-- Release 1.0.5 — 08_data_lifecycle_destination_table_archived_prefix.sql
-- Canonical: db-structure/update_old_db_data_lifecycle_destination_table_archived_prefix.sql

UPDATE public.data_lifecycle_policy
SET destination_table = 'archived_' || table_name,
    last_updated = now()
WHERE destination_table IS DISTINCT FROM ('archived_' || table_name);
