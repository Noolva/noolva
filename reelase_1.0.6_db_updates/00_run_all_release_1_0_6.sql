-- =============================================================================
-- Noolva release 1.0.6 — run all DB update scripts in order (production)
-- =============================================================================
-- Use \ir (include relative): each file loads from THIS directory.
--
--   psql "postgresql://USER:PASSWORD@HOST:5432/DATABASE" -v ON_ERROR_STOP=1 \
--     -f reelase_1.0.6_db_updates/00_run_all_release_1_0_6.sql
--
-- Or from psql (from this directory):
--   \i 00_run_all_release_1_0_6.sql
--
-- All scripts are idempotent (safe to re-run).
-- =============================================================================

\set ON_ERROR_STOP on

\ir 01_flattening_my_tasks_engine.sql
\ir 02_lifecycle_sync_purge_schedulers.sql
\ir 03_data_lifecycle_my_tasks_completed.sql
\ir 04_verify_ui_readiness.sql
\ir 05_lifecycle_incremental_quality.sql
\ir 06_flattening_archive_children.sql
\ir 07_shopping_products_menu.sql
\ir 08_finance_savings_menu.sql
\ir 09_account_categories_seed.sql
\ir 10_bank_accounts_menu.sql
\ir 11_remove_bank_accounts_category.sql
\ir 12_journal_entries_category_nullable.sql
\ir 13_purchase_plans_schema.sql
\ir 14_commitments_schema.sql
\ir 15_meeting_sessions_schema.sql
\ir 16_notes_schema.sql
