import React from "react";
import { Form } from "antd";

export function VCForm({ component, children, onFinish, form }) {
  const input_values = component?.input_values || {};
  const layout = input_values.layout || "vertical";
  const size = input_values.size || undefined;
  const initialValues = input_values.initialValues || {};

  const formProps = {
    layout,
    size,
    onFinish,
    initialValues,
    ...(form && { form }),
  };

  return (
    <Form {...formProps}>
      {children}
    </Form>
  );
}
