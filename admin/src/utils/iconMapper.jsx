import React from 'react';

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
 * Renders a Font Awesome icon component
 */
export const renderIcon = (iconName) => {
    const iconClass = getIconClass(iconName);
    if (!iconClass) return null;
    return <i className={iconClass} />;
};
