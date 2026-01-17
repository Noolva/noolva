import React from "react";
import { Tabs } from "antd";

export function VCTab({ component }) {
  const input_values = component?.input_values || {};
  const tabs = input_values.tabs || [];
  const tabPosition = input_values.tab_position || "top";
  const activeKey = input_values.active_key;
  const onChange = input_values.on_change;

  const tabItems = tabs.map((tab) => ({
    key: tab.key || tab.label,
    label: tab.label,
    children: tab.children || tab.content,
  }));

  return (
    <Tabs
      items={tabItems}
      tabPosition={tabPosition}
      activeKey={activeKey}
      onChange={onChange}
    />
  );
}
