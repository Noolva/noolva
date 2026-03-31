-- Replace legacy archival_policies + data_flattening_rules with flattening_* tables,
-- job workflow: dispatch_flattening_refreshes -> refresh_flattening_table.
-- Safe to run once per environment; uses IF EXISTS drops and idempotent upserts.

-- ---------------------------------------------------------------------------
-- 1) Drop legacy tables (destructive — backup first if they contain data)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS public.data_flattening_rules CASCADE;
DROP TABLE IF EXISTS public.archival_policies CASCADE;

-- ---------------------------------------------------------------------------
-- 2) Flattening policy tables
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.flattening_table_policy (
    id SERIAL PRIMARY KEY,
    table_name TEXT UNIQUE NOT NULL,
    refresh_strategy TEXT CHECK (refresh_strategy IS NULL OR refresh_strategy IN ('FULL', 'INCREMENTAL', 'VERSIONED')),
    refresh_interval_minutes INT,
    batch_size INT,
    last_refreshed TIMESTAMPTZ,
    last_processed_value TIMESTAMPTZ,
    is_snapshot BOOLEAN DEFAULT TRUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS public.flattening_relation_policy (
    id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL REFERENCES public.flattening_table_policy(table_name) ON DELETE CASCADE,
    relation_name TEXT NOT NULL,
    relation_type TEXT NOT NULL CHECK (relation_type IN ('m2o', 'o2m')),
    strategy TEXT NOT NULL CHECK (strategy IN ('denormalize', 'json', 'separate')),
    include_fields TEXT[],
    target_table TEXT,
    is_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (table_name, relation_name),
    CHECK (strategy <> 'separate' OR (target_table IS NOT NULL AND length(trim(target_table)) > 0)),
    CHECK ((relation_type = 'm2o' AND strategy = 'denormalize') OR (relation_type = 'o2m' AND strategy IN ('json', 'separate'))),
    CHECK (strategy = 'denormalize' OR include_fields IS NULL OR cardinality(include_fields) = 0)
);

CREATE INDEX IF NOT EXISTS idx_flattening_table_policy_due
    ON public.flattening_table_policy(is_snapshot, refresh_strategy) WHERE is_active = TRUE AND is_snapshot = FALSE;
CREATE INDEX IF NOT EXISTS idx_flattening_table_policy_last_refreshed ON public.flattening_table_policy(last_refreshed);
CREATE INDEX IF NOT EXISTS idx_flattening_relation_policy_table ON public.flattening_relation_policy(table_name);

-- ---------------------------------------------------------------------------
-- 3) Custom query + job templates (requires create_jobs_from_records from alarm/workflow migrations)
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
    '/job-workflows/flattening_policies_due',
    'GET',
    'custom_query',
    NULL,
    '{}',
    '{"query": "SELECT id, table_name, refresh_strategy, refresh_interval_minutes, batch_size FROM public.flattening_table_policy WHERE COALESCE(is_active, true) = true AND is_snapshot = false AND refresh_strategy IS NOT NULL AND refresh_interval_minutes IS NOT NULL AND (last_refreshed IS NULL OR last_refreshed + (refresh_interval_minutes || '' minutes'')::interval <= now())"}'::jsonb
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
    'refresh_flattening_table',
    'Run flatten refresh for one flattening_table_policy row (stub updates last_refreshed)',
    'task',
    'core_function',
    'refresh_flattening_table',
    ARRAY['local','remote'],
    3600,
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
    'dispatch_flattening_refreshes',
    'Fetch due flattening policies (custom_query), enqueue refresh_flattening_table per row',
    'workflow',
    jsonb_build_object(
        'version', '1.0',
        'execution', 'sequential',
        'steps', jsonb_build_array(
            jsonb_build_object(
                'id', 'fetch_due_flattening',
                'task', 'custom_query_endpoint',
                'input', jsonb_build_object(
                    'endpoint_path', '/job-workflows/flattening_policies_due',
                    'method', 'GET',
                    'limit', 100,
                    'offset', 0
                ),
                'output', 'due_list'
            ),
            jsonb_build_object(
                'id', 'enqueue_refreshes',
                'task', 'create_jobs_from_records',
                'depends_on', jsonb_build_array('fetch_due_flattening'),
                'input', jsonb_build_object(
                    'records', '$due_list.body.records',
                    'job_template_name', 'refresh_flattening_table',
                    'payload_mapping', jsonb_build_object(
                        'policy_id', '$record.id',
                        'table_name', '$record.table_name'
                    )
                )
            )
        )
    ),
    ARRAY['local','remote'],
    3600,
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
