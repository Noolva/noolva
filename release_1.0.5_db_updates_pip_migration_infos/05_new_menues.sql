-- Standalone SQL (NOT PL/pgSQL).
-- Adds Dev Console menus: Flattened Datas, Data Life Cycles.
-- Note: implemented without CTE/WITH for maximum compatibility.

INSERT INTO public.menus (
    menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by
)
SELECT
    'Flattened Datas', NULL, 'item', 'dev_console_flattened_datas', 'table',
    dc.app_id, 'saas', TRUE, 52, su.user_id
FROM (
    SELECT user_id
    FROM public.users
    WHERE user_type = 'system'
    ORDER BY user_id
    LIMIT 1
) su
CROSS JOIN (
    SELECT app_id
    FROM public.apps
    WHERE app_name = 'developer_console'
      AND tenant_id IS NULL
      AND company_id IS NULL
    ORDER BY app_id
    LIMIT 1
) dc
WHERE NOT EXISTS (
    SELECT 1
    FROM public.menus m
    WHERE m.app_id = dc.app_id
      AND m.parent_id IS NULL
      AND m.menu_title = 'Flattened Datas'
);

INSERT INTO public.menus (
    menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by
)
SELECT
    'Data Life Cycles', NULL, 'item', 'dev_console_data_lifecycle', 'swap',
    dc.app_id, 'saas', TRUE, 53, su.user_id
FROM (
    SELECT user_id
    FROM public.users
    WHERE user_type = 'system'
    ORDER BY user_id
    LIMIT 1
) su
CROSS JOIN (
    SELECT app_id
    FROM public.apps
    WHERE app_name = 'developer_console'
      AND tenant_id IS NULL
      AND company_id IS NULL
    ORDER BY app_id
    LIMIT 1
) dc
WHERE NOT EXISTS (
    SELECT 1
    FROM public.menus m
    WHERE m.app_id = dc.app_id
      AND m.parent_id IS NULL
      AND m.menu_title = 'Data Life Cycles'
);