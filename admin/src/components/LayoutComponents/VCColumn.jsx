import React from "react";
import { Col } from "antd";
import { coerceNumber } from "../ViewComponents/vcTypes";

export function VCColumn({ component, children }) {
  const input_values = component?.input_values || {};
  const span = coerceNumber(input_values.span, 24);
  const offset = coerceNumber(input_values.offset, undefined);

  return (
    <Col span={span} offset={offset}>
      {children}
    </Col>
  );
}
