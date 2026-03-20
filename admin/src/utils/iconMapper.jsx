import React from 'react';
import * as AntdIcons from '@ant-design/icons';

/**
 * Maps icon names from database to Font Awesome icon classes
 * Returns the FA class string (e.g., "fas fa-user") or null
 */
export const getIconClass = (iconName) => {
    if (!iconName) return null;
    
    // Icon name to Font Awesome class mapping
    const iconMap = {
        // Organization app icons
        'bank': 'fas fa-landmark',
        'appstore': 'fas fa-th-large',
        'user': 'fas fa-user',
        'users': 'fas fa-users',
        'team': 'fas fa-users-cog',
        'safety': 'fas fa-shield-alt',
        'key': 'fas fa-key',
        'setting': 'fas fa-cog',
        'bgcolors': 'fas fa-palette',
        
        // App Studio icons
        'shop': 'fas fa-store',
        'blocks': 'fas fa-cubes',
        'profile': 'fas fa-user-circle',
        'api': 'fas fa-code',
        'database': 'fas fa-database',
        'layout': 'fas fa-th',
        'rocket': 'fas fa-rocket',
        'link': 'fas fa-link',
        'picture': 'fas fa-image',
        'build': 'fas fa-tools',
        
        // Developer Console icons
        'code': 'fas fa-code',
        'file-text': 'fas fa-file-alt',
        'unordered-list': 'fas fa-list',
        'clock-circle': 'far fa-clock',
        
        // Common icons
        'tool': 'fas fa-wrench',
        'file': 'fas fa-file',
        'dashboard': 'fas fa-tachometer-alt',
        'chart-bar': 'fas fa-chart-bar',
        'user-plus': 'fas fa-user-plus',
        'star': 'fas fa-star',
    };
    
    // If already a full FA class (contains 'fa-'), return as is
    if (iconName.includes('fa-')) {
        // Ensure it has 'fas' or 'far' prefix
        return iconName.startsWith('fa') ? `fas ${iconName}` : iconName;
    }
    
    // Map icon name to FA class
    return iconMap[iconName] || null;
};

/**
 * Renders an icon component based on icon code format
 * Supports: "fa:name", "antd:name", "smily:name", "custom:name"
 * Also supports legacy format (just icon name for FontAwesome)
 */
export const renderIcon = (iconName) => {
    if (!iconName) return null;
    
    // Check if it's the new format with prefix (e.g., "fa:heart", "antd:download")
    if (iconName.includes(':')) {
        const [prefix, name] = iconName.split(':');
        
        switch (prefix) {
            case 'fa':
                // FontAwesome icon
                const faClass = getFontAwesomeClass(name);
                if (faClass) {
                    return <i className={faClass} />;
                }
                break;
            
            case 'antd':
                // Ant Design icon
                return renderAntdIcon(name);
            
            case 'smily':
                // Emoji/Smiley
                return renderSmily(name);
            
            case 'custom':
                // Custom SVG (placeholder for now)
                return <span>[Custom: {name}]</span>;
            
            default:
                // Unknown prefix, try as FontAwesome
                const fallbackClass = getFontAwesomeClass(iconName);
                if (fallbackClass) {
                    return <i className={fallbackClass} />;
                }
        }
        
        return null;
    }
    
    // Legacy format: try as FontAwesome
    const iconClass = getIconClass(iconName);
    if (iconClass) {
        return <i className={iconClass} />;
    }
    
    return null;
};

/**
 * Get FontAwesome class for icon name
 */
function getFontAwesomeClass(iconName) {
    const faIconMap = {
        'home': 'fas fa-home',
        'user': 'fas fa-user',
        'users': 'fas fa-users',
        'cog': 'fas fa-cog',
        'search': 'fas fa-search',
        'bell': 'fas fa-bell',
        'heart': 'fas fa-heart',
        'star': 'fas fa-star',
        'envelope': 'fas fa-envelope',
        'phone': 'fas fa-phone',
        'plus': 'fas fa-plus',
        'edit': 'fas fa-edit',
        'trash': 'fas fa-trash',
        'save': 'fas fa-save',
        'download': 'fas fa-download',
        'upload': 'fas fa-upload',
        'check': 'fas fa-check',
        'times': 'fas fa-times',
        'database': 'fas fa-database',
        'chart-bar': 'fas fa-chart-bar',
        'file': 'fas fa-file',
        'file-text': 'fas fa-file-alt',
        'unordered-list': 'fas fa-list',
        'folder': 'fas fa-folder',
        'building': 'fas fa-building',
        'briefcase': 'fas fa-briefcase',
        'arrow-left': 'fas fa-arrow-left',
        'arrow-right': 'fas fa-arrow-right',
        'arrow-up': 'fas fa-arrow-up',
        'arrow-down': 'fas fa-arrow-down',
        'lock': 'fas fa-lock',
        'unlock': 'fas fa-unlock',
        'shield': 'fas fa-shield-alt',
        'key': 'fas fa-key',
        'check-circle': 'fas fa-check-circle',
        'exclamation-circle': 'fas fa-exclamation-circle',
        'times-circle': 'fas fa-times-circle',
        'info-circle': 'fas fa-info-circle',
        'clock-circle': 'far fa-clock',
    };
    
    return faIconMap[iconName] || null;
}

/**
 * Render Ant Design icon
 */
function renderAntdIcon(iconName) {
    const antdIconMap = {
        'home': 'HomeOutlined',
        'user': 'UserOutlined',
        'users': 'UsergroupAddOutlined',
        'setting': 'SettingOutlined',
        'search': 'SearchOutlined',
        'bell': 'BellOutlined',
        'heart': 'HeartOutlined',
        'star': 'StarOutlined',
        'plus': 'PlusOutlined',
        'edit': 'EditOutlined',
        'delete': 'DeleteOutlined',
        'save': 'SaveOutlined',
        'download': 'DownloadOutlined',
        'upload': 'UploadOutlined',
        'check': 'CheckOutlined',
        'close': 'CloseOutlined',
        'database': 'DatabaseOutlined',
        'file': 'FileOutlined',
        'folder': 'FolderOutlined',
        'appstore': 'AppstoreOutlined',
        'arrow-left': 'ArrowLeftOutlined',
        'arrow-right': 'ArrowRightOutlined',
        'arrow-up': 'ArrowUpOutlined',
        'arrow-down': 'ArrowDownOutlined',
        'check-circle': 'CheckCircleOutlined',
        'exclamation-circle': 'ExclamationCircleOutlined',
        'close-circle': 'CloseCircleOutlined',
        'info-circle': 'InfoCircleOutlined',
    };
    
    const componentName = antdIconMap[iconName] || `${iconName.charAt(0).toUpperCase() + iconName.slice(1)}Outlined`;
    const IconComponent = AntdIcons[componentName];
    
    if (IconComponent) {
        return <IconComponent />;
    }
    
    // Fallback
    return <span>[Icon: {iconName}]</span>;
}

/**
 * Render Smily/Emoji
 */
function renderSmily(iconName) {
    const smilyMap = {
        'thanks': '🙏',
        'smile': '😊',
        'thumbs-up': '👍',
        'heart': '❤️',
        'star': '⭐',
        'fire': '🔥',
        'rocket': '🚀',
        'party': '🎉',
        'check': '✅',
        'warning': '⚠️',
    };
    
    const emoji = smilyMap[iconName] || iconName;
    
    return (
        <span role="img" aria-label={iconName}>
            {emoji}
        </span>
    );
}
