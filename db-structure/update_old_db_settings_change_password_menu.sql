-- For every app with app_name = 'organization': Settings submenu with General; Change password top-level.
-- Tenant/company-scoped Organization apps each have their own app_id and menu rows.
-- Safe to run multiple times (idempotent).

DO $$
DECLARE
    org_app_id INT;
    settings_parent_id INT;
    system_uid INT;
BEGIN
    SELECT user_id INTO system_uid FROM public.users WHERE user_type = 'system' LIMIT 1;

    FOR org_app_id IN SELECT a.app_id FROM public.apps a WHERE a.app_name = 'organization'
    LOOP
        settings_parent_id := NULL;
        SELECT menu_id INTO settings_parent_id
        FROM public.menus
        WHERE app_id = org_app_id AND parent_id IS NULL AND menu_title = 'Settings'
        LIMIT 1;

        IF settings_parent_id IS NULL THEN
            INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
            VALUES ('Settings', NULL, 'item', NULL, 'setting', org_app_id, 'saas', TRUE, 80, system_uid)
            RETURNING menu_id INTO settings_parent_id;
        END IF;

        UPDATE public.menus
        SET route_path = NULL, last_updated = CURRENT_TIMESTAMP
        WHERE menu_id = settings_parent_id AND route_path = 'settings';

        IF NOT EXISTS (
            SELECT 1 FROM public.menus
            WHERE app_id = org_app_id AND parent_id = settings_parent_id AND route_path = 'settings'
        ) THEN
            INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
            VALUES ('General', settings_parent_id, 'item', 'settings', 'setting', org_app_id, 'saas', TRUE, 10, system_uid);
        END IF;

        UPDATE public.menus
        SET parent_id = NULL, order_no = 82, last_updated = CURRENT_TIMESTAMP
        WHERE app_id = org_app_id
          AND menu_title = 'Change password'
          AND route_path = 'change_password';

        IF NOT EXISTS (
            SELECT 1 FROM public.menus
            WHERE app_id = org_app_id AND parent_id IS NULL AND route_path = 'change_password'
        ) THEN
            INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
            VALUES ('Change password', NULL, 'item', 'change_password', 'key', org_app_id, 'saas', TRUE, 82, system_uid);
        END IF;
    END LOOP;
END $$;
