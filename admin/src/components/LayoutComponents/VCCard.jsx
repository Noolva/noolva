import React from "react";
import { Card } from "antd";
import { coerceBoolean } from "../ViewComponents/vcTypes";

export function VCCard({ component, children }) {
  const input_values = component?.input_values || {};
  const title = input_values.title || undefined;
  const bordered = coerceBoolean(input_values.bordered, true);
  // Convert bordered to variant: true -> "outlined", false -> "borderless"
  const variant = bordered ? "outlined" : "borderless";

  return (
    <Card title={title} variant={variant}>
      {children}
    </Card>
  );
}
