-- Incremental update for databases that already ran:
-- - release_1.0.5_db_updates_pip_migration_infos/03_flattening_policies_and_job_workflows.sql (or equivalent)
--
-- Adds destination + DB-table mode fields and normalizes S3 folder naming.
-- Safe to run multiple times.

-- 1) Add new columns (no destructive changes)
ALTER TABLE public.flattening_table_policy
  ADD COLUMN IF NOT EXISTS destination TEXT NOT NULL DEFAULT 'postgres';

DO $$ BEGIN
  ALTER TABLE public.flattening_table_policy
    ADD CONSTRAINT flattening_table_policy_destination_check
    CHECK (destination IN ('postgres','s3','iceberg'));
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

ALTER TABLE public.flattening_table_policy
  ADD COLUMN IF NOT EXISTS is_db_table BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.flattening_table_policy
  ADD COLUMN IF NOT EXISTS is_public_on_s3 BOOLEAN;

ALTER TABLE public.flattening_table_policy
  ADD COLUMN IF NOT EXISTS target_table_name TEXT;

-- 2) Backfill target_table_name for postgres destination
UPDATE public.flattening_table_policy
SET target_table_name = COALESCE(target_table_name, 'flat_' || table_name)
WHERE COALESCE(destination,'postgres') = 'postgres';

-- 3) Update due custom_query endpoint to include destination (S3 + Postgres)
INSERT INTO public.api_endpoints (
  path, method, type, related_model_id, reference_model_ids, custom_json
)
VALUES (
  '/job-workflows/flattening_policies_due',
  'GET',
  'custom_query',
  NULL,
  '{}',
  '{"query": "SELECT id, table_name, destination, is_db_table, is_public_on_s3, refresh_strategy, refresh_interval_minutes, batch_size FROM public.flattening_table_policy WHERE COALESCE(is_active, true) = true AND is_snapshot = false AND refresh_strategy IS NOT NULL AND refresh_interval_minutes IS NOT NULL AND (last_refreshed IS NULL OR last_refreshed + (refresh_interval_minutes || '' minutes'')::interval <= now())"}'::jsonb
)
ON CONFLICT (path, method) DO UPDATE SET
  type = EXCLUDED.type,
  custom_json = EXCLUDED.custom_json;

