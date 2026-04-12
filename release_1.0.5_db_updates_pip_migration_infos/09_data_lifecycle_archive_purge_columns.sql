-- Release 1.0.5 — 09_data_lifecycle_archive_purge_columns.sql
-- Canonical columns: db-structure/update_old_db_data_lifecycle_archive_purge_columns.sql

ALTER TABLE public.data_lifecycle_policy
    ADD COLUMN IF NOT EXISTS archive_source_table TEXT,
    ADD COLUMN IF NOT EXISTS purge_enabled BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS purge_after_interval_minutes INT,
    ADD COLUMN IF NOT EXISTS last_archive_completed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_purge_completed_at TIMESTAMPTZ;

UPDATE public.data_lifecycle_policy SET purge_enabled = FALSE WHERE purge_enabled IS NULL;
ALTER TABLE public.data_lifecycle_policy
    ALTER COLUMN purge_enabled SET DEFAULT FALSE,
    ALTER COLUMN purge_enabled SET NOT NULL;

-- Optional: align destination_table with flattening target when archive_source_table is null
UPDATE public.data_lifecycle_policy dlp
SET destination_table = 'archived_' || COALESCE(
        NULLIF(TRIM(ftp.target_table_name), ''),
        dlp.table_name
    )
FROM public.flattening_table_policy ftp
WHERE ftp.table_name = dlp.table_name
  AND COALESCE(ftp.is_active, TRUE)
  AND (dlp.archive_source_table IS NULL OR TRIM(COALESCE(dlp.archive_source_table, '')) = '')
  AND dlp.destination_table IS DISTINCT FROM (
        'archived_' || COALESCE(NULLIF(TRIM(ftp.target_table_name), ''), dlp.table_name)
    );

INSERT INTO public.api_endpoints (
    path,
    method,
    type,
    related_model_id,
    reference_model_ids,
    custom_json
)
VALUES (
    '/job-workflows/lifecycle_policies_purge_due',
    'GET',
    'custom_query',
    NULL,
    '{}',
    '{"query": "SELECT id, table_name, pk_column, destination_type::text AS destination_type, movement_type::text AS movement_type, sync_strategy::text AS sync_strategy, sync_batch_size, time_column, filter_condition, destination_table, is_public_on_s3, archive_source_table, purge_after_interval_minutes, transfer_mode::text AS transfer_mode, last_archive_completed_at, last_purge_completed_at FROM public.data_lifecycle_policy WHERE COALESCE(is_active, true) = true AND purge_enabled = true AND destination_type = ''postgres_archive''::public.destination_type_enum AND sync_interval_minutes IS NOT NULL AND last_archive_completed_at IS NOT NULL AND ( COALESCE(purge_after_interval_minutes, 0) = 0 OR last_archive_completed_at + (purge_after_interval_minutes || '' minutes'')::interval <= now() ) AND ( last_purge_completed_at IS NULL OR last_purge_completed_at + (sync_interval_minutes || '' minutes'')::interval <= now() )"}'::jsonb
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
    'purge_lifecycle_after_archive',
    'Delete one batch from flattened source + root table after rows exist in postgres archive (purge_enabled only; separate from sync)',
    'task',
    'core_function',
    'purge_lifecycle_after_archive',
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
    'dispatch_lifecycle_purge',
    'Due purge_enabled lifecycle policies → enqueue purge_lifecycle_after_archive per row',
    'workflow',
    jsonb_build_object(
        'version', '1.0',
        'execution', 'sequential',
        'steps', jsonb_build_array(
            jsonb_build_object(
                'id', 'fetch_due_purge',
                'task', 'custom_query_endpoint',
                'input', jsonb_build_object(
                    'endpoint_path', '/job-workflows/lifecycle_policies_purge_due',
                    'method', 'GET',
                    'limit', 50,
                    'offset', 0
                ),
                'output', 'due_purge'
            ),
            jsonb_build_object(
                'id', 'enqueue_purge',
                'task', 'create_jobs_from_records',
                'depends_on', jsonb_build_array('fetch_due_purge'),
                'input', jsonb_build_object(
                    'records', '$due_purge.body.records',
                    'job_template_name', 'purge_lifecycle_after_archive',
                    'payload_mapping', jsonb_build_object(
                        'policy_id', '$record.id'
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

UPDATE public.job_templates
SET description = 'Archive from flattened/source table to postgres/S3/Iceberg (no deletes); updates last_archive_completed_at when rows copied'
WHERE name = 'sync_lifecycle_table';
