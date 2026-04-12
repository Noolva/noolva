-- Release 1.0.5 — 10_data_lifecycle_batch_ledger_purge_due.sql
-- Canonical ledger + root: db-structure/update_old_db_data_lifecycle_batch_ledger_and_root.sql

CREATE TABLE IF NOT EXISTS public.data_lifecycle_batch_ledger (
    id BIGSERIAL PRIMARY KEY,
    policy_id INT NOT NULL REFERENCES public.data_lifecycle_policy(id) ON DELETE CASCADE,
    operation TEXT NOT NULL CHECK (operation IN (
        'archive_postgres',
        'iceberg_export',
        'purge_hot',
        'purge_archived'
    )),
    source_table TEXT NOT NULL,
    destination_type TEXT NOT NULL,
    destination_detail TEXT,
    rows_affected INT DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('started', 'completed', 'failed')),
    error_message TEXT,
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    last_processed_snapshot TIMESTAMPTZ,
    purged_at TIMESTAMPTZ,
    extra JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_lc_batch_ledger_policy_started
    ON public.data_lifecycle_batch_ledger(policy_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_lc_batch_ledger_purge_pending
    ON public.data_lifecycle_batch_ledger(policy_id, operation)
    WHERE operation = 'iceberg_export' AND purged_at IS NULL AND status = 'completed';

ALTER TABLE public.data_lifecycle_policy
    ADD COLUMN IF NOT EXISTS lifecycle_root_table TEXT;

UPDATE public.data_lifecycle_policy dlp
SET lifecycle_root_table = ftp.table_name
FROM public.flattening_table_policy ftp
WHERE ftp.target_table_name = dlp.table_name
  AND COALESCE(ftp.is_active, TRUE)
  AND (dlp.lifecycle_root_table IS NULL OR TRIM(COALESCE(dlp.lifecycle_root_table, '')) = '');

UPDATE public.api_endpoints
SET custom_json = '{"query": "SELECT id, table_name, pk_column, destination_type::text AS destination_type, movement_type::text AS movement_type, sync_strategy::text AS sync_strategy, sync_batch_size, time_column, filter_condition, destination_table, is_public_on_s3, archive_source_table, purge_after_interval_minutes, transfer_mode::text AS transfer_mode, last_archive_completed_at, last_purge_completed_at, lifecycle_root_table FROM public.data_lifecycle_policy WHERE COALESCE(is_active, true) = true AND purge_enabled = true AND sync_interval_minutes IS NOT NULL AND last_archive_completed_at IS NOT NULL AND ( COALESCE(purge_after_interval_minutes, 0) = 0 OR last_archive_completed_at + (purge_after_interval_minutes || '' minutes'')::interval <= now() ) AND ( last_purge_completed_at IS NULL OR last_purge_completed_at + (sync_interval_minutes || '' minutes'')::interval <= now() ) AND ( ( destination_type = ''postgres_archive''::public.destination_type_enum AND lifecycle_root_table IS NOT NULL ) OR ( destination_type = ''iceberg''::public.destination_type_enum AND EXISTS ( SELECT 1 FROM public.data_lifecycle_batch_ledger bl WHERE bl.policy_id = public.data_lifecycle_policy.id AND bl.operation = ''iceberg_export'' AND bl.status = ''completed'' AND bl.purged_at IS NULL ) ) )"}'::jsonb
WHERE path = '/job-workflows/lifecycle_policies_purge_due' AND method = 'GET';

-- Menu: run release **11_dev_console_lifecycle_batch_ledger_menu.sql** (or db-structure/update_old_db_dev_console_lifecycle_ledger_menu.sql) so "Lifecycle batch ledger" appears in Developer Console.

-- ---------------------------------------------------------------------------
-- Legacy policy shape: table_name used to be hot root — migrate to flat source + root column.
-- Canonical: db-structure/update_old_db_data_lifecycle_migrate_root_to_flat_source.sql
-- ---------------------------------------------------------------------------
UPDATE public.data_lifecycle_policy dlp
SET
    lifecycle_root_table = TRIM(ftp.table_name::text),
    table_name = TRIM(ftp.target_table_name::text),
    destination_table = 'archived_' || TRIM(ftp.target_table_name::text),
    last_updated = CURRENT_TIMESTAMP
FROM public.flattening_table_policy ftp
WHERE TRIM(ftp.table_name::text) = TRIM(dlp.table_name::text)
  AND TRIM(COALESCE(ftp.target_table_name::text, '')) <> ''
  AND TRIM(ftp.target_table_name::text) IS DISTINCT FROM TRIM(dlp.table_name::text)
  AND COALESCE(ftp.is_active, TRUE)
  AND dlp.destination_type::text IN ('postgres_archive', 's3');
