-- Update pending_alarms query: COALESCE(next_alarm_time, scheduled_for) for due check; status IN (pending, snoozed).
-- When next_alarm_time is set (e.g. after snooze), it takes precedence; otherwise scheduled_for is used.
-- Safe to run multiple times.

UPDATE public.api_endpoints
SET custom_json = jsonb_build_object(
    'query',
    'SELECT * FROM public.alarms WHERE status IN (''pending'', ''snoozed'') AND COALESCE(next_alarm_time, scheduled_for) IS NOT NULL AND COALESCE(next_alarm_time, scheduled_for) <= now()'
)
WHERE path = '/job-workflows/pending_alarms' AND method = 'GET';
