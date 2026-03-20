-- Workflow alarm templates and pending_alarms custom_query endpoint.
-- Safe to run multiple times (ON CONFLICT / INSERT only when missing).
-- Prerequisite: Table public.alarms with status, scheduled_for (or next_alarm_time), alarm_id, optional alarm_target.
-- Uses scheduled_for for due time; payload maps alarm_id and alarm_target (as device_id). See update_old_db_workflow_alarm_schema_alignment.sql to switch to next_alarm_time if you use it.

-- 1) Custom query API endpoint: pending_alarms
-- Query: pending alarms where scheduled_for <= now(). API adds LIMIT/OFFSET at runtime.
INSERT INTO public.api_endpoints (
    path,
    method,
    type,
    related_model_id,
    reference_model_ids,
    custom_json
)
VALUES (
    '/job-workflows/pending_alarms',
    'GET',
    'custom_query',
    NULL,
    '{}',
    '{"query": "SELECT * FROM public.alarms WHERE status = ''pending'' AND scheduled_for IS NOT NULL AND scheduled_for <= now()"}'::jsonb
)
ON CONFLICT (path, method) DO UPDATE SET
    type = EXCLUDED.type,
    custom_json = EXCLUDED.custom_json;

-- 2) Job template: create_jobs_from_records (task)
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
    'create_jobs_from_records',
    'Create one job per record from a list; used by workflows (e.g. process_pending_alarms)',
    'task',
    'core_function',
    'create_jobs_from_records',
    ARRAY['local','remote'],
    300,
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

-- 3) Job template: process_alarm (task)
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
    'process_alarm',
    'Process one alarm; push to device over WebSocket if device_id present and connected',
    'task',
    'core_function',
    'process_alarm',
    ARRAY['local','remote'],
    60,
    'parallel',
    50,
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

-- 4) Job template: process_pending_alarms (workflow)
-- Step 1: custom_query_endpoint by path (portable; no endpoint_id) -> output alarm_list
-- Step 2: create_jobs_from_records(records from alarm_list.body.records, template process_alarm)
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
    'process_pending_alarms',
    'Fetch pending alarms (custom_query), then create one process_alarm job per alarm',
    'workflow',
    jsonb_build_object(
        'version', '1.0',
        'execution', 'sequential',
        'steps', jsonb_build_array(
            jsonb_build_object(
                'id', 'fetch_pending_alarms',
                'task', 'custom_query_endpoint',
                'input', jsonb_build_object(
                    'endpoint_path', '/job-workflows/pending_alarms',
                    'method', 'GET',
                    'limit', 100,
                    'offset', 0
                ),
                'output', 'alarm_list'
            ),
            jsonb_build_object(
                'id', 'create_alarm_jobs',
                'task', 'create_jobs_from_records',
                'depends_on', jsonb_build_array('fetch_pending_alarms'),
                'input', jsonb_build_object(
                    'records', '$alarm_list.body.records',
                    'job_template_name', 'process_alarm',
                    'payload_mapping', jsonb_build_object(
                        'alarm_id', '$record.alarm_id',
                        'device_id', '$record.alarm_target'
                    )
                )
            )
        )
    ),
    ARRAY['local','remote'],
    300,
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
