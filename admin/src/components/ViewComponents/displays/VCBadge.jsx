import React from "react";
import { Badge } from "antd";
import { coerceNumber } from "../vcTypes";

export function VCBadge({ component }) {
  const input_values = component?.input_values || {};
  const count = coerceNumber(input_values.count, input_values.count);
  return (
    <Badge count={count} color={input_values.color}>
      <span />
    </Badge>
  );
}

