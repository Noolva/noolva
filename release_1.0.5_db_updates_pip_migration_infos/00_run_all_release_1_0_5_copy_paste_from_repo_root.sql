-- Paste into psql after: \cd /path/to/noolva   (repo root must be current directory)
-- Or run: psql ... -f release_1.0.5_db_updates_pip_migration_infos/00_run_all_release_1_0_5_copy_paste_from_repo_root.sql
\set ON_ERROR_STOP on
\i release_1.0.5_db_updates_pip_migration_infos/01_mobile_agent_fcm_tables.sql
\i release_1.0.5_db_updates_pip_migration_infos/03_flattening_policies_and_job_workflows.sql
\i release_1.0.5_db_updates_pip_migration_infos/04_data_lifecycle_and_job_workflows.sql
\i release_1.0.5_db_updates_pip_migration_infos/05_new_menues.sql
\i release_1.0.5_db_updates_pip_migration_infos/06_flattening_policy_destination_and_db_tables.sql
\i release_1.0.5_db_updates_pip_migration_infos/07_flattening_disable_snapshot.sql
\i release_1.0.5_db_updates_pip_migration_infos/08_data_lifecycle_destination_table_archived_prefix.sql
\i release_1.0.5_db_updates_pip_migration_infos/09_data_lifecycle_archive_purge_columns.sql
\i release_1.0.5_db_updates_pip_migration_infos/10_data_lifecycle_batch_ledger_purge_due.sql
\i release_1.0.5_db_updates_pip_migration_infos/11_dev_console_lifecycle_batch_ledger_menu.sql
\i release_1.0.5_db_updates_pip_migration_infos/12_client_instances_offline.sql
\i release_1.0.5_db_updates_pip_migration_infos/13_global_icons.sql
\i release_1.0.5_db_updates_pip_migration_infos/14_global_icons_v2_platform_metadata.sql
\i release_1.0.5_db_updates_pip_migration_infos/15_instance_menus.sql
