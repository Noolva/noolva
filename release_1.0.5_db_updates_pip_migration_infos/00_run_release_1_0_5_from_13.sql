-- =============================================================================
-- Noolva release 1.0.5 — DB updates from 13 onward only (global icons + instance menus)
-- =============================================================================
-- Use when scripts 01–12 are already applied on this database.
-- \ir resolves paths relative to THIS file’s directory.
--
--   psql "postgresql://USER:PASSWORD@HOST:5432/DATABASE" -v ON_ERROR_STOP=1 \
--     -f release_1.0.5_db_updates_pip_migration_infos/00_run_release_1_0_5_from_13.sql
--
-- Or in psql:
--   \i /absolute/path/to/noolva/release_1.0.5_db_updates_pip_migration_infos/00_run_release_1_0_5_from_13.sql
-- =============================================================================

\set ON_ERROR_STOP on

\ir 13_global_icons.sql
\ir 14_global_icons_v2_platform_metadata.sql
\ir 15_instance_menus.sql
