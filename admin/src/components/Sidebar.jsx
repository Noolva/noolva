import React, { useState, useEffect, useMemo, memo, useRef } from 'react';
import { Menu, Spin, Input, Switch } from 'antd';
import { SearchOutlined, LeftOutlined, RightOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import { renderIcon } from '../utils/iconMapper.jsx';
import { useTheme } from '../contexts/ThemeContext';

const Sidebar = memo(({ selectedApp, selectedAppData, onSelect, onOpenInNewTab, autoHideSidebar = false, onAutoHideSidebarChange, collapsed = false }) => {
    const { isDark, themeKey, themes } = useTheme();
    const [menusCache, setMenusCache] = useState({});
    const [loading, setLoading] = useState(false);
    const [search, setSearch] = useState('');
    const fetchingRef = useRef(new Set());

    const palette = useMemo(() => (themes[themeKey] || themes.default)[isDark ? 'dark' : 'light'], [themeKey, themes, isDark]);
    const sidebarTextColor = palette?.text ?? (isDark ? '#f8fafc' : '#101828');
    const sidebarTextSecondary = palette?.textSecondary ?? (isDark ? '#cbd5e1' : '#475467');
    const sidebarBorderColor = palette?.border ?? (isDark ? '#26324a' : '#e4e7ec');

    const currentAppKey = selectedAppData?.app_id || selectedAppData?.app_uuid || selectedAppData?.app_name || selectedApp;
    const menus = menusCache[currentAppKey] || [];

    useEffect(() => {
        const fetchMenus = async () => {
            if (!selectedApp || !selectedAppData) return;
            const appKey = selectedAppData.app_id || selectedAppData.app_uuid || selectedAppData.app_name || selectedApp;
            if (menusCache[appKey] || fetchingRef.current.has(appKey)) return;
            try {
                fetchingRef.current.add(appKey);
                setLoading(true);
                const appId = selectedAppData.app_id || selectedApp;
                const response = await api.getMenusForApp(appId);
                const menusList = Array.isArray(response) ? response : (response?.menus || response?.data || []);
                setMenusCache(prev => ({ ...prev, [appKey]: menusList }));
            } catch (error) {
                console.error('Failed to fetch menus:', error);
                setMenusCache(prev => ({ ...prev, [appKey]: [] }));
            } finally {
                setLoading(false);
                fetchingRef.current.delete(appKey);
            }
        };
        fetchMenus();
    }, [selectedApp, selectedAppData]);

    // Build two-level tree: parent_id null = root, else child of that parent
    const { roots, mapById } = useMemo(() => {
        const mapById = new Map();
        (menus || []).forEach(m => {
            mapById.set(m.menu_id, { ...m, children: [] });
        });
        const roots = [];
        (menus || []).forEach(m => {
            const node = mapById.get(m.menu_id);
            if (!m.parent_id) {
                roots.push(node);
            } else {
                const parent = mapById.get(m.parent_id);
                if (parent) parent.children.push(node);
                else roots.push(node);
            }
        });
        roots.sort((a, b) => (a.order_no ?? 0) - (b.order_no ?? 0));
        roots.forEach(r => r.children?.sort((a, b) => (a.order_no ?? 0) - (b.order_no ?? 0)));
        return { roots, mapById };
    }, [menus]);

    // Filter by search (menu_title)
    const filteredRoots = useMemo(() => {
        if (!search.trim()) return roots;
        const q = search.trim().toLowerCase();
        const match = (m) => (m.menu_title || '').toLowerCase().includes(q);
        return roots
            .map(r => {
                const childrenMatch = (r.children || []).filter(match);
                const selfMatch = match(r);
                if (selfMatch) return { ...r, children: r.children };
                if (childrenMatch.length) return { ...r, children: childrenMatch };
                return null;
            })
            .filter(Boolean);
    }, [roots, search]);

    // Right-click: show context menu "Open in new tab"
    const [contextMenu, setContextMenu] = useState({ visible: false, x: 0, y: 0, url: null });
    const handleContextMenu = (e, menuKey) => {
        e.preventDefault();
        e.stopPropagation();
        const params = new URLSearchParams();
        params.set('app', String(selectedApp));
        params.set('tab', String(menuKey));
        // Preserve account parameter when opening in new tab
        const accountId = new URLSearchParams(window.location.search).get('account');
        if (accountId) {
            params.set('account', accountId);
        }
        const url = `${window.location.origin}${window.location.pathname}?${params.toString()}`;
        setContextMenu({ visible: true, x: e.clientX, y: e.clientY, url });
    };
    const closeContextMenu = () => setContextMenu(prev => ({ ...prev, visible: false }));
    useEffect(() => {
        if (!contextMenu.visible) return;
        const close = () => closeContextMenu();
        window.addEventListener('click', close);
        return () => window.removeEventListener('click', close);
    }, [contextMenu.visible]);

    const buildMenuItems = (items) => {
        return items.map((menu) => {
            const key = menu.menu_id || menu.menu_uuid;
            const hasChildren = menu.children && menu.children.length > 0;
            const handleClick = () => onSelect(key, menu);
            const label = (
                <span
                    onContextMenu={(e) => handleContextMenu(e, key)}
                    style={{ display: 'inline-block', width: '100%' }}
                >
                    {menu.menu_title}
                </span>
            );
            const childItems = hasChildren ? buildMenuItems(menu.children) : undefined;
            return {
                key,
                label,
                icon: menu.icon ? renderIcon(menu.icon) : null,
                children: childItems,
                onClick: !hasChildren ? handleClick : undefined,
            };
        });
    };

    const menuItems = useMemo(() => buildMenuItems(filteredRoots), [filteredRoots, onSelect, selectedApp]);

    const showLoading = loading && menus.length === 0;
    const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:9001';
    const appIconRaw = selectedAppData?.app_image_url;
    const appIcon =
        appIconRaw
            ? (appIconRaw.startsWith('http') ? appIconRaw : `${apiBaseUrl}${appIconRaw}`)
            : null;
    const appTitle = selectedAppData?.app_title || selectedAppData?.app_name || 'App';

    return (
        <div
            style={{
                height: '100%',
                opacity: selectedApp ? 1 : 0,
                transition: 'opacity 0.2s ease-in-out',
                overflow: 'hidden',
                display: 'flex',
                flexDirection: 'column',
            }}
        >
            {/* App name + icon (compact) - theme-aware colors; Auto-hide sidebar toggle */}
            <div
                style={{
                    flexShrink: 0,
                    padding: collapsed ? '8px' : '8px 12px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: collapsed ? 'center' : undefined,
                    gap: 8,
                    borderBottom: `1px solid ${sidebarBorderColor}`,
                    minHeight: 40,
                }}
            >
                {!collapsed && (appIcon ? (
                    <img src={appIcon} alt="" width={24} height={24} style={{ borderRadius: 4, objectFit: 'contain', flexShrink: 0 }} />
                ) : (
                    <span style={{ width: 24, height: 24, borderRadius: 4, background: sidebarTextSecondary, opacity: 0.5, display: 'inline-block', flexShrink: 0 }} />
                ))}
                {!collapsed && (
                    <span style={{ fontSize: 13, fontWeight: 600, color: sidebarTextColor, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', flex: 1, minWidth: 0 }}>
                        {appTitle}
                    </span>
                )}
                {onAutoHideSidebarChange && (
                    <Switch
                        size="small"
                        checked={!!autoHideSidebar}
                        onChange={(checked) => onAutoHideSidebarChange(checked)}
                        checkedChildren={<LeftOutlined style={{ fontSize: 10 }} />}
                        unCheckedChildren={<RightOutlined style={{ fontSize: 10 }} />}
                        title="Auto-hide sidebar (collapse when mouse leaves)"
                        aria-label="Auto-hide sidebar"
                    />
                )}
            </div>

            {/* Search box - theme-aware colors (hidden when collapsed) */}
            {!collapsed && (
                <div style={{ flexShrink: 0, padding: '6px 8px' }}>
                    <Input
                        placeholder="Filter menus"
                        prefix={<SearchOutlined style={{ color: sidebarTextSecondary }} />}
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        allowClear
                        size="small"
                        style={{
                            background: isDark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)',
                            borderColor: sidebarBorderColor,
                            color: sidebarTextColor,
                        }}
                    />
                </div>
            )}

            {showLoading ? (
                <div style={{ padding: 20, textAlign: 'center' }}>
                    <Spin size="small" />
                </div>
            ) : filteredRoots.length === 0 ? (
                <div style={{ padding: 20, textAlign: 'center', color: sidebarTextSecondary }}>
                    {search.trim() ? 'No matching menus' : 'No menus available'}
                </div>
            ) : (
                <div style={{ flex: 1, overflow: 'auto' }}>
                    <Menu
                        mode="inline"
                        inlineCollapsed={collapsed}
                        style={{ height: '100%', borderRight: 0, background: 'transparent' }}
                        items={menuItems}
                        inlineIndent={collapsed ? 0 : 16}
                    />
                </div>
            )}

            {/* Context menu for "Open in new tab" */}
            {contextMenu.visible && contextMenu.url && (
                <div
                    style={{
                        position: 'fixed',
                        left: contextMenu.x,
                        top: contextMenu.y,
                        zIndex: 9999,
                        background: '#fff',
                        border: '1px solid #d9d9d9',
                        borderRadius: 4,
                        boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                        padding: '4px 0',
                        minWidth: 180,
                    }}
                    onClick={(e) => e.stopPropagation()}
                >
                    <div
                        role="button"
                        tabIndex={0}
                        style={{ padding: '6px 12px', cursor: 'pointer', color: '#000' }}
                        onClick={() => {
                            window.open(contextMenu.url, '_blank');
                            closeContextMenu();
                        }}
                        onKeyDown={(e) => e.key === 'Enter' && window.open(contextMenu.url, '_blank')}
                    >
                        Open in new browser tab
                    </div>
                </div>
            )}
        </div>
    );
});

Sidebar.displayName = 'Sidebar';

export default Sidebar;
