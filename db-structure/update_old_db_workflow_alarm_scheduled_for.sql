-- Migration for OLD databases that already ran update_old_db_workflow_alarm_templates.sql.
-- Aligns pending_alarms with alarms table that uses: alarm_id, scheduled_for, alarm_target (no next_alarm_time / id / device_id).
-- Safe to run multiple times.

-- 1) Custom query: use scheduled_for for due time (next_alarm_time is null in your data).
UPDATE public.api_endpoints
SET custom_json = jsonb_build_object(
    'query',
    'SELECT * FROM public.alarms WHERE status = ''pending'' AND scheduled_for IS NOT NULL AND scheduled_for <= now()'
)
WHERE path = '/job-workflows/pending_alarms' AND method = 'GET';

-- 2) Workflow: use endpoint_path (portable) and payload mapping alarm_id / alarm_target.
UPDATE public.job_templates
SET workflow_definition = jsonb_build_object(
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
)
WHERE name = 'process_pending_alarms';
