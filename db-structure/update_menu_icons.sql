-- Update menu icons to use Font Awesome icon names
-- Note: The iconMapper utility will convert these to FA classes
-- This ensures consistency with the iconMapper mapping

-- No changes needed - icon names are already correct
-- The iconMapper.js utility handles conversion from icon names to FA classes
-- Examples:
--   'bank' -> 'fas fa-landmark'
--   'user' -> 'fas fa-user'
--   'users' -> 'fas fa-users'
--   etc.

-- If you want to verify current icon values:
SELECT menu_id, menu_title, icon, app_id 
FROM public.menus 
ORDER BY app_id, order_no;

-- All icons should use simple names (bank, user, users, etc.)
-- The frontend iconMapper will convert them to FA classes
