import React from "react";
import { Form, Switch } from "antd";
import { coerceBoolean } from "../vcTypes";

export function VCSwitch({ component }) {
  const input_values = component?.input_values || {};
  const checkedChildren = input_values.checked_children ?? "";
  const unCheckedChildren = input_values.un_checked_children ?? "";

  return (
    <Form.Item
      name={input_values.name}
      label={input_values.label}
      valuePropName="checked"
      initialValue={coerceBoolean(input_values.default_value, false)}
    >
      <Switch checkedChildren={checkedChildren} unCheckedChildren={unCheckedChildren} />
    </Form.Item>
  );
}

