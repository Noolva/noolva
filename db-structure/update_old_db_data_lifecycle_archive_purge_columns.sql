-- Data lifecycle: archive source (flattened table), purge flags, archive/purge checkpoints.
-- Safe to run multiple times (IF NOT EXISTS columns).

ALTER TABLE public.data_lifecycle_policy
    ADD COLUMN IF NOT EXISTS archive_source_table TEXT,
    ADD COLUMN IF NOT EXISTS purge_enabled BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS purge_after_interval_minutes INT,
    ADD COLUMN IF NOT EXISTS last_archive_completed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_purge_completed_at TIMESTAMPTZ;

UPDATE public.data_lifecycle_policy SET purge_enabled = FALSE WHERE purge_enabled IS NULL;
ALTER TABLE public.data_lifecycle_policy
    ALTER COLUMN purge_enabled SET DEFAULT FALSE,
    ALTER COLUMN purge_enabled SET NOT NULL;

COMMENT ON COLUMN public.data_lifecycle_policy.archive_source_table IS
    'Physical table rows are read from for archive (flattened target). NULL = use flattening_table_policy.target_table_name for table_name, else source table_name.';
COMMENT ON COLUMN public.data_lifecycle_policy.purge_enabled IS
    'When true, dispatch_lifecycle_purge can run purge_lifecycle_after_archive (never in sync_lifecycle_table).';
COMMENT ON COLUMN public.data_lifecycle_policy.purge_after_interval_minutes IS
    'Minimum minutes after last_archive_completed_at before purge; NULL = 0 (eligible immediately after archive).';
