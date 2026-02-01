import React from "react";
import { ColorPicker, Form } from "antd";

// Normalize: "none"/null/undefined -> "none" when allowNone (store "none"); else undefined for ColorPicker display
function normalizeColorValue(value, allowNone) {
  if (allowNone && (value === "none" || value === null || value === undefined || value === "")) return "none";
  if (!value) return undefined;

  // If it's already a string (hex), return it
  if (typeof value === "string") {
    const cleaned = value.replace(/^["']+|["']+$/g, '');
    if (/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(cleaned)) {
      return cleaned;
    }
    return cleaned;
  }

  // If it's an object, convert to hex
  if (typeof value === "object" && value !== null) {
    // Handle metaColor object
    if (value.metaColor) {
      const meta = value.metaColor;
      if (meta.r !== undefined && meta.g !== undefined && meta.b !== undefined) {
        const r = Math.round(meta.r).toString(16).padStart(2, '0');
        const g = Math.round(meta.g).toString(16).padStart(2, '0');
        const b = Math.round(meta.b).toString(16).padStart(2, '0');
        return `#${r}${g}${b}`;
      }
    }

    // Handle direct color object
    if (value.r !== undefined && value.g !== undefined && value.b !== undefined) {
      const r = Math.round(value.r).toString(16).padStart(2, '0');
      const g = Math.round(value.g).toString(16).padStart(2, '0');
      const b = Math.round(value.b).toString(16).padStart(2, '0');
      return `#${r}${g}${b}`;
    }

    if (typeof value.toHexString === 'function') {
      return value.toHexString();
    }

    if (value.hex) {
      return value.hex;
    }
  }

  return value;
}

function ColorPickerWithNone({ value, onChange, allowNone, ...rest }) {
  const pickerValue = (value === "none" || value === null || value === undefined || value === "") ? undefined : value;
  const handleChange = (color) => {
    if (allowNone && (color === null || color === undefined)) {
      onChange("none");
    } else if (color && typeof color.toHexString === "function") {
      onChange(color.toHexString());
    } else {
      onChange(color);
    }
  };
  return <ColorPicker {...rest} value={pickerValue} onChange={handleChange} showText allowClear={allowNone} />;
}

export function VCColor({ component }) {
  const input_values = component?.input_values || {};
  const allowNone = input_values.allow_none ?? input_values.allow_clear ?? false;

  return (
    <Form.Item
      name={input_values.name}
      label={input_values.label}
      normalize={(value) => normalizeColorValue(value, allowNone)}
    >
      <ColorPickerWithNone allowNone={allowNone} />
    </Form.Item>
  );
}

