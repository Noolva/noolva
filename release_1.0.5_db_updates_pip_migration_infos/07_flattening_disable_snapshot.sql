-- Release 1.0.5 — 07_flattening_disable_snapshot.sql
-- Canonical: db-structure/update_old_db_flattening_disable_snapshot.sql

-- Disable snapshot mode for flattening policies (not used).
-- Safe to run multiple times.

-- 1) Force all existing policies to non-snapshot
UPDATE public.flattening_table_policy
SET is_snapshot = FALSE,
    last_updated = now()
WHERE is_snapshot IS DISTINCT FROM FALSE;

-- 2) Default new rows to non-snapshot
ALTER TABLE public.flattening_table_policy
  ALTER COLUMN is_snapshot SET DEFAULT FALSE;

-- 3) Optional hard guard (idempotent): prevent re-enabling snapshot
DO $$ BEGIN
  ALTER TABLE public.flattening_table_policy
    ADD CONSTRAINT flattening_table_policy_no_snapshot_check
    CHECK (is_snapshot = FALSE);
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

