-- ============================================================================
-- Release 1.0.6 — 02: Schedulers for data lifecycle archive sync + purge
-- Templates already exist (dispatch_lifecycle_syncs, dispatch_lifecycle_purge);
-- this adds the cron rows so archive/purge actually run every 5 minutes.
-- Idempotent: safe to re-run.
-- ============================================================================

INSERT INTO public.schedulers (name, description, cron_expression, template_id, payload)
SELECT
    'Process Lifecycle Syncs',
    'Dispatch due data lifecycle archive syncs (dispatch_lifecycle_syncs -> sync_lifecycle_table)',
    '*/5 * * * *',
    jt.id,
    '{}'::jsonb
FROM public.job_templates jt
WHERE jt.name = 'dispatch_lifecycle_syncs'
  AND NOT EXISTS (
      SELECT 1 FROM public.schedulers s WHERE s.name = 'Process Lifecycle Syncs'
  );

INSERT INTO public.schedulers (name, description, cron_expression, template_id, payload)
SELECT
    'Process Lifecycle Purges',
    'Dispatch due data lifecycle purges (dispatch_lifecycle_purge -> purge_lifecycle_after_archive)',
    '*/5 * * * *',
    jt.id,
    '{}'::jsonb
FROM public.job_templates jt
WHERE jt.name = 'dispatch_lifecycle_purge'
  AND NOT EXISTS (
      SELECT 1 FROM public.schedulers s WHERE s.name = 'Process Lifecycle Purges'
  );
