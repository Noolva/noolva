import React from "react";
import { Image } from "antd";
import { coerceNumber } from "../vcTypes";

export function VCImage({ component }) {
  const input_values = component?.input_values || {};
  const width = coerceNumber(input_values.width);
  return (
    <Image
      src={input_values.src}
      alt={input_values.alt}
      width={width}
      preview={false}
      style={{ borderRadius: 8 }}
    />
  );
}

