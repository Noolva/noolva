-- Script to remove "users" app and all related menus from the database
-- Since users functionality is now in the Organization app

BEGIN;

-- Step 1: Delete menu permissions for all menus associated with the users app
DELETE FROM public.menu_permissions
WHERE menu_id IN (
    SELECT menu_id 
    FROM public.menus 
    WHERE app_id = (
        SELECT app_id 
        FROM public.apps 
        WHERE app_name = 'users' 
          AND tenant_id IS NULL 
          AND company_id IS NULL
    )
);

-- Step 2: Delete all menus associated with the users app (including child menus)
-- Using CASCADE to handle any remaining dependencies
DELETE FROM public.menus
WHERE app_id = (
    SELECT app_id 
    FROM public.apps 
    WHERE app_name = 'users' 
      AND tenant_id IS NULL 
      AND company_id IS NULL
);

-- Step 3: Delete the users app from the apps table
DELETE FROM public.apps
WHERE app_name = 'users' 
  AND tenant_id IS NULL 
  AND company_id IS NULL;

COMMIT;

-- Verification queries (uncomment to run after the deletion)
-- SELECT app_id, app_name, app_title FROM public.apps WHERE app_name = 'users';
-- SELECT menu_id, menu_title, app_id FROM public.menus WHERE app_id IN (SELECT app_id FROM public.apps WHERE app_name = 'users');
