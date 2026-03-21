-- Superseded: "Change password" is top-level under Organization, not under Settings.
-- Use update_old_db_change_password_top_level_organization.sql (or noolvandb_feeds.sql) instead.
-- This script still moves any stray row under Settings if you need that old layout (not recommended).
-- Idempotent.

DO $$
DECLARE
    org_app_id INT;
    settings_parent_id INT;
    system_uid INT;
BEGIN
    SELECT app_id INTO org_app_id
    FROM public.apps
    WHERE app_name = 'organization' AND tenant_id IS NULL AND company_id IS NULL
    LIMIT 1;

    IF org_app_id IS NULL THEN
        RAISE NOTICE 'Organization app not found; skipping.';
        RETURN;
    END IF;

    SELECT user_id INTO system_uid FROM public.users WHERE user_type = 'system' LIMIT 1;

    SELECT menu_id INTO settings_parent_id
    FROM public.menus
    WHERE app_id = org_app_id AND parent_id IS NULL AND menu_title = 'Settings'
    LIMIT 1;

    IF settings_parent_id IS NULL THEN
        RAISE NOTICE 'Settings root menu not found for organization app; skipping.';
        RETURN;
    END IF;

    UPDATE public.menus
    SET route_path = NULL, last_updated = CURRENT_TIMESTAMP
    WHERE menu_id = settings_parent_id AND route_path = 'settings';

    -- Move orphan "Change password" (wrong parent_id) under Settings
    UPDATE public.menus
    SET parent_id = settings_parent_id, last_updated = CURRENT_TIMESTAMP
    WHERE app_id = org_app_id
      AND menu_title = 'Change password'
      AND route_path = 'change_password'
      AND (parent_id IS NULL OR parent_id <> settings_parent_id);

    IF NOT EXISTS (
        SELECT 1 FROM public.menus
        WHERE app_id = org_app_id AND parent_id = settings_parent_id AND route_path = 'settings'
    ) THEN
        INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
        VALUES ('General', settings_parent_id, 'item', 'settings', 'setting', org_app_id, 'saas', TRUE, 10, system_uid);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.menus
        WHERE app_id = org_app_id AND parent_id = settings_parent_id AND route_path = 'change_password'
    ) THEN
        INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
        VALUES ('Change password', settings_parent_id, 'item', 'change_password', 'key', org_app_id, 'saas', TRUE, 20, system_uid);
    END IF;
END $$;
