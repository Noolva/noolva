import React from "react";
import { Typography } from "antd";

export function VCLink({ component }) {
  const input_values = component?.input_values || {};
  return (
    <Typography.Link href={input_values.href} target={input_values.target || "_blank"}>
      {input_values.text ?? input_values.label ?? input_values.href}
    </Typography.Link>
  );
}

