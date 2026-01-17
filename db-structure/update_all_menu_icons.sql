-- Update icons for all menu items
-- Icons use simple names that are mapped to Font Awesome classes by iconMapper.js

-- Dashboards app (app_id = 1)
UPDATE public.menus SET icon = 'dashboard' WHERE menu_id = 1 AND menu_title = 'Overview';
UPDATE public.menus SET icon = 'chart-bar' WHERE menu_id = 2 AND menu_title = 'Dashboard Stats';
UPDATE public.menus SET icon = 'file' WHERE menu_id = 3 AND menu_title = 'Reports';

-- Users app (app_id = 2)
UPDATE public.menus SET icon = 'users' WHERE menu_id = 4 AND menu_title = 'User Management';
UPDATE public.menus SET icon = 'user' WHERE menu_id = 5 AND menu_title = 'User List';
UPDATE public.menus SET icon = 'user-plus' WHERE menu_id = 6 AND menu_title = 'Add User';

-- Organization app (app_id = 4)
UPDATE public.menus SET icon = 'bank' WHERE menu_id = 8 AND menu_title = 'Companies';
UPDATE public.menus SET icon = 'appstore' WHERE menu_id = 9 AND menu_title = 'App Menus';
UPDATE public.menus SET icon = 'user' WHERE menu_id = 10 AND menu_title = 'Users';
UPDATE public.menus SET icon = 'users' WHERE menu_id = 11 AND menu_title = 'User Groups';
UPDATE public.menus SET icon = 'team' WHERE menu_id = 12 AND menu_title = 'Teams';
UPDATE public.menus SET icon = 'safety' WHERE menu_id = 13 AND menu_title = 'Roles';
UPDATE public.menus SET icon = 'key' WHERE menu_id = 14 AND menu_title = 'Permissions';

-- Settings app (app_id = 6)
UPDATE public.menus SET icon = 'setting' WHERE menu_id = 15 AND menu_title = 'Settings';

-- App Studio app (app_id = 5)
UPDATE public.menus SET icon = 'shop' WHERE menu_id = 17 AND menu_title = 'App Store';
UPDATE public.menus SET icon = 'appstore' WHERE menu_id = 18 AND menu_title = 'My Apps';
UPDATE public.menus SET icon = 'blocks' WHERE menu_id = 19 AND menu_title = 'Modules';
UPDATE public.menus SET icon = 'star' WHERE menu_id = 20 AND menu_title = 'Features';
UPDATE public.menus SET icon = 'api' WHERE menu_id = 21 AND menu_title = 'Api Endpoints';
UPDATE public.menus SET icon = 'database' WHERE menu_id = 22 AND menu_title = 'Data Models';
UPDATE public.menus SET icon = 'layout' WHERE menu_id = 23 AND menu_title = 'UI Views';
UPDATE public.menus SET icon = 'rocket' WHERE menu_id = 24 AND menu_title = 'Jobs/Actions';
UPDATE public.menus SET icon = 'link' WHERE menu_id = 25 AND menu_title = 'Integration Manager';
UPDATE public.menus SET icon = 'picture' WHERE menu_id = 26 AND menu_title = 'Assets';
UPDATE public.menus SET icon = 'build' WHERE menu_id = 27 AND menu_title = 'UI Components';

-- Developer Console app (app_id = 7)
UPDATE public.menus SET icon = 'database' WHERE menu_id = 29 AND menu_title = 'Database';
UPDATE public.menus SET icon = 'code' WHERE menu_id = 30 AND menu_title = 'Db Query';

-- Verify the updates
SELECT menu_id, menu_title, icon, app_id 
FROM public.menus 
ORDER BY app_id, order_no;
