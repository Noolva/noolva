import React from "react";
import { Checkbox, Form } from "antd";
import { coerceBoolean } from "../vcTypes";

export function VCCheckbox({ component }) {
  const input_values = component?.input_values || {};

  return (
    <Form.Item
      name={input_values.name}
      valuePropName="checked"
      initialValue={coerceBoolean(input_values.default_value, false)}
    >
      <Checkbox>{input_values.label}</Checkbox>
    </Form.Item>
  );
}

