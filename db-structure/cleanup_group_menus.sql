-- Check which menus are type 'group' and should be deleted
SELECT menu_id, menu_title, type, app_id, parent_id 
FROM public.menus 
WHERE type = 'group';

-- Delete all group type menus (they're no longer needed in flat structure)
DELETE FROM public.menus 
WHERE type = 'group';

-- Verify remaining menus (should all be type 'item' or NULL)
SELECT menu_id, menu_title, type, app_id, parent_id 
FROM public.menus 
ORDER BY app_id, order_no;
