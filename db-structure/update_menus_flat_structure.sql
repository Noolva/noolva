-- Update all menu items to have parent_id = NULL (flat structure)
-- This removes the nested hierarchy and makes all menus direct children of their apps

-- Update Organization app menus (app_id = 4)
UPDATE public.menus 
SET parent_id = NULL 
WHERE app_id = 4 
  AND parent_id IS NOT NULL 
  AND type = 'item';

-- Update App Studio app menus (app_id = 5)
UPDATE public.menus 
SET parent_id = NULL 
WHERE app_id = 5 
  AND parent_id IS NOT NULL 
  AND type = 'item';

-- Update Developer Console app menus (app_id = 6 or whatever the ID is)
UPDATE public.menus 
SET parent_id = NULL 
WHERE app_id IN (
    SELECT app_id FROM public.apps WHERE app_name = 'developer_console'
)
  AND parent_id IS NOT NULL 
  AND type = 'item';

-- Delete group type menus (they're no longer needed)
DELETE FROM public.menus 
WHERE type = 'group' 
  AND app_id IN (
    SELECT app_id FROM public.apps 
    WHERE app_name IN ('organization', 'app_studio', 'developer_console')
  );

-- Optional: Update all menu items across all apps to be flat (if you want a blanket update)
-- UPDATE public.menus 
-- SET parent_id = NULL 
-- WHERE parent_id IS NOT NULL 
--   AND type = 'item';
