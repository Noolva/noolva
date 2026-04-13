-- Run from repo root (noolva/) as cwd, or: psql ... -f release_1.0.5_db_updates_pip_migration_infos/00_run_release_1_0_5_from_13_copy_paste_repo_root.sql
\set ON_ERROR_STOP on
\i release_1.0.5_db_updates_pip_migration_infos/13_global_icons.sql
\i release_1.0.5_db_updates_pip_migration_infos/14_global_icons_v2_platform_metadata.sql
\i release_1.0.5_db_updates_pip_migration_infos/15_instance_menus.sql
