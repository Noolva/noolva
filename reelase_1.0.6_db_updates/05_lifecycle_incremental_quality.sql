-- ============================================================================
-- Release 1.0.6 — 05: High-quality INCREMENTAL for lifecycle archive
-- - New column: incremental_lookback_minutes (late-row safety window; overlap
--   re-checks recent rows — safe because archive dedupes by PK).
-- - Purge no longer uses the archive watermark (engine change), so INCREMENTAL
--   + purge is now correct: archive uses the watermark, purge relies on the
--   archive join.
-- - Switches the my_tasks completed policy to INCREMENTAL + 7-day lookback
--   (as requested for future scale). Idempotent: safe to re-run.
-- ============================================================================

ALTER TABLE public.data_lifecycle_policy
    ADD COLUMN IF NOT EXISTS incremental_lookback_minutes integer;

COMMENT ON COLUMN public.data_lifecycle_policy.incremental_lookback_minutes IS
    'INCREMENTAL only: re-check rows newer than (watermark - this window). Catches late/out-of-order timestamps. 0 or NULL = strict watermark.';

-- Switch the my_tasks completed archive+purge policy to INCREMENTAL + 7-day lookback
UPDATE public.data_lifecycle_policy
SET sync_strategy = 'INCREMENTAL',
    incremental_lookback_minutes = 10080,
    last_updated = CURRENT_TIMESTAMP
WHERE policy_label LIKE 'my_tasks completed%'
  AND table_name = 'flat_my_tasks'
  AND destination_type = 'postgres_archive';
