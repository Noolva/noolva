-- Data lifecycle enums + data_lifecycle_policy + job templates.
-- Run after flattening migration if desired; independent otherwise.
-- Requires create_jobs_from_records job template (from workflow/alarm migrations).

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE public.destination_type_enum AS ENUM ('s3', 'postgres_archive', 'iceberg');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
DO $$ BEGIN
    CREATE TYPE public.movement_type_enum AS ENUM ('move', 'copy');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
DO $$ BEGIN
    CREATE TYPE public.sync_strategy_enum AS ENUM ('FULL', 'INCREMENTAL');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
DO $$ BEGIN
    CREATE TYPE public.transfer_mode_enum AS ENUM ('time_based', 'condition_based', 'time_and_condition');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.data_lifecycle_policy (
    id SERIAL PRIMARY KEY,
    policy_label TEXT,
    table_name TEXT NOT NULL,
    pk_column TEXT NOT NULL DEFAULT 'id',
    transfer_mode public.transfer_mode_enum DEFAULT 'time_based' NOT NULL,
    time_column TEXT,
    filter_condition TEXT,
    destination_type public.destination_type_enum NOT NULL,
    destination_table TEXT,
    is_public_on_s3 BOOLEAN,
    movement_type public.movement_type_enum NOT NULL,
    sync_strategy public.sync_strategy_enum NOT NULL,
    sync_batch_size INT DEFAULT 1000,
    sync_interval_minutes INT,
    last_synced_at TIMESTAMPTZ,
    last_processed_value TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_data_lifecycle_policy_due
    ON public.data_lifecycle_policy(is_active, destination_type) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_data_lifecycle_policy_last_sync ON public.data_lifecycle_policy(last_synced_at);

-- ---------------------------------------------------------------------------
-- API + jobs
-- ---------------------------------------------------------------------------
INSERT INTO public.api_endpoints (
    path,
    method,
    type,
    related_model_id,
    reference_model_ids,
    custom_json
)
VALUES (
    '/job-workflows/lifecycle_policies_due',
    'GET',
    'custom_query',
    NULL,
    '{}',
    '{"query": "SELECT id, table_name, pk_column, destination_type::text AS destination_type, movement_type::text AS movement_type, sync_strategy::text AS sync_strategy, sync_batch_size, time_column, filter_condition, destination_table, is_public_on_s3 FROM public.data_lifecycle_policy WHERE COALESCE(is_active, true) = true AND sync_interval_minutes IS NOT NULL AND (last_synced_at IS NULL OR last_synced_at + (sync_interval_minutes || '' minutes'')::interval <= now())"}'::jsonb
)
ON CONFLICT (path, method) DO UPDATE SET
    type = EXCLUDED.type,
    custom_json = EXCLUDED.custom_json;

INSERT INTO public.job_templates (
    name,
    description,
    template_category,
    handler_type,
    handler_function_name,
    runnable_in,
    default_timeout_seconds,
    queue_concurrency_mode,
    queue_concurrency_limit,
    is_active
)
VALUES (
    'sync_lifecycle_table',
    'Sync one data_lifecycle_policy row (S3 copy / archive stub; updates last_synced_at)',
    'task',
    'core_function',
    'sync_lifecycle_table',
    ARRAY['local','remote'],
    7200,
    'parallel',
    0,
    true
)
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    template_category = EXCLUDED.template_category,
    handler_type = EXCLUDED.handler_type,
    handler_function_name = EXCLUDED.handler_function_name,
    runnable_in = EXCLUDED.runnable_in,
    default_timeout_seconds = EXCLUDED.default_timeout_seconds,
    queue_concurrency_mode = EXCLUDED.queue_concurrency_mode,
    queue_concurrency_limit = EXCLUDED.queue_concurrency_limit,
    is_active = EXCLUDED.is_active;

INSERT INTO public.job_templates (
    name,
    description,
    template_category,
    workflow_definition,
    runnable_in,
    default_timeout_seconds,
    queue_concurrency_mode,
    queue_concurrency_limit,
    is_active
)
VALUES (
    'dispatch_lifecycle_syncs',
    'Fetch due lifecycle policies, enqueue sync_lifecycle_table per row',
    'workflow',
    jsonb_build_object(
        'version', '1.0',
        'execution', 'sequential',
        'steps', jsonb_build_array(
            jsonb_build_object(
                'id', 'fetch_due_lifecycle',
                'task', 'custom_query_endpoint',
                'input', jsonb_build_object(
                    'endpoint_path', '/job-workflows/lifecycle_policies_due',
                    'method', 'GET',
                    'limit', 50,
                    'offset', 0
                ),
                'output', 'due_lc'
            ),
            jsonb_build_object(
                'id', 'enqueue_lifecycle',
                'task', 'create_jobs_from_records',
                'depends_on', jsonb_build_array('fetch_due_lifecycle'),
                'input', jsonb_build_object(
                    'records', '$due_lc.body.records',
                    'job_template_name', 'sync_lifecycle_table',
                    'payload_mapping', jsonb_build_object(
                        'policy_id', '$record.id',
                        'table_name', '$record.table_name'
                    )
                )
            )
        )
    ),
    ARRAY['local','remote'],
    7200,
    'parallel',
    0,
    true
)
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    template_category = EXCLUDED.template_category,
    workflow_definition = EXCLUDED.workflow_definition,
    runnable_in = EXCLUDED.runnable_in,
    default_timeout_seconds = EXCLUDED.default_timeout_seconds,
    queue_concurrency_mode = EXCLUDED.queue_concurrency_mode,
    queue_concurrency_limit = EXCLUDED.queue_concurrency_limit,
    is_active = EXCLUDED.is_active;

INSERT INTO public.job_templates (
    name,
    description,
    template_category,
    handler_type,
    handler_function_name,
    runnable_in,
    default_timeout_seconds,
    queue_concurrency_mode,
    queue_concurrency_limit,
    is_active
)
VALUES (
    'purge_soft_deleted',
    'Hard-delete rows where deleted_at is older than retention_days (default 30)',
    'task',
    'core_function',
    'purge_soft_deleted',
    ARRAY['local','remote'],
    3600,
    'singleton',
    1,
    true
)
ON CONFLICT (name) DO UPDATE SET
      description = EXCLUDED.description,
      template_category = EXCLUDED.template_category,
      handler_type = EXCLUDED.handler_type,
      handler_function_name = EXCLUDED.handler_function_name,
      runnable_in = EXCLUDED.runnable_in,
      default_timeout_seconds = EXCLUDED.default_timeout_seconds,
      queue_concurrency_mode = EXCLUDED.queue_concurrency_mode,
      queue_concurrency_limit = EXCLUDED.queue_concurrency_limit,
      is_active = EXCLUDED.is_active;
