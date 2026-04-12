-- Migrate legacy data_lifecycle_policy rows where table_name was the HOT ROOT (flattening_table_policy.table_name)
-- to the new shape: table_name = materialized flat (target_table_name), lifecycle_root_table = former root,
-- destination_table = archived_<flat_physical>.
-- Safe for non-production / unchecked envs. Skip rows with no matching active flattening policy.

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

-- OPTIONAL (dev / empty DB): reset batch ledger if re-testing
-- TRUNCATE public.data_lifecycle_batch_ledger RESTART IDENTITY;
-- OPTIONAL: drop wrong archive table named archived_<root> after backing up (example only):
-- DROP TABLE IF EXISTS public.archived_orders CASCADE;
