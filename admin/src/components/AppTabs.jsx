import React from 'react';
import { Tabs } from 'antd';

const AppTabs = ({ tabs, onChange, onEdit }) => (
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
            children: tab.content,
        }))}
    />
);

export default AppTabs;