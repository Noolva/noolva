-- Release 1.0.5 — Client instances + offline sync tables + Developer Console menu
-- Canonical: db-structure/update_old_db_client_instances_offline.sql (same statements).

-- Update existing databases: client instances + offline sync configuration (operator-managed).
-- Canonical copy: db-structure/noolvandb_schema.sql (section 4b).
-- Apply after flattening_table_policy, api_endpoints, data_models, companies exist.

CREATE TABLE IF NOT EXISTS public.instances (
    instance_id SERIAL PRIMARY KEY,
    instance_uuid UUID DEFAULT gen_random_uuid() NOT NULL UNIQUE,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    company_id INTEGER REFERENCES public.companies(company_id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_instances_company ON public.instances(company_id);

CREATE TABLE IF NOT EXISTS public.instance_offline_settings (
    instance_id INTEGER PRIMARY KEY REFERENCES public.instances(instance_id) ON DELETE CASCADE,
    enable_offline_data BOOLEAN DEFAULT FALSE NOT NULL,
    schema_pack_version TEXT NOT NULL DEFAULT '1',
    operator_notes TEXT,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS public.client_offline_dataset (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER NOT NULL REFERENCES public.instances(instance_id) ON DELETE CASCADE,
    dataset_key TEXT NOT NULL,
    label TEXT,
    source_kind TEXT NOT NULL CHECK (source_kind IN ('hot_auto_crud_get', 'flattened_api_get', 'flattened_s3')),
    model_id INTEGER REFERENCES public.data_models(model_id) ON DELETE SET NULL,
    flattening_policy_id INTEGER REFERENCES public.flattening_table_policy(id) ON DELETE SET NULL,
    read_endpoint_id INTEGER REFERENCES public.api_endpoints(endpoint_id) ON DELETE SET NULL,
    incremental_field TEXT,
    batch_size INTEGER,
    local_lifecycle_jsonb JSONB DEFAULT '{}'::jsonb NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (instance_id, dataset_key)
);

CREATE INDEX IF NOT EXISTS idx_client_offline_dataset_instance ON public.client_offline_dataset(instance_id);

CREATE TABLE IF NOT EXISTS public.client_offline_write_endpoint (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER NOT NULL REFERENCES public.instances(instance_id) ON DELETE CASCADE,
    endpoint_id INTEGER NOT NULL REFERENCES public.api_endpoints(endpoint_id) ON DELETE CASCADE,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    idate TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (instance_id, endpoint_id)
);

CREATE INDEX IF NOT EXISTS idx_client_offline_write_endpoint_instance ON public.client_offline_write_endpoint(instance_id);

-- Developer Console menu: Client instances (offline sync configuration)
DO $$
DECLARE
    dev_id INT;
    uid INT;
BEGIN
    SELECT app_id INTO dev_id FROM public.apps WHERE app_name = 'developer_console' AND tenant_id IS NULL AND company_id IS NULL LIMIT 1;
    IF dev_id IS NULL THEN
        SELECT app_id INTO dev_id FROM public.apps WHERE app_name = 'developer_console' LIMIT 1;
    END IF;
    IF dev_id IS NULL THEN
        RAISE NOTICE 'developer_console app not found; skip Client instances menu';
        RETURN;
    END IF;
    SELECT user_id INTO uid FROM public.users WHERE is_super_admin = TRUE LIMIT 1;
    IF uid IS NULL THEN
        SELECT user_id INTO uid FROM public.users ORDER BY user_id LIMIT 1;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id = dev_id AND parent_id IS NULL AND route_path = 'dev_console_client_instances') THEN
        INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
        VALUES ('Client instances', NULL, 'item', 'dev_console_client_instances', 'mobile', dev_id, 'saas', TRUE, 56, uid);
    END IF;
END $$;
