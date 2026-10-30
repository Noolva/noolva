-- ============================================================================
-- Release 1.0.6 — 01: Flattening engine for my_tasks
-- Dev DB: apply freely. Production: apply ONLY from this file (see repository-rules).
-- Idempotent: safe to re-run.
-- ============================================================================

-- 1. Flattening table policy for my_tasks (postgres -> flat_my_tasks, INCREMENTAL 60 min)
INSERT INTO public.flattening_table_policy (
    table_name, refresh_strategy, refresh_interval_minutes, batch_size,
    destination, target_table_name, is_snapshot, is_active
)
SELECT 'my_tasks', 'INCREMENTAL', 60, 1000, 'postgres', 'flat_my_tasks', false, true
WHERE NOT EXISTS (
    SELECT 1 FROM public.flattening_table_policy WHERE table_name = 'my_tasks'
);

-- 2. m2o denormalize relations (logical FKs via data_model_fields, no Postgres FK needed)
INSERT INTO public.flattening_relation_policy (
    table_name, relation_name, relation_type, strategy, include_fields
)
SELECT v.tn, v.rn, 'm2o', 'denormalize', v.inc
FROM (VALUES
    ('my_tasks', 'business_id',      ARRAY['name']),
    ('my_tasks', 'person_id',        ARRAY['name']),
    ('my_tasks', 'priority',         ARRAY['name']),
    ('my_tasks', 'project_id',       ARRAY['project_name']),
    ('my_tasks', 'sprint_id',        ARRAY['sprint_name']),
    ('my_tasks', 'task_category_id', ARRAY['name'])
) AS v(tn, rn, inc)
WHERE EXISTS (
    SELECT 1 FROM public.flattening_table_policy p WHERE p.table_name = v.tn
)
ON CONFLICT (table_name, relation_name) DO NOTHING;

-- 3. o2m JSON child relations — followup messages + activity logs (task_comments carries
--    activity_type: 'comment' = followup message, other values = activity log entries)
--    and attachments (task_attachments). Flat rows embed them as JSONB arrays:
--      task_comments_items, task_attachments_items
INSERT INTO public.flattening_relation_policy (
    table_name, relation_name, relation_type, strategy, include_fields, target_table
)
SELECT 'my_tasks', v.rn, 'o2m', 'json', NULL, NULL
FROM (VALUES
    ('task_comments.task'),
    ('task_attachments.task')
) AS v(rn)
WHERE EXISTS (
    SELECT 1 FROM public.flattening_table_policy WHERE table_name = 'my_tasks'
)
ON CONFLICT (table_name, relation_name) DO NOTHING;

-- 4. Job template description: engine is real now (no longer a stub)
UPDATE public.job_templates
SET description = 'Run flatten refresh for one flattening_table_policy row (materializes flat table: base columns + m2o denormalized fields + o2m JSON children)'
WHERE name = 'refresh_flattening_table';
