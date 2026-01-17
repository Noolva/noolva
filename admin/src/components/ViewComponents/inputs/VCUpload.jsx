import React from "react";
import { Form, Upload, Button } from "antd";
import { UploadOutlined } from "@ant-design/icons";
import { coerceBoolean } from "../vcTypes";

export function VCUpload({ component }) {
  const input_values = component?.input_values || {};
  const multiple = coerceBoolean(input_values.multiple, false);
  const accept = input_values.accept || undefined;

  // NOTE: This is UI-only until you wire antd Upload `action` or `customRequest`.
  return (
    <Form.Item name={input_values.name} label={input_values.label} valuePropName="fileList" getValueFromEvent={(e) => e?.fileList}>
      <Upload multiple={multiple} accept={accept} beforeUpload={() => false}>
        <Button icon={<UploadOutlined />}>Select file</Button>
      </Upload>
    </Form.Item>
  );
}

