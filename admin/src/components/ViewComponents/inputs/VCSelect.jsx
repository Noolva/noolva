import React from "react";
import { Form, Select } from "antd";
import { normalizeOptions } from "../vcTypes";

export function VCSelect({ component }) {
  const input_values = component?.input_values || {};
  const mode = input_values.mode || undefined; // 'multiple' | 'tags' etc.
  const options = normalizeOptions(input_values.options);

  // Debug: Always log for select fields
  console.log(`VCSelect: ${input_values.name}`, {
    rawOptions: input_values.options,
    normalizedOptions: options,
    mode,
  });

  // Debug: Log if no options
  if (options.length === 0 && input_values.options) {
    console.warn(`VCSelect: No normalized options for ${input_values.name}. Raw options:`, input_values.options);
  }

  // Normalize form value - remove quotes if present
  const normalizeValue = (value) => {
    if (value == null) return value;
    if (typeof value === "string") {
      // Remove surrounding quotes
      let cleaned = value.replace(/^["']+|["']+$/g, '');
      // Try JSON parse if it looks like JSON
      try {
        const parsed = JSON.parse(value.trim());
        if (typeof parsed === "string") {
          cleaned = parsed.replace(/^["']+|["']+$/g, '');
        } else {
          cleaned = parsed;
        }
      } catch (e) {
        // Not JSON, use cleaned value
      }
      return cleaned;
    }
    return value;
  };

  return (
    <Form.Item 
      name={input_values.name} 
      label={input_values.label}
      normalize={normalizeValue}
    >
      <Select
        mode={mode}
        placeholder={input_values.place_holder}
        options={options}
        allowClear
        showSearch
        optionFilterProp="label"
        notFoundContent={options.length === 0 ? "No options available" : undefined}
      />
    </Form.Item>
  );
}

