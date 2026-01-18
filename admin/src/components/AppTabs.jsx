import React, { useState, useRef, useEffect } from 'react';
import { Tabs, Menu } from 'antd';
import {
    CopyOutlined,
    CloseOutlined,
    CloseCircleOutlined,
    ArrowLeftOutlined,
    ArrowRightOutlined,
    ExportOutlined,
} from '@ant-design/icons';
import { useTheme } from '../contexts/ThemeContext';

const AppTabs = ({ 
    tabs, 
    onChange, 
    onEdit,
    renderContent,
    onDuplicate,
    onCloseAll,
    onCloseLeft,
    onCloseRight,
    onCloseOthers,
    onOpenInNewTab
}) => {
    const [contextMenuTab, setContextMenuTab] = useState(null);
    const [contextMenuPosition, setContextMenuPosition] = useState({ x: 0, y: 0 });
    const [contextMenuVisible, setContextMenuVisible] = useState(false);
    const tabsRef = useRef(null);
    const menuContainerRef = useRef(null);
    const { isDark } = useTheme();

    useEffect(() => {
        const handleClickOutside = (e) => {
            if (contextMenuVisible && menuContainerRef.current && !menuContainerRef.current.contains(e.target)) {
                setContextMenuVisible(false);
                setContextMenuTab(null);
            }
        };

        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, [contextMenuVisible]);

    const handleTabContextMenu = (e, tabKey) => {
        e.preventDefault();
        e.stopPropagation();
        setContextMenuTab(tabKey);
        setContextMenuPosition({ x: e.clientX, y: e.clientY });
        setContextMenuVisible(true);
    };

    const handleContextMenuAction = (action, tabKey) => {
        setContextMenuVisible(false);
        setContextMenuTab(null);
        
        switch (action) {
            case 'duplicate':
                onDuplicate?.(tabKey);
                break;
            case 'close':
                onEdit?.(tabKey);
                break;
            case 'closeAll':
                onCloseAll?.();
                break;
            case 'closeLeft':
                onCloseLeft?.(tabKey);
                break;
            case 'closeRight':
                onCloseRight?.(tabKey);
                break;
            case 'closeOthers':
                onCloseOthers?.(tabKey);
                break;
            case 'openInNewTab':
                onOpenInNewTab?.(tabKey);
                break;
            default:
                break;
        }
    };

    const getContextMenu = (tabKey) => {
        const currentIndex = tabs.items.findIndex(tab => tab.key === tabKey);
        const isFirst = currentIndex === 0;
        const isLast = currentIndex === tabs.items.length - 1;
        const hasMultipleTabs = tabs.items.length > 1;

        const menuItems = [
            {
                key: 'duplicate',
                icon: <CopyOutlined />,
                label: 'Duplicate',
            },
            {
                type: 'divider',
            },
            {
                key: 'close',
                icon: <CloseOutlined />,
                label: 'Close',
            },
            {
                key: 'closeOthers',
                icon: <CloseCircleOutlined />,
                label: 'Close Others',
                disabled: !hasMultipleTabs,
            },
            {
                key: 'closeLeft',
                icon: <ArrowLeftOutlined />,
                label: 'Close Left',
                disabled: isFirst || !hasMultipleTabs,
            },
            {
                key: 'closeRight',
                icon: <ArrowRightOutlined />,
                label: 'Close Right',
                disabled: isLast || !hasMultipleTabs,
            },
            {
                key: 'closeAll',
                icon: <CloseCircleOutlined />,
                label: 'Close All',
                disabled: !hasMultipleTabs,
            },
            {
                type: 'divider',
            },
            {
                key: 'openInNewTab',
                icon: <ExportOutlined />,
                label: 'Open in New Browser Tab',
            },
        ];

        return (
            <Menu
                onClick={({ key }) => handleContextMenuAction(key, tabKey)}
                items={menuItems}
            />
        );
    };

    // Add event listeners to tab elements after render
    useEffect(() => {
        if (tabsRef.current) {
            const tabElements = tabsRef.current.querySelectorAll('.ant-tabs-tab');
            const cleanup = [];
            
            tabElements.forEach((tabElement, idx) => {
                // Get tab key from the tabs.items array based on index
                const tabKey = tabs.items[idx]?.key;
                
                if (tabKey) {
                    const handler = (e) => handleTabContextMenu(e, tabKey);
                    tabElement.addEventListener('contextmenu', handler);
                    cleanup.push(() => tabElement.removeEventListener('contextmenu', handler));
                }
            });
            
            return () => cleanup.forEach(fn => fn());
        }
    }, [tabs.items]);

    return (
        <div ref={tabsRef} style={{ position: 'relative' }}>
            <Tabs
                type="editable-card"
                className='custom-window-tabs'
                style={{ marginBottom: 0 }}
                activeKey={tabs.activeKey}
                onChange={onChange}
                onEdit={onEdit}
                hideAdd
                items={tabs.items.map((tab) => ({
                    label: tab.label,
                    key: tab.key,
                    // Render content dynamically from menuData
                    children: renderContent ? renderContent(tab.key, tab.menuData) : <div>Loading...</div>,
                }))}
            />
            {contextMenuVisible && contextMenuTab && (
                <div
                    ref={menuContainerRef}
                    style={{
                        position: 'fixed',
                        left: contextMenuPosition.x,
                        top: contextMenuPosition.y,
                        zIndex: 10000,
                        boxShadow: isDark ? '0 2px 8px rgba(0,0,0,0.65)' : '0 2px 8px rgba(0,0,0,0.15)',
                        backgroundColor: isDark ? '#1f1f1f' : 'white',
                        borderRadius: '4px',
                    }}
                >
                    {getContextMenu(contextMenuTab)}
                </div>
            )}
        </div>
    );
};

export default AppTabs;