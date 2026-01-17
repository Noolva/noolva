import React from "react";
import { Row } from "antd";
import { coerceNumber } from "../ViewComponents/vcTypes";

export function VCRow({ component, children }) {
  const input_values = component?.input_values || {};
  const gutter = coerceNumber(input_values.gutter, 24);
  const justify = input_values.justify || undefined;
  const align = input_values.align || undefined;

  return (
    <Row gutter={gutter} justify={justify} align={align}>
      {children}
    </Row>
  );
}
