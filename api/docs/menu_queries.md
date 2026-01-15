# Menu System - Sample SQL Queries

This document provides sample SQL queries for working with the dynamic menu system.

## Table Structure

- `apps` - Applications/Modules
- `menus` - Menu items (linked to apps)
- `menu_permissions` - Role-based menu permissions
- `user_module_features` - User-specific feature permissions
- `roles` - User roles
- `user_roles` - User-role assignments

## Sample Queries

### 1. Get All Apps for a User

```sql
-- Get all apps that a user has access to (via menus they can see)
SELECT DISTINCT 
    a.app_id, 
    a.app_uuid, 
    a.app_name, 
    a.app_title, 
    a.app_image_url, 
    a.app_description, 
    a.order_no
FROM public.apps a
INNER JOIN public.menus m ON a.app_id = m.app_id
WHERE m.is_hidden = FALSE
  AND m.is_builtin = TRUE  -- Or check permissions
ORDER BY a.order_no, a.app_title;
```

### 2. Get Menus for a Specific App

```sql
-- Get all menus for app_id = 1
SELECT 
    m.menu_id, 
    m.menu_uuid, 
    m.menu_title, 
    m.parent_id, 
    m.route_path,
    m.icon, 
    m.order_no, 
    m.app_id, 
    m.scope, 
    m.type, 
    m.view_id,
    m.module_feature_id, 
    m.is_builtin, 
    m.is_hidden
FROM public.menus m
WHERE m.app_id = 1
  AND m.is_hidden = FALSE
ORDER BY m.order_no, m.menu_title;
```

### 3. Get Menus with Hierarchical Structure

```sql
-- Get menus with parent-child relationships
WITH RECURSIVE menu_tree AS (
    -- Root menus (no parent)
    SELECT 
        m.menu_id,
        m.menu_uuid,
        m.menu_title,
        m.parent_id,
        m.route_path,
        m.icon,
        m.order_no,
        m.app_id,
        1 as level,
        ARRAY[m.menu_id] as path
    FROM public.menus m
    WHERE m.app_id = 1
      AND m.parent_id IS NULL
      AND m.is_hidden = FALSE
    
    UNION ALL
    
    -- Child menus
    SELECT 
        m.menu_id,
        m.menu_uuid,
        m.menu_title,
        m.parent_id,
        m.route_path,
        m.icon,
        m.order_no,
        m.app_id,
        mt.level + 1,
        mt.path || m.menu_id
    FROM public.menus m
    INNER JOIN menu_tree mt ON m.parent_id = mt.menu_id
    WHERE m.is_hidden = FALSE
      AND NOT m.menu_id = ANY(mt.path)  -- Prevent cycles
)
SELECT * FROM menu_tree
ORDER BY level, order_no;
```

### 4. Get Menus Based on User Roles

```sql
-- Get menus accessible to a user based on their roles
SELECT DISTINCT 
    m.menu_id, 
    m.menu_uuid, 
    m.menu_title, 
    m.parent_id, 
    m.route_path,
    m.icon, 
    m.order_no, 
    m.app_id
FROM public.menus m
LEFT JOIN public.menu_permissions mp ON m.menu_id = mp.menu_id
WHERE m.app_id = 1
  AND m.is_hidden = FALSE
  AND (
      m.is_builtin = TRUE OR
      mp.role_id IN (
          SELECT role_id 
          FROM public.user_roles 
          WHERE user_id = 1  -- Replace with actual user_id
      )
  )
ORDER BY m.order_no, m.menu_title;
```

### 5. Insert Sample App

```sql
-- Insert a new app
INSERT INTO public.apps (
    app_name,
    app_title,
    app_image_url,
    app_description,
    order_no,
    is_saas_default,
    is_tenant_default,
    is_builtin
) VALUES (
    'dashboards',
    'Dashboards',
    'https://cdn.avkaran.com/assets/dashboards_app_icon.png',
    'Dashboard and analytics application',
    1,
    FALSE,
    FALSE,
    TRUE
) RETURNING app_id, app_uuid;
```

### 6. Insert Sample Menus for an App

