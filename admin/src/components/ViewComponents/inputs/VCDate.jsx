import React from "react";
import { DatePicker, Form } from "antd";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import timezone from "dayjs/plugin/timezone";

// Extend dayjs with plugins
dayjs.extend(utc);
dayjs.extend(timezone);

export function VCDate({ component }) {
  const input_values = component?.input_values || {};
  const format = input_values.format || "YYYY-MM-DD";
  const timezone_name = input_values.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone;

  // Get default value - assume it's UTC from database
  let defaultValue = null;
  if (input_values.default_value) {
    try {
      // If it's a string, parse it as UTC
      if (typeof input_values.default_value === 'string') {
        const utcString = input_values.default_value.endsWith('Z') 
          ? input_values.default_value 
          : input_values.default_value + 'Z';
        defaultValue = dayjs.utc(utcString).tz(timezone_name);
      } else if (input_values.default_value instanceof Date) {
        defaultValue = dayjs.utc(input_values.default_value.toISOString()).tz(timezone_name);
      } else {
        defaultValue = dayjs(input_values.default_value).tz(timezone_name);
      }
    } catch (e) {
      console.error('Error parsing date:', e);
      defaultValue = null;
    }
  }

  return (
    <Form.Item 
      name={input_values.name} 
      label={input_values.label}
      getValueFromEvent={(value) => {
        // Convert from local timezone to UTC for storage
        if (!value) return null;
        return dayjs(value).utc().format('YYYY-MM-DD');
      }}
      getValueProps={(value) => {
        // Convert from UTC to local timezone for display
        if (!value) return { value: null };
        try {
          const utcString = typeof value === 'string' && !value.endsWith('Z')
            ? value + 'Z'
            : value;
          const utcValue = dayjs.utc(utcString);
          return { value: utcValue.tz(timezone_name) };
        } catch (e) {
          console.error('Error converting UTC to local timezone:', e);
          return { value: null };
        }
      }}
    >
      <DatePicker
        style={{ width: "100%" }}
        format={format}
        defaultValue={defaultValue}
      />
    </Form.Item>
  );
}

