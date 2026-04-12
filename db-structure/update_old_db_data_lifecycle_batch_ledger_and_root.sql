-- Batch ledger for lifecycle archive/purge/iceberg + lifecycle_root_table for purge scope.

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

COMMENT ON TABLE public.data_lifecycle_batch_ledger IS
    'Append-only batch audit: archive to postgres/iceberg, purge hot or archived tier; extra may hold pk_values for tier-2 purge.';

ALTER TABLE public.data_lifecycle_policy
    ADD COLUMN IF NOT EXISTS lifecycle_root_table TEXT;

COMMENT ON COLUMN public.data_lifecycle_policy.lifecycle_root_table IS
    'Hot root table_name from flattening_table_policy when source is a flat target; NULL when policy source is archived_* (tier-2).';

UPDATE public.data_lifecycle_policy dlp
SET lifecycle_root_table = ftp.table_name
FROM public.flattening_table_policy ftp
WHERE ftp.target_table_name = dlp.table_name
  AND COALESCE(ftp.is_active, TRUE)
  AND (dlp.lifecycle_root_table IS NULL OR TRIM(COALESCE(dlp.lifecycle_root_table, '')) = '');
