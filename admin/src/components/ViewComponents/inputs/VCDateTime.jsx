import React from "react";
import { DatePicker, Form } from "antd";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import timezone from "dayjs/plugin/timezone";

// Extend dayjs with plugins
dayjs.extend(utc);
dayjs.extend(timezone);

export function VCDateTime({ component }) {
  const input_values = component?.input_values || {};
  const format = input_values.format || "YYYY-MM-DD HH:mm:ss";
  const showTime = input_values.show_time !== false; // Default to true for datetime
  const timezone_name = input_values.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone;

  // Get default value - assume it's UTC from database
  let defaultValue = null;
  if (input_values.default_value) {
    try {
      // If it's a string, parse it as UTC
      if (typeof input_values.default_value === 'string') {
        // Parse as UTC and convert to local timezone for display
        // Handle both with and without 'Z' suffix
        const utcString = input_values.default_value.endsWith('Z') 
          ? input_values.default_value 
          : input_values.default_value + 'Z';
        defaultValue = dayjs.utc(utcString).tz(timezone_name);
      } else if (input_values.default_value instanceof Date) {
        // If it's a Date object, assume it's UTC and convert to local timezone
        defaultValue = dayjs.utc(input_values.default_value.toISOString()).tz(timezone_name);
      } else {
        defaultValue = dayjs(input_values.default_value).tz(timezone_name);
      }
    } catch (e) {
      console.error('Error parsing datetime:', e);
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
        // dayjs value is already in local timezone, convert to UTC
        return dayjs(value).utc().format('YYYY-MM-DDTHH:mm:ss[Z]');
      }}
      getValueProps={(value) => {
        // Convert from UTC to local timezone for display
        if (!value) return { value: null };
        try {
          // Ensure value is treated as UTC
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
        showTime={showTime ? {
          format: 'HH:mm:ss',
          defaultValue: dayjs('00:00:00', 'HH:mm:ss')
        } : false}
        defaultValue={defaultValue}
      />
    </Form.Item>
  );
}
