import React, { useState, useEffect } from 'react';
import { Menu, Spin } from 'antd';
import { api } from '../utils/api';

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
                const response = await api.getAppMenus(appId);
                setMenus(response.menus || []);
            } catch (error) {
                console.error('Failed to fetch menus:', error);
                setMenus([]);
            } finally {
                setLoading(false);
            }
        };

        fetchMenus();
    }, [selectedApp, selectedAppData]);

    const renderMenuItems = (menuList) => {
        return menuList.map((menu) => {
            if (menu.children && menu.children.length > 0) {
                return (
                    <Menu.SubMenu
                        key={menu.menu_id || menu.menu_uuid}
                        title={menu.menu_title}
                        icon={menu.icon ? <span>{menu.icon}</span> : null}
                    >
                        {renderMenuItems(menu.children)}
                    </Menu.SubMenu>
                );
            } else {
                return (
                    <Menu.Item
                        key={menu.menu_id || menu.menu_uuid}
                        onClick={() => onSelect(menu.route_path || menu.menu_id, menu)}
                    >
                        {menu.menu_title}
                    </Menu.Item>
                );
            }
        });
    };

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
            defaultOpenKeys={menus.map(m => m.menu_id?.toString() || m.menu_uuid)}
        >
            {renderMenuItems(menus)}
        </Menu>
    );
};

export default Sidebar;