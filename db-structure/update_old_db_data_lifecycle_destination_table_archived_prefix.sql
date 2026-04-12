-- Normalize data_lifecycle_policy.destination_table to archived_<table_name> for all rows.
-- Safe to run multiple times.

UPDATE public.data_lifecycle_policy
SET destination_table = 'archived_' || table_name,
    last_updated = now()
WHERE destination_table IS DISTINCT FROM ('archived_' || table_name);
