import React from "react";
import { Tag } from "antd";

export function VCTag({ component }) {
  const input_values = component?.input_values || {};
  return <Tag color={input_values.color}>{input_values.text ?? input_values.label ?? input_values.default_value}</Tag>;
}

