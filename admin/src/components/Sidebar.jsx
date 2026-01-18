import React, { useState, useEffect, useMemo, memo, useRef } from 'react';
import { Menu, Spin } from 'antd';
import { api } from '../utils/api';
import { renderIcon } from '../utils/iconMapper.jsx';

const Sidebar = memo(({ selectedApp, selectedAppData, onSelect }) => {
    // Cache menus by app to avoid refetching
    const [menusCache, setMenusCache] = useState({});
    const [loading, setLoading] = useState(false);
    const fetchingRef = useRef(new Set()); // Track which apps are currently being fetched

    // Get current app's menus from cache
    const currentAppKey = selectedAppData?.app_id || selectedAppData?.app_uuid || selectedAppData?.app_name || selectedApp;
    const menus = menusCache[currentAppKey] || [];

    useEffect(() => {
        const fetchMenus = async () => {
            if (!selectedApp || !selectedAppData) {
                return;
            }

            const appKey = selectedAppData.app_id || selectedAppData.app_uuid || selectedAppData.app_name || selectedApp;
            
            // If menus are already cached, don't refetch
            if (menusCache[appKey]) {
                return;
            }

            // If already fetching, don't start another fetch
            if (fetchingRef.current.has(appKey)) {
                return;
            }

            try {
                fetchingRef.current.add(appKey);
                setLoading(true);
                const appId = selectedAppData.app_id || selectedApp;
                const response = await api.getMenusForApp(appId);
                // Handle both response formats: {menus: [...]} or direct array
                const menusList = Array.isArray(response) ? response : (response?.menus || response?.data || []);
                
                // Cache the menus
                setMenusCache(prev => ({
                    ...prev,
                    [appKey]: menusList
                }));
            } catch (error) {
                console.error('Failed to fetch menus:', error);
                // Cache empty array to prevent retries
                setMenusCache(prev => ({
                    ...prev,
                    [appKey]: []
                }));
            } finally {
                setLoading(false);
                fetchingRef.current.delete(appKey);
            }
        };

        fetchMenus();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [selectedApp, selectedAppData]); // menusCache intentionally excluded to avoid infinite loops

    const menuItems = useMemo(() => {
        return menus.map((menu) => ({
            key: menu.menu_id || menu.menu_uuid,
            label: menu.menu_title,
            icon: menu.icon ? renderIcon(menu.icon) : null,
            // Use menu_id as the tab key (cleaner URL), but pass full menu data
            onClick: () => onSelect(menu.menu_id || menu.menu_uuid || menu.route_path || menu.menu_title, menu),
        }));
    }, [menus, onSelect]);

    // Show loading only if we don't have cached menus
    const showLoading = loading && menus.length === 0;

    return (
        <div style={{ 
            height: '100%', 
            opacity: selectedApp ? 1 : 0,
            transition: 'opacity 0.2s ease-in-out',
            overflow: 'hidden'
        }}>
            {showLoading ? (
                <div style={{ padding: 20, textAlign: 'center' }}>
                    <Spin size="small" />
                </div>
            ) : menus.length === 0 ? (
                <div style={{ padding: 20, textAlign: 'center', color: '#999' }}>
                    No menus available
                </div>
            ) : (
                <Menu
                    mode="inline"
                    style={{ height: '100%', borderRight: 0 }}
                    items={menuItems}
                />
            )}
        </div>
    );
});

Sidebar.displayName = 'Sidebar';

export default Sidebar;
