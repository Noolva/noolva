-- ==========================================
-- Developer Console App - Database Update Queries
-- ==========================================
-- Run these queries on your existing database to add the Developer Console app
-- Execute after ensuring you have a system user

-- Step 1: Insert Developer Console App
INSERT INTO public.apps (app_name, app_title, app_description, app_image_url, tenant_id, company_id, is_saas_default, is_builtin, is_active, order_no, created_by)
SELECT 
    'developer_console',
    'Developer Console',
    'Database administration and query tools',
    '/assets/developer_console_app_icon.svg',
    NULL,
    NULL,
    TRUE,
    TRUE,
    TRUE,
    50,
    (SELECT user_id FROM public.users WHERE user_type = 'system' LIMIT 1)
WHERE NOT EXISTS (
    SELECT 1 FROM public.apps 
    WHERE app_name = 'developer_console' 
    AND tenant_id IS NULL 
    AND company_id IS NULL
)
RETURNING app_id;

-- Step 2: Get the Developer Console app_id (replace with actual ID if needed)
-- Let's use a DO block to handle this properly
DO $$
DECLARE
    system_user_id INT;
    dev_console_app_id INT;
    dev_console_parent INT;
BEGIN
    -- Get system user
    SELECT user_id INTO system_user_id FROM public.users WHERE user_type = 'system' LIMIT 1;
    
    -- Insert or get Developer Console app
    INSERT INTO public.apps (app_name, app_title, app_description, app_image_url, tenant_id, company_id, is_saas_default, is_builtin, is_active, order_no, created_by)
    VALUES ('developer_console', 'Developer Console', 'Database administration and query tools', '/assets/developer_console_app_icon.svg', NULL, NULL, TRUE, TRUE, TRUE, 50, system_user_id)
    ON CONFLICT ON CONSTRAINT unique_app_per_tenant_scope
    DO UPDATE SET app_title = EXCLUDED.app_title, last_updated = CURRENT_TIMESTAMP
    RETURNING app_id INTO dev_console_app_id;

    IF dev_console_app_id IS NULL THEN
        SELECT app_id INTO dev_console_app_id FROM public.apps WHERE app_name='developer_console' AND tenant_id IS NULL AND company_id IS NULL LIMIT 1;
    END IF;

    -- Create parent menu group
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id = dev_console_app_id AND parent_id IS NULL AND menu_title = 'Developer Console') THEN
        INSERT INTO public.menus (menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by)
        VALUES ('Developer Console', NULL, 'group', NULL, 'code', dev_console_app_id, 'saas', TRUE, 1, system_user_id)
        RETURNING menu_id INTO dev_console_parent;
    ELSE
        SELECT menu_id INTO dev_console_parent FROM public.menus WHERE app_id = dev_console_app_id AND parent_id IS NULL AND menu_title = 'Developer Console' LIMIT 1;
    END IF;

    -- Insert Database menu
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id=dev_console_parent AND menu_title='Database') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Database',dev_console_parent,'item','dev_console_database','database',dev_console_app_id,'saas',TRUE,10,system_user_id);
    END IF;

    -- Insert Db Query menu
    IF NOT EXISTS (SELECT 1 FROM public.menus WHERE app_id=dev_console_app_id AND parent_id=dev_console_parent AND menu_title='Db Query') THEN
        INSERT INTO public.menus (menu_title,parent_id,type,route_path,icon,app_id,scope,is_builtin,order_no,created_by)
        VALUES ('Db Query',dev_console_parent,'item','dev_console_db_query','code',dev_console_app_id,'saas',TRUE,20,system_user_id);
    END IF;
END $$;

-- ==========================================
-- Verification Queries
-- ==========================================

-- Verify app was created
SELECT app_id, app_name, app_title, app_image_url, is_active 
FROM public.apps 
WHERE app_name = 'developer_console';

-- Verify menus were created
SELECT m.menu_id, m.menu_title, m.type, m.route_path, m.order_no, a.app_title
FROM public.menus m
JOIN public.apps a ON m.app_id = a.app_id
WHERE a.app_name = 'developer_console'
ORDER BY m.order_no;
