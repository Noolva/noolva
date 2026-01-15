-- 97_seed_actions.sql
-- Classification: Seed Data
-- Description: Standard System Actions (Atomic Units of Work).

INSERT INTO public.actions (action_code, action_name, handler_function, queue_concurrency_mode, queue_concurrency_limit, default_timeout_seconds, is_idempotent, inputs_schema_json) VALUES
-- Heavy Operations -> Sequential
('app_clone', 'Clone Application', 'AppService.clone', 'sequential', 1, 600, false, '{"app_id": {"type": "integer"}, "target_company_id": {"type": "integer"}}'),
('tenant_provision', 'Provision New Tenant', 'TenantService.provision', 'sequential', 2, 300, false, '{"tenant_name": {"type": "string"}}'),

-- Data Operations -> Limited Parallelism
('data_import', 'Bulk Data Import', 'DataService.import', 'parallel', 3, 1800, false, '{"file_url": {"type": "string"}, "target_model": {"type": "string"}}'),
('data_export', 'Data Export', 'DataService.export', 'parallel', 5, 1800, true, '{"model_id": {"type": "integer"}, "filters": {"type": "object"}}'),

-- Communications -> High Parallelism
('send_email', 'Send Email', 'CommsService.sendEmail', 'parallel', 20, 300, true, '{"to": {"type": "email"}, "subject": {"type": "string"}, "body": {"type": "text"}}'),
('notification_push', 'Send Push Notification', 'CommsService.sendPush', 'parallel', 50, 60, true, '{"user_id": {"type": "integer"}, "message": {"type": "string"}}'),

-- Maintenance
('system_cleanup', 'Daily Cleanup', 'MaintenanceService.cleanup', 'sequential', 1, 3600, true, '{}'),
('search_reindex', 'Re-index Search', 'SearchService.reindex', 'sequential', 1, 7200, true, '{}')

ON CONFLICT (action_code) DO NOTHING;
