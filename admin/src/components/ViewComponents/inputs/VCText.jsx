import React from "react";
import { Form, Input } from "antd";

const validationRules = {
  phone: [{ pattern: /^[0-9]{10}$/, message: "Invalid phone number" }],
  email: [{ type: "email", message: "Invalid email" }],
  number: [{ pattern: /^[0-9]+$/, message: "Only numbers allowed" }],
};

export function VCText({ component }) {
  const input_values = component?.input_values || {};

  return (
    <Form.Item
      name={input_values.name}
      label={input_values.label}
      rules={validationRules[input_values.validation_type] || []}
    >
      <Input
        placeholder={input_values.place_holder}
        defaultValue={input_values.default_value}
        allowClear
      />
    </Form.Item>
  );
}

