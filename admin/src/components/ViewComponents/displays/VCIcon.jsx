import React from 'react';
import * as AntdIcons from '@ant-design/icons';

/**
 * VCIcon - View Component for rendering icons
 * Supports FontAwesome, Ant Design icons, Smilies, and Custom SVG icons
 * 
 * Expected format in component.input_values:
 * - icon_code: "fa:heart", "antd:download", "smily:thanks", "custom:myhome"
 * - OR icon_id: integer reference to icons table
 * - size: optional size (number or string)
 * - color: optional color (string)
 * - style: optional style object
 */
export function VCIcon({ component }) {
  const input_values = component?.input_values || {};
  const iconCode = input_values.icon_code || input_values.default_value || '';
  const size = input_values.size || 16;
  const color = input_values.color;
  const style = input_values.style || {};

  if (!iconCode) {
    return null;
  }

  // Parse icon code format: "prefix:name"
  const [prefix, name] = iconCode.split(':');

  // Apply size and color to style
  const iconStyle = {
    fontSize: typeof size === 'number' ? `${size}px` : size,
    color: color,
    ...style
  };

  // Render based on icon type
  switch (prefix) {
    case 'fa':
      // FontAwesome icon
      return renderFontAwesome(name, iconStyle);
    
    case 'antd':
      // Ant Design icon
      return renderAntdIcon(name, iconStyle);
    
    case 'smily':
      // Emoji/Smiley
      return renderSmily(name, iconStyle);
    
    case 'custom':
      // Custom SVG icon
      return renderCustomIcon(name, iconStyle);
    
    default:
      // Fallback: try to render as FontAwesome if no prefix
      return renderFontAwesome(iconCode, iconStyle);
  }
}

/**
 * Render FontAwesome icon
 */
function renderFontAwesome(iconName, style) {
  // Map common icon names to FA classes
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
    'folder': 'fas fa-folder',
    'building': 'fas fa-building',
    'briefcase': 'fas fa-briefcase',
    'arrow-left': 'fas fa-arrow-left',
    'arrow-right': 'fas fa-arrow-right',
    'arrow-up': 'fas fa-arrow-up',
    'arrow-down': 'fas fa-arrow-down',
    'facebook': 'fab fa-facebook',
    'twitter': 'fab fa-twitter',
    'linkedin': 'fab fa-linkedin',
    'instagram': 'fab fa-instagram',
    'lock': 'fas fa-lock',
    'unlock': 'fas fa-unlock',
    'shield': 'fas fa-shield-alt',
    'key': 'fas fa-key',
    'check-circle': 'fas fa-check-circle',
    'exclamation-circle': 'fas fa-exclamation-circle',
    'times-circle': 'fas fa-times-circle',
    'info-circle': 'fas fa-info-circle',
  };

  // Get FA class or use iconName directly if it already contains 'fa-'
  let faClass = faIconMap[iconName] || iconName;
  
  // If iconName already contains 'fa-', use it directly
  if (iconName.includes('fa-')) {
    faClass = iconName.startsWith('fa') ? `fas ${iconName}` : iconName;
  }

  return <i className={faClass} style={style} />;
}

/**
 * Render Ant Design icon
 */
function renderAntdIcon(iconName, style) {
  // Map icon names to Ant Design icon components
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

  // Get component name
  const componentName = antdIconMap[iconName] || `${iconName.charAt(0).toUpperCase() + iconName.slice(1)}Outlined`;
  
  // Get the icon component from @ant-design/icons
  const IconComponent = AntdIcons[componentName];

  if (!IconComponent) {
    // Fallback: try to find the icon with different naming
    const fallbackName = iconName
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join('') + 'Outlined';
    const FallbackIcon = AntdIcons[fallbackName];
    
    if (FallbackIcon) {
      return <FallbackIcon style={style} />;
    }
    
    // If still not found, return a placeholder
    return <span style={style}>[Icon: {iconName}]</span>;
  }

  return <IconComponent style={style} />;
}

/**
 * Render Smily/Emoji
 */
function renderSmily(iconName, style) {
  // Map icon names to emojis
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
    <span style={style} role="img" aria-label={iconName}>
      {emoji}
    </span>
  );
}

/**
 * Render Custom SVG icon
 */
function renderCustomIcon(iconName, style) {
  // For custom icons, you would typically fetch the SVG from the database
  // For now, we'll return a placeholder
  // In production, you'd fetch icon_data from the icons table via API
  
  // This is a placeholder - in production, fetch from API
  const customIconMap = {
    'myhome': (
      <svg viewBox="0 0 24 24" style={style} fill="currentColor">
        <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" />
      </svg>
    ),
    'logo': (
      <svg viewBox="0 0 24 24" style={style} fill="currentColor">
        <circle cx="12" cy="12" r="10" />
      </svg>
    ),
  };

  const customIcon = customIconMap[iconName];
  
  if (customIcon) {
    return customIcon;
  }

  // Fallback placeholder
  return <span style={style}>[Custom: {iconName}]</span>;
}
