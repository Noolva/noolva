-- =============================================================================
-- Operator: copy client instances + instance menus (+ offline config) to another DB
-- =============================================================================
--
-- IMPORTANT — backup file noolvandb_bkp20260330.sql in this repo:
--   That dump does NOT define or load public.instances / instance_menus / etc.
--   (Client instances shipped later.) Verify any backup with:
--     grep -E '^-- Name: instances;|^COPY public.instances' noolvandb_bkp....sql
--   Use a newer pg_dump, or export from the source server that already has the feature.
--
-- RECOMMENDED (cleanest): pg_dump data-only from SOURCE, load on TARGET
-- -----------------------------------------------------------------------------
-- On a host that can reach the SOURCE database (replace connection vars):
--
--   pg_dump "postgresql://USER:PASS@SOURCE_HOST:5432/SOURCE_DB" \
--     --data-only --column-inserts \
--     -t public.instances \
--     -t public.instance_offline_settings \
--     -t public.client_offline_dataset \
--     -t public.client_offline_write_endpoint \
--     -t public.instance_menus \
--     -t public.instance_menu_client_config \
--     -f client_instances_and_menus_data.sql
--
--   You may see: "circular foreign-key constraints on this table: instance_menus"
--   That is normal (parent_id -> instance_menus.id). The dump file is still valid.
--   On TARGET, restore using ONE of the options below.
--
-- Review/edit the file for:
--   • instances.company_id — must exist in TARGET public.companies or set NULL
--   • instance_menus.created_by / instance_menu_client_config.created_by — valid TARGET users.user_id or NULL
--   • client_offline_dataset: model_id, flattening_policy_id, read_endpoint_id — must exist on TARGET or NULL
--   • client_offline_write_endpoint.endpoint_id — must exist on TARGET
--
-- RESTORE on TARGET (pick one)
--
-- A) Custom format dump + pg_restore (self-FK on instance_menus)
--    SOURCE:
--      pg_dump "postgresql://..." --data-only --format=custom \
--        -t public.instances \
--        -t public.instance_offline_settings \
--        -t public.client_offline_dataset \
--        -t public.client_offline_write_endpoint \
--        -t public.instance_menus \
--        -t public.instance_menu_client_config \
--        -f client_instances_and_menus.dump
--
--    TARGET — read this before --disable-triggers:
--      • --disable-triggers requires a SUPERUSER (or a role that owns the tables and
--        can disable RI triggers — in practice use user `postgres` on RDS use superuser).
--        Normal app users get: permission denied on "RI_ConstraintTrigger_…"
--      • pg_restore / pg_dump client must not be NEWER than the server for odd SET params:
--        PG 17+ dumps may emit `SET transaction_timeout = 0` which PG16 and older reject.
--        Fix: use the same major version as the server (e.g. PG16 client → PG16 server), OR
--        convert to SQL and delete that line (see “Troubleshooting” below).
--
--    If you ARE superuser on TARGET:
--      pg_restore --data-only --disable-triggers --no-owner --no-acl \
--        -d "postgresql://USER:PASS@TARGET_HOST:5432/TARGET_DB" \
--        client_instances_and_menus.dump
--
--    client_offline_dataset references flattening_table_policy, data_models, api_endpoints.
--    If restore fails with missing flattening_policy_id: copy those policies from SOURCE first,
--    or set flattening_policy_id (and other FKs) to NULL in the dump / target for broken rows.
--
-- B) Plain SQL file: temporarily disable triggers on instance_menus (superuser/table owner)
--      psql "postgresql://..." -v ON_ERROR_STOP=1 <<'SQL'
--      BEGIN;
--      ALTER TABLE public.instance_menus DISABLE TRIGGER ALL;
--      \i client_instances_and_menus_data.sql
--      ALTER TABLE public.instance_menus ENABLE TRIGGER ALL;
--      COMMIT;
--      SQL
--    (\i path must be visible to psql; or merge into one script.)
--
-- C) Plain SQL without superuser: if INSERTs fail, split instance_menus only —
--    run INSERTs with parent_id IS NULL first, then rows with parent_id NOT NULL
--    (edit the generated file or re-export menus in two queries).
--
-- D) Non-superuser + custom .dump: expand to SQL, strip bad SET, apply with psql
--      pg_restore -f client_instances_and_menus.sql client_instances_and_menus.dump
--      # remove PG17+-only setting if server is older:
--      sed -i.bak '/transaction_timeout/d' client_instances_and_menus.sql   # GNU sed
--      # macOS: sed -i '' '/transaction_timeout/d' client_instances_and_menus.sql
--      psql "postgresql://..." -v ON_ERROR_STOP=1 -f client_instances_and_menus.sql
--    You still need FK targets present (flattening policies, endpoints, etc.) or COPY will fail.
--
-- =============================================================================
-- Troubleshooting (common pg_restore failures)
-- =============================================================================
--
-- 1) ERROR: unrecognized configuration parameter "transaction_timeout"
--    Cause: dump built with PostgreSQL 17+ client, target is ≤16.
--    Fix: use pg_dump/pg_restore from the same major version as the server, or method D above.
--
-- 2) permission denied: "RI_ConstraintTrigger_…" on DISABLE TRIGGER ALL
--    Cause: not a superuser; --disable-triggers cannot be used.
--    Fix: connect as postgres superuser, OR omit --disable-triggers and use plain SQL (C/D),
--    fixing instance_menus insert order and all cross-table FKs first.
--
-- 3) client_offline_dataset_flattening_policy_id_fkey (or model_id / read_endpoint_id)
--    Cause: TARGET is missing rows SOURCE referenced.
--    Fix: import matching rows from SOURCE (e.g. flattening_table_policy id=15), or edit data:
--      UPDATE public.client_offline_dataset SET flattening_policy_id = NULL WHERE …;
--    Long-term: include dependent tables in the same dump, or align IDs across environments.
--
-- After loading with explicit ids, fix sequences (adjust table names if needed):
--   SELECT setval(pg_get_serial_sequence('public.instances','instance_id'),
--                 COALESCE((SELECT MAX(instance_id) FROM public.instances), 1));
--   SELECT setval(pg_get_serial_sequence('public.client_offline_dataset','id'),
--                 COALESCE((SELECT MAX(id) FROM public.client_offline_dataset), 1));
--   SELECT setval(pg_get_serial_sequence('public.client_offline_write_endpoint','id'),
--                 COALESCE((SELECT MAX(id) FROM public.client_offline_write_endpoint), 1));
--   SELECT setval(pg_get_serial_sequence('public.instance_menus','id'),
--                 COALESCE((SELECT MAX(id) FROM public.instance_menus), 1));
--   SELECT setval(pg_get_serial_sequence('public.instance_menu_client_config','id'),
--                 COALESCE((SELECT MAX(id) FROM public.instance_menu_client_config), 1));
--
-- =============================================================================
-- OPTIONAL: same PostgreSQL server — copy from a restored DB (dblink)
-- =============================================================================
-- Requires: CREATE EXTENSION IF NOT EXISTS dblink;
-- Replace connection string and WHERE filters (e.g. single instance_id).
--
-- Example pattern (run on TARGET DB). Adjust columns to match your schema.
/*
CREATE EXTENSION IF NOT EXISTS dblink;

-- 1) instances
INSERT INTO public.instances (
    instance_id, instance_uuid, name, description, company_id, is_active, idate, last_updated
)
SELECT *
FROM dblink(
    'host=localhost port=5432 dbname=SOURCE_DB user=... password=...',
    'SELECT instance_id, instance_uuid, name, description, company_id, is_active, idate, last_updated
     FROM public.instances WHERE instance_id = 1'  -- your filter
) AS s(
    instance_id INT,
    instance_uuid UUID,
    name TEXT,
    description TEXT,
    company_id INT,
    is_active BOOLEAN,
    idate TIMESTAMPTZ,
    last_updated TIMESTAMPTZ
)
ON CONFLICT (instance_id) DO NOTHING;

-- 2) instance_offline_settings
INSERT INTO public.instance_offline_settings (
    instance_id, enable_offline_data, schema_pack_version, operator_notes, last_updated
)
SELECT *
FROM dblink(
    'host=localhost port=5432 dbname=SOURCE_DB user=... password=...',
    'SELECT instance_id, enable_offline_data, schema_pack_version, operator_notes, last_updated
     FROM public.instance_offline_settings WHERE instance_id = 1'
) AS s(
    instance_id INT,
    enable_offline_data BOOLEAN,
    schema_pack_version TEXT,
    operator_notes TEXT,
    last_updated TIMESTAMPTZ
)
ON CONFLICT (instance_id) DO NOTHING;

-- 3) client_offline_dataset (all columns — match db-structure/update_old_db_client_instances_offline.sql)
INSERT INTO public.client_offline_dataset (
    id, instance_id, dataset_key, label, source_kind, model_id, flattening_policy_id,
    read_endpoint_id, incremental_field, batch_size, local_lifecycle_jsonb, is_active, idate, last_updated
)
SELECT *
FROM dblink(
    'host=localhost port=5432 dbname=SOURCE_DB user=... password=...',
    'SELECT id, instance_id, dataset_key, label, source_kind, model_id, flattening_policy_id,
            read_endpoint_id, incremental_field, batch_size, local_lifecycle_jsonb, is_active, idate, last_updated
     FROM public.client_offline_dataset WHERE instance_id = 1'
) AS s(
    id INT, instance_id INT, dataset_key TEXT, label TEXT, source_kind TEXT,
    model_id INT, flattening_policy_id INT, read_endpoint_id INT,
    incremental_field TEXT, batch_size INT, local_lifecycle_jsonb JSONB,
    is_active BOOLEAN, idate TIMESTAMPTZ, last_updated TIMESTAMPTZ
)
ON CONFLICT (id) DO NOTHING;

-- 4) client_offline_write_endpoint
INSERT INTO public.client_offline_write_endpoint (
    id, instance_id, endpoint_id, notes, is_active, idate, last_updated
)
SELECT *
FROM dblink(
    'host=localhost port=5432 dbname=SOURCE_DB user=... password=...',
    'SELECT id, instance_id, endpoint_id, notes, is_active, idate, last_updated
     FROM public.client_offline_write_endpoint WHERE instance_id = 1'
) AS s(
    id INT, instance_id INT, endpoint_id INT, notes TEXT,
    is_active BOOLEAN, idate TIMESTAMPTZ, last_updated TIMESTAMPTZ
)
ON CONFLICT (id) DO NOTHING;

-- 5) instance_menus (self-FK parent_id: insert parents before children, or use two steps)
--    Easiest: pg_dump table data in PK order, or insert with same ids if no collision.
INSERT INTO public.instance_menus (
    id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated
)
SELECT *
FROM dblink(
    'host=localhost port=5432 dbname=SOURCE_DB user=... password=...',
    'SELECT id, instance_id, menu_title, route_path, is_builtin, icon_key, parent_id, sort_order, created_by, idate, last_updated
     FROM public.instance_menus WHERE instance_id = 1 ORDER BY id'
) AS s(
    id INT, instance_id INT, menu_title TEXT, route_path TEXT, is_builtin BOOLEAN,
    icon_key TEXT, parent_id INT, sort_order INT, created_by INT, idate TIMESTAMPTZ, last_updated TIMESTAMPTZ
)
ON CONFLICT (id) DO NOTHING;

-- 6) instance_menu_client_config (after instance_menus)
INSERT INTO public.instance_menu_client_config (
    id, instance_menu_id, client_type, render_mode, is_enabled, created_by, idate, last_updated
)
SELECT *
FROM dblink(
    'host=localhost port=5432 dbname=SOURCE_DB user=... password=...',
    'SELECT c.id, c.instance_menu_id, c.client_type, c.render_mode, c.is_enabled, c.created_by, c.idate, c.last_updated
     FROM public.instance_menu_client_config c
     JOIN public.instance_menus m ON m.id = c.instance_menu_id
     WHERE m.instance_id = 1'
) AS s(
    id INT, instance_menu_id INT, client_type TEXT, render_mode TEXT,
    is_enabled BOOLEAN, created_by INT, idate TIMESTAMPTZ, last_updated TIMESTAMPTZ
)
ON CONFLICT (id) DO NOTHING;

-- Then run SELECT setval(...) block above for sequences.
*/

-- =============================================================================
-- End
-- =============================================================================
