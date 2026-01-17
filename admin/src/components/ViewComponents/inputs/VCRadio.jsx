import React from "react";
import { Form, Radio } from "antd";
import { normalizeOptions } from "../vcTypes";

export function VCRadio({ component }) {
  const input_values = component?.input_values || {};
  const options = normalizeOptions(input_values.options);

  return (
    <Form.Item name={input_values.name} label={input_values.label}>
      <Radio.Group
        options={options.map((o) => ({ label: o.label, value: o.value }))}
      />
    </Form.Item>
  );
}

