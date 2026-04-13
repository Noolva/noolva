-- =============================================================================
-- Noolva release 1.0.5 — run all DB update scripts in order (production)
-- =============================================================================
-- Use \ir (include relative): each file loads from THIS directory.
--
-- Prefer ONE of these (do not paste line-by-line into psql — that breaks \echo quotes):
--
--   psql "postgresql://USER:PASSWORD@HOST:5432/DATABASE" -v ON_ERROR_STOP=1 \
--     -f release_1.0.5_db_updates_pip_migration_infos/00_run_all_release_1_0_5.sql
--
-- Or from psql:
--   \i /absolute/path/to/noolva/release_1.0.5_db_updates_pip_migration_infos/00_run_all_release_1_0_5.sql
--
-- Canonical copies: db-structure/update_old_db_*.sql. No 02_* in this bundle.
-- =============================================================================

\set ON_ERROR_STOP on

\ir 01_mobile_agent_fcm_tables.sql
\ir 03_flattening_policies_and_job_workflows.sql
\ir 04_data_lifecycle_and_job_workflows.sql
\ir 05_new_menues.sql
\ir 06_flattening_policy_destination_and_db_tables.sql
\ir 07_flattening_disable_snapshot.sql
\ir 08_data_lifecycle_destination_table_archived_prefix.sql
\ir 09_data_lifecycle_archive_purge_columns.sql
\ir 10_data_lifecycle_batch_ledger_purge_due.sql
\ir 11_dev_console_lifecycle_batch_ledger_menu.sql
\ir 12_client_instances_offline.sql
\ir 13_global_icons.sql
\ir 14_global_icons_v2_platform_metadata.sql
\ir 15_instance_menus.sql
