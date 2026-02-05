import React from "react";
import { Form, InputNumber } from "antd";
import { coerceNumber } from "../vcTypes";

/**
 * Duration input (e.g. idle timeout in minutes).
 * value: number of minutes. -1 = no limit / disabled.
 * field_config_json: { min, max, step, unit } (unit e.g. "minutes" for display).
 */
export function VCDuration({ component }) {
  const input_values = component?.input_values || {};
  const cfg = component?._raw?.field_config_json || {};
  const config = typeof cfg === "string" ? {} : cfg;
  const min = coerceNumber(input_values.min ?? config.min, -1);
  const max = coerceNumber(input_values.max ?? config.max, 1440);
  const step = coerceNumber(input_values.step ?? config.step, 1);
  const unit = input_values.unit ?? config.unit ?? "minutes";

  return (
    <Form.Item
      name={input_values.name}
      label={input_values.label}
      extra={input_values.place_holder || (unit ? `Value in ${unit}. Use -1 for no limit.` : undefined)}
    >
      <InputNumber
        style={{ width: "100%" }}
        min={min}
        max={max}
        step={step}
        defaultValue={coerceNumber(input_values.default_value)}
        placeholder={min === -1 ? "-1 = no lock" : undefined}
        addonAfter={unit || null}
      />
    </Form.Item>
  );
}
