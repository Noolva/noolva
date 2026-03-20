-- 97_seed_actions.sql (superseded by job scheduler)
-- Job templates are now seeded in noolvandb_schema.sql (job_templates table).
-- This file is kept for reference. Run update_old_db_job_scheduler.sql to migrate from actions/job_queue.

INSERT INTO public.job_templates (name, description, handler_type, handler_function_name, runnable_in, default_timeout_seconds, is_idempotent, queue_concurrency_mode, queue_concurrency_limit)
VALUES
  ('send_email', 'Send Email', 'core_function', 'send_email', ARRAY['local','remote'], 300, true, 'parallel', 20),
  ('notification_push', 'Send Push Notification', 'core_function', 'notification_push', ARRAY['local','remote'], 60, true, 'parallel', 50),
  ('generate_report', 'Generate Report', 'core_function', 'generate_report', ARRAY['local','remote'], 600, false, 'parallel', 5)
ON CONFLICT (name) DO NOTHING;
