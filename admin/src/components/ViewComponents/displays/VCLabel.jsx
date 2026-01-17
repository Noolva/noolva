import React from "react";
import { Typography } from "antd";

export function VCLabel({ component }) {
  const input_values = component?.input_values || {};
  const strong = input_values.strong === true || input_values.strong === "true";
  return (
    <Typography.Text strong={strong}>
      {input_values.default_value}
    </Typography.Text>
  );
}

