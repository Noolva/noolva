-- Update existing databases: Auto Hide Sidebar setting + Asset Gallery menu (child of Assets)
-- Run this on existing DBs that already have apps/menus seeded; safe to run multiple times.

-- 1. Auto Hide Sidebar setting (UI group, boolean)
DO $$
DECLARE
    ft_bool INT;
BEGIN
    SELECT field_type_id INTO ft_bool FROM public.field_types WHERE type_code = 'boolean' LIMIT 1;
    IF ft_bool IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.settings WHERE setting_key = 'auto_hide_sidebar' AND tenant_id IS NULL) THEN
        INSERT INTO public.settings (group_name, setting_key, setting_name, description, field_type_id, default_value, value, scope, is_built_in, field_config_json)
        VALUES ('UI', 'auto_hide_sidebar', 'Auto Hide Sidebar', 'When Yes, the app sidebar is hidden by default.', ft_bool, 'false', 'false', 'global', true, '{}'::jsonb);
    END IF;
END $$;

-- 2. Asset Gallery menu as child of Assets (App Studio)
DO $$
DECLARE
    assets_menu_id INT;
    appstudio_app_id INT;
    system_user_id INT;
BEGIN
    SELECT app_id INTO appstudio_app_id FROM public.apps WHERE app_name = 'app_studio' AND tenant_id IS NULL AND company_id IS NULL LIMIT 1;
    IF appstudio_app_id IS NULL THEN
        SELECT app_id INTO appstudio_app_id FROM public.apps WHERE app_name = 'app_studio' LIMIT 1;
    END IF;
    SELECT user_id INTO system_user_id FROM public.users WHERE user_type = 'system' LIMIT 1;
    IF system_user_id IS NULL THEN
        SELECT user_id INTO system_user_id FROM public.users LIMIT 1;
    END IF;

    IF appstudio_app_id IS NOT NULL THEN
        SELECT menu_id INTO assets_menu_id FROM public.menus WHERE app_id = appstudio_app_id AND menu_title = 'Assets' AND parent_id IS NULL LIMIT 1;
        IF assets_menu_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id = appstudio_app_id AND parent_id = assets_menu_id AND menu_title = 'Asset Gallery') THEN
            INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
            VALUES ('Asset Gallery', assets_menu_id, 'item', 'studio_asset_gallery', 'picture', appstudio_app_id, 'saas', TRUE, 1, system_user_id);
        END IF;
    END IF;
END $$;