```sql
-- Insert menus for an app (example: Dashboards app with app_id = 1)
-- Root menu: Overview
INSERT INTO public.menus (
    menu_title,
    parent_id,
    route_path,
    icon,
    app_id,
    type,
    scope,
    order_no,
    is_builtin,
    is_hidden
) VALUES (
    'Overview',
    NULL,
    '/dashboards/overview',
    'AppstoreOutlined',
    1,  -- app_id
    'item',
    'both',
    1,
    TRUE,
    FALSE
) RETURNING menu_id;

-- Child menu: Dashboard Stats (under Overview)
INSERT INTO public.menus (
    menu_title,
    parent_id,
    route_path,
    icon,
    app_id,
    type,
    scope,
    order_no,
    is_builtin,
    is_hidden
) VALUES (
    'Dashboard Stats',
    (SELECT menu_id FROM public.menus WHERE menu_title = 'Overview' AND app_id = 1 LIMIT 1),
    '/dashboards/stats',
    NULL,
    1,
    'item',
    'both',
    1,
    TRUE,
    FALSE
);

-- Root menu: Reports
INSERT INTO public.menus (
    menu_title,
    parent_id,
    route_path,
    icon,
    app_id,
    type,
    scope,
    order_no,
    is_builtin,
    is_hidden
) VALUES (
    'Reports',
    NULL,
    '/dashboards/reports',
    'FileOutlined',
    1,
    'item',
    'both',
    2,
    TRUE,
    FALSE
);
```

### 7. Insert Menus for Users App

```sql
-- Insert menus for Users app (example: app_id = 2)
-- Root menu: User Management
INSERT INTO public.menus (
    menu_title,
    parent_id,
    route_path,
    icon,
    app_id,
    type,
    scope,
    order_no,
    is_builtin,
    is_hidden
) VALUES (
    'User Management',
    NULL,
    '/users',
    'UserOutlined',
    2,  -- app_id
    'item',
    'both',
    1,
    TRUE,
    FALSE
) RETURNING menu_id;

-- Child menu: User List
INSERT INTO public.menus (
    menu_title,
    parent_id,
    route_path,
    icon,
    app_id,
    type,
    scope,
    order_no,
    is_builtin,
    is_hidden
) VALUES (
    'User List',
    (SELECT menu_id FROM public.menus WHERE menu_title = 'User Management' AND app_id = 2 LIMIT 1),
    '/users/list',
    NULL,
    2,
    'item',
    'both',
    1,
    TRUE,
    FALSE
);

-- Child menu: Add User
INSERT INTO public.menus (
    menu_title,
    parent_id,
    route_path,
    icon,
    app_id,
    type,
    scope,
    order_no,
    is_builtin,
    is_hidden
) VALUES (
    'Add User',
    (SELECT menu_id FROM public.menus WHERE menu_title = 'User Management' AND app_id = 2 LIMIT 1),
    '/users/add',
    NULL,
    2,
    'item',
    'both',
    2,
    TRUE,
    FALSE
);
```

### 8. Grant Menu Access to a Role

```sql
-- Grant menu access to a role
INSERT INTO public.menu_permissions (
    menu_id,
    role_id,
    can_view
) VALUES (
    1,  -- menu_id
    1,  -- role_id
    TRUE
) ON CONFLICT (menu_id, role_id) DO UPDATE SET can_view = TRUE;
```

### 9. Get All Menus with App Information

```sql
-- Get all menus with their app details
SELECT 
    m.menu_id,
    m.menu_title,
    m.route_path,
    m.parent_id,
    m.order_no,
    a.app_id,
    a.app_title,
    a.app_name
FROM public.menus m
LEFT JOIN public.apps a ON m.app_id = a.app_id
WHERE m.is_hidden = FALSE
ORDER BY a.order_no, m.order_no;
```

### 10. Update App Icon URL

```sql
-- Update app icon to use CDN URL
UPDATE public.apps
SET app_image_url = 'https://cdn.avkaran.com/assets/' || app_name || '_app_icon.png'
WHERE app_id = 1;
```

## Notes

- **Menu Hierarchy**: Menus can have parent-child relationships via `parent_id`
- **Permissions**: Menus are controlled by `menu_permissions` (role-based) and `user_module_features` (user-specific)
- **Scope**: Menus have a `scope` field: 'saas', 'tenant', or 'both'
- **Built-in**: `is_builtin = TRUE` menus are always visible to users
- **Hidden**: `is_hidden = TRUE` menus are never shown
- **Order**: Use `order_no` to control menu/app display order

## API Endpoints

- `GET /auth/apps` - Get all apps user has access to
- `GET /auth/apps/{app_id}/menus` - Get menus for a specific app
- `GET /auth/menus` - Get all menus (legacy, includes apps)
