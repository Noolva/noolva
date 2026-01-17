import React from "react";
import { Divider } from "antd";

export function VCDivider({ component }) {
  const input_values = component?.input_values || {};
  const orientation = input_values.orientation || "horizontal";

  return <Divider orientation={orientation} />;
}
