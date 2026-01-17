import React from "react";
import { Progress } from "antd";
import { coerceNumber } from "../vcTypes";

export function VCProgress({ component }) {
  const input_values = component?.input_values || {};
  return (
    <Progress
      percent={coerceNumber(input_values.percent, 0)}
      status={input_values.status}
    />
  );
}

