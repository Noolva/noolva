-- ============================================================================
-- Release 1.0.6 — 04: Verification (read-only) for UI + engine readiness
-- Run AFTER 01-03. Does not modify data.
-- ============================================================================

-- 1. Flattening policy + relations for my_tasks
SELECT 'flattening_policy' AS check, id, table_name, target_table_name,
       refresh_strategy, refresh_interval_minutes, last_refreshed, is_active
FROM public.flattening_table_policy WHERE table_name = 'my_tasks';

SELECT 'relations' AS check, id, relation_name, relation_type, strategy, include_fields
FROM public.flattening_relation_policy WHERE table_name = 'my_tasks' ORDER BY id;

-- 2. Flat table + data model + read endpoints
SELECT 'flat_table' AS check,
       (SELECT count(*) FROM information_schema.tables
         WHERE table_schema='public' AND table_name='flat_my_tasks') AS exists,
       (SELECT count(*) FROM public.flat_my_tasks) AS rows_now;

SELECT 'flat_model' AS check, model_id, model_name, table_name
FROM public.data_models WHERE table_name = 'flat_my_tasks';

SELECT 'flat_endpoints' AS check, path, method
FROM public.api_endpoints WHERE path LIKE '%flattened_my_tasks%';

-- 3. Schedulers for flatten + lifecycle sync + purge
SELECT 'schedulers' AS check, s.name, s.cron_expression, s.is_enabled, jt.name AS template
FROM public.schedulers s JOIN public.job_templates jt ON jt.id = s.template_id
ORDER BY s.name;

-- 4. Lifecycle policy + ledger status (what the UI pipeline strip reads)
SELECT 'lifecycle_policy' AS check, id, policy_label, table_name, pk_column,
       transfer_mode, time_column, destination_type, destination_table,
       purge_enabled, purge_after_interval_minutes, lifecycle_root_table,
       last_archive_completed_at, last_purge_completed_at
FROM public.data_lifecycle_policy ORDER BY id;

SELECT 'ledger_by_op' AS check, policy_id, operation, status,
       count(*) AS batches, sum(rows_affected) AS rows_total,
       max(completed_at) AS last_run
FROM public.data_lifecycle_batch_ledger
GROUP BY policy_id, operation, status
ORDER BY policy_id, operation;
