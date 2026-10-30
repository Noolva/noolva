-- ============================================================================
-- Release 1.0.6 — 07: Flatten completeness for the read-only Completed view
-- Adds o2m JSON child relations so flat_my_tasks carries dependencies and
-- work logs inline (task_person_dependencies_items, work_logs_items) —
-- pkmanager Completed Tasks (read-only) then needs ZERO hot-table child calls.
-- Idempotent: safe to re-run.
-- ============================================================================

INSERT INTO public.flattening_relation_policy (
    table_name, relation_name, relation_type, strategy, include_fields, target_table
)
SELECT 'my_tasks', v.rn, 'o2m', 'json', NULL, NULL
FROM (VALUES
    ('task_person_dependencies.task_id'),
    ('work_logs.task_id')
) AS v(rn)
WHERE EXISTS (
    SELECT 1 FROM public.flattening_table_policy WHERE table_name = 'my_tasks'
)
ON CONFLICT (table_name, relation_name) DO NOTHING;

-- Force one full rebuild so existing flat rows get the new JSON columns
-- (INCREMENTAL with NULL watermark behaves as FULL; scheduler picks it up
-- on its next tick via last_refreshed IS NULL).
UPDATE public.flattening_table_policy
SET last_refreshed = NULL,
    last_processed_value = NULL
WHERE table_name = 'my_tasks';
