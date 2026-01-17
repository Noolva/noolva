import React from "react";
import { Statistic } from "antd";
import { coerceNumber } from "../vcTypes";

export function VCStatistic({ component }) {
  const input_values = component?.input_values || {};
  return (
    <Statistic
      title={input_values.title}
      value={coerceNumber(input_values.value, input_values.value)}
      precision={coerceNumber(input_values.precision)}
    />
  );
}

