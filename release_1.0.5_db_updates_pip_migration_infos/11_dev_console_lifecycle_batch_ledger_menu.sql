-- Release 1.0.5 — Developer Console menu: Lifecycle batch ledger
-- Canonical copy: db-structure/update_old_db_dev_console_lifecycle_ledger_menu.sql
-- Run if the admin UI shows Data Life Cycles but not "Lifecycle batch ledger" (menu row missing from public.menus).

DO $$
DECLARE
    dev_id INT;
    uid INT;
BEGIN
    SELECT app_id INTO dev_id FROM public.apps WHERE app_name = 'developer_console' LIMIT 1;
    IF dev_id IS NULL THEN
        RAISE NOTICE 'developer_console app not found; skip menu';
        RETURN;
    END IF;
    SELECT user_id INTO uid FROM public.users WHERE is_super_admin = TRUE LIMIT 1;

    IF NOT EXISTS (
        SELECT 1 FROM public.menus WHERE app_id = dev_id AND route_path = 'dev_console_data_lifecycle_ledger'
    ) THEN
        INSERT INTO public.menus (
            menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by
        ) VALUES (
            'Lifecycle batch ledger', NULL, 'item', 'dev_console_data_lifecycle_ledger', 'database',
            dev_id, 'saas', TRUE, 54, uid
        );
    END IF;
END $$;
