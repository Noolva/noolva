-- ============================================================================
-- Release 1.0.6 — 03: Data lifecycle policy — completed my_tasks (proposed design)
--
-- Design (tiered lifecycle):
--   hot my_tasks (+ task_comments / task_attachments)
--     --refresh--> flat_my_tasks          (flattening engine, every 60 min)
--     --archive--> archived_flat_my_tasks (this policy: completed > 1 year, daily)
--     --purge----> hot flat+root+children deleted ONLY for rows verified in archive
--                  (purge_enabled, 7-day grace after last archive batch)
--
-- Reads after purge: Completed page reads flat rows until archived; archived tier
-- is queryable via the archived table / future lifecycle read endpoints.
-- Retention knobs: interval '1 year' (archive age), purge_after_interval_minutes (grace).
-- Idempotent: safe to re-run. Review retention values before production.
-- ============================================================================

INSERT INTO public.data_lifecycle_policy (
    policy_label, table_name, pk_column,
    transfer_mode, time_column, filter_condition,
    destination_type, destination_table, movement_type,
    sync_strategy, sync_batch_size, sync_interval_minutes,
    is_active, purge_enabled, purge_after_interval_minutes,
    lifecycle_root_table
)
SELECT
    'my_tasks completed > 1y -> postgres archive + purge',
    'flat_my_tasks',
    'task_id',
    'time_and_condition',
    'completed_at',
    $$status = 'completed' AND completed_at IS NOT NULL AND completed_at < now() - interval '1 year'$$,
    'postgres_archive',
    'archived_flat_my_tasks',
    'move',
    'FULL',
    1000,
    1440,
    true,
    true,
    10080,
    'my_tasks'
WHERE NOT EXISTS (
    SELECT 1 FROM public.data_lifecycle_policy
    WHERE table_name = 'flat_my_tasks'
      AND destination_type = 'postgres_archive'
      AND policy_label LIKE 'my_tasks completed%'
);
