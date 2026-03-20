-- Use endpoint_path instead of endpoint_id in process_pending_alarms workflow (portable across environments).
-- Safe to run multiple times.

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
