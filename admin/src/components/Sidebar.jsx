import React, { useState, useEffect } from 'react';
import { Menu, Spin } from 'antd';
import { api } from '../utils/api';
import { renderIcon } from '../utils/iconMapper.jsx';

const Sidebar = ({ selectedApp, selectedAppData, onSelect }) => {
    const [menus, setMenus] = useState([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        const fetchMenus = async () => {
            if (!selectedApp || !selectedAppData) {
                setMenus([]);
                return;
            }

            try {
                setLoading(true);
                // selectedApp could be app_id or app_name, try app_id first
                const appId = selectedAppData.app_id || selectedApp;
                console.log('Fetching menus for appId:', appId, 'selectedAppData:', selectedAppData);
                const response = await api.getMenusForApp(appId);
                console.log('API response:', response);
                // Handle both response formats: {menus: [...]} or direct array
                const menusList = Array.isArray(response) ? response : (response?.menus || response?.data || []);
                console.log('Menus list:', menusList);
                setMenus(menusList);
            } catch (error) {
                console.error('Failed to fetch menus:', error);
                setMenus([]);
            } finally {
                setLoading(false);
            }
        };

        fetchMenus();
    }, [selectedApp, selectedAppData]);

    const menuItems = menus.map((menu) => ({
        key: menu.menu_id || menu.menu_uuid,
        label: menu.menu_title,
        icon: menu.icon ? renderIcon(menu.icon) : null,
        onClick: () => onSelect(menu.route_path || menu.menu_id || menu.menu_title, menu),
    }));

    if (loading) {
        return (
            <div style={{ padding: 20, textAlign: 'center' }}>
                <Spin size="small" />
            </div>
        );
    }

    if (menus.length === 0) {
        return (
            <div style={{ padding: 20, textAlign: 'center', color: '#999' }}>
                No menus available
            </div>
        );
    }

    return (
        <Menu
            mode="inline"
            style={{ height: '100%', borderRight: 0 }}
            items={menuItems}
        />
    );
};

export default Sidebar;