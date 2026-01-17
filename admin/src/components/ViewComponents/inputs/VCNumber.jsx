import React from "react";
import { Form, InputNumber } from "antd";
import { coerceNumber } from "../vcTypes";

export function VCNumber({ component }) {
  const input_values = component?.input_values || {};
  const min = coerceNumber(input_values.min);
  const max = coerceNumber(input_values.max);

  return (
    <Form.Item name={input_values.name} label={input_values.label}>
      <InputNumber
        style={{ width: "100%" }}
        min={min}
        max={max}
        defaultValue={coerceNumber(input_values.default_value)}
      />
    </Form.Item>
  );
}

