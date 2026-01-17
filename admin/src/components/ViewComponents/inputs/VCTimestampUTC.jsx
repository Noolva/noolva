import React from "react";
import { DatePicker, Form } from "antd";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";

// Extend dayjs with UTC plugin only (no timezone conversion needed)
dayjs.extend(utc);

export function VCTimestampUTC({ component }) {
  const input_values = component?.input_values || {};
  const format = input_values.format || "YYYY-MM-DD HH:mm:ss";
  const showTime = input_values.show_time !== false; // Default to true for timestamp

  // Get default value - parse as UTC and keep as UTC (no timezone conversion)
  let defaultValue = null;
  if (input_values.default_value) {
    try {
      // If it's a string, parse it as UTC and keep it as UTC (no conversion)
      if (typeof input_values.default_value === 'string') {
        // Handle both with and without 'Z' suffix - treat as UTC
        const utcString = input_values.default_value.endsWith('Z')
          ? input_values.default_value
          : input_values.default_value + 'Z';
        // Use utc(true) to keep same time without conversion (treat as already UTC)
        defaultValue = dayjs(utcString).utc(true);
      } else if (input_values.default_value instanceof Date) {
        // If it's a Date object, assume it's UTC and parse as UTC without conversion
        defaultValue = dayjs(input_values.default_value.toISOString()).utc(true);
      } else {
        defaultValue = dayjs(input_values.default_value).utc(true);
      }
    } catch (e) {
      console.error(`[VCTimestampUTC] Error parsing timestamp for ${input_values.name}:`, e);
      defaultValue = null;
    }
  }

  return (
    <Form.Item
      name={input_values.name}
      label={input_values.label}
      getValueFromEvent={(value) => {
        // Store as UTC string directly (no conversion)
        if (!value) return null;
        // Use utc(true) to keep same hours/minutes but mark as UTC (no shift)
        const utcValue = dayjs(value).utc(true);
        return utcValue.format('YYYY-MM-DDTHH:mm:ss[Z]');
      }}
      getValueProps={(value) => {
        // Display UTC value directly (no timezone conversion)
        if (!value) return { value: null };
        try {
          // Parse as UTC and use utc(true) to keep same time without shift
          const utcString = typeof value === 'string' && !value.endsWith('Z')
            ? value + 'Z'
            : value;
          // Use utc(true) to treat as already UTC without converting
          const utcValue = dayjs(utcString).utc(true);
          return { value: utcValue };
        } catch (e) {
          console.error(`[VCTimestampUTC] Error parsing UTC timestamp for ${input_values.name}:`, e);
          return { value: null };
        }
      }}
    >
      <DatePicker
        style={{ width: "100%" }}
        format={format}
        showTime={showTime ? {
          format: 'HH:mm:ss'
        } : false}
        defaultValue={defaultValue}
      />
    </Form.Item>
  );
}
