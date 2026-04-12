-- Release 1.0.5 — instance menus for client instance apps (not Noolva console menus).
-- Canonical: db-structure/update_old_db_instance_menus.sql (same statements; apply once per environment).

CREATE TABLE IF NOT EXISTS public.instance_menus (
    id SERIAL PRIMARY KEY,
    instance_id INTEGER NOT NULL REFERENCES public.instances(instance_id) ON DELETE CASCADE,
    menu_title TEXT NOT NULL,
    route_path TEXT,
    is_builtin BOOLEAN NOT NULL DEFAULT FALSE,
    icon_key TEXT,
    parent_id INTEGER REFERENCES public.instance_menus(id) ON DELETE CASCADE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_by INTEGER REFERENCES public.users(user_id) ON DELETE SET NULL,
    idate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.instance_menus IS 'Navigation items for client instance apps (mobile/desktop/web shells), not Noolva console menus.';

CREATE UNIQUE INDEX IF NOT EXISTS uq_instance_menus_top_level_title ON public.instance_menus (instance_id, menu_title) WHERE parent_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_instance_menus_child_title ON public.instance_menus (instance_id, parent_id, menu_title) WHERE parent_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_instance_menus_instance ON public.instance_menus (instance_id);
CREATE INDEX IF NOT EXISTS idx_instance_menus_parent ON public.instance_menus (parent_id);

CREATE TABLE IF NOT EXISTS public.instance_menu_client_config (
    id SERIAL PRIMARY KEY,
    instance_menu_id INTEGER NOT NULL REFERENCES public.instance_menus(id) ON DELETE CASCADE,
    client_type TEXT NOT NULL CHECK (client_type IN ('web', 'android', 'ios', 'macos', 'linux')),
    render_mode TEXT NOT NULL CHECK (render_mode IN ('web', 'native', 'webview')),
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_by INTEGER REFERENCES public.users(user_id) ON DELETE SET NULL,
    idate TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (instance_menu_id, client_type)
);

COMMENT ON TABLE public.instance_menu_client_config IS 'How each client stack renders/enables a given instance menu row.';

CREATE INDEX IF NOT EXISTS idx_instance_menu_client_config_menu ON public.instance_menu_client_config (instance_menu_id);

DO $$
DECLARE
    dev_id INT;
    uid INT;
BEGIN
    SELECT app_id INTO dev_id FROM public.apps WHERE app_name = 'developer_console' LIMIT 1;
    IF dev_id IS NULL THEN RETURN; END IF;
    SELECT user_id INTO uid FROM public.users WHERE user_type = 'system' ORDER BY user_id LIMIT 1;
    IF uid IS NULL THEN uid := 1; END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.menus
        WHERE app_id = dev_id AND parent_id IS NULL AND route_path = 'dev_console_instance_menus'
    ) THEN
        INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
        VALUES ('Instance menus', NULL, 'item', 'dev_console_instance_menus', 'unordered-list', dev_id, 'saas', TRUE, 57, uid);
    END IF;
END $$;
