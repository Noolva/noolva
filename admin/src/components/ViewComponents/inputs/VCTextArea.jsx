import React from "react";
import { Form, Input } from "antd";
import { coerceNumber } from "../vcTypes";

export function VCTextArea({ component }) {
  const input_values = component?.input_values || {};
  const rows = coerceNumber(input_values.rows, 4);

  return (
    <Form.Item name={input_values.name} label={input_values.label}>
      <Input.TextArea
        rows={rows}
        placeholder={input_values.place_holder}
        defaultValue={input_values.default_value}
        allowClear
      />
    </Form.Item>
  );
}

