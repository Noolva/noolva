-- Put "Change password" at top level (parent_id NULL) on every app with app_name = 'organization'.
-- Each tenant/company-scoped Organization app has its own app_id; menus are per app_id.
-- order_no 82 keeps it after Settings (80) and before Themes (85). Idempotent.

DO $$
DECLARE
    org_app_id INT;
    system_uid INT;
BEGIN
    SELECT user_id INTO system_uid FROM public.users WHERE user_type = 'system' LIMIT 1;

    FOR org_app_id IN SELECT a.app_id FROM public.apps a WHERE a.app_name = 'organization'
    LOOP
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
