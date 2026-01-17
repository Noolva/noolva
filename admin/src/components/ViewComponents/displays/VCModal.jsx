import React from "react";
import { Modal } from "antd";
import { coerceBoolean } from "../vcTypes";

export function VCModal({ component, children }) {
  const input_values = component?.input_values || {};
  const title = input_values.title || "Modal";
  const width = input_values.width || 520;
  const open = coerceBoolean(input_values.open, false);
  const closable = coerceBoolean(input_values.closable, true);
  const maskClosable = coerceBoolean(input_values.maskClosable, true);
  const footer = input_values.footer !== undefined ? input_values.footer : null;
  const onOk = input_values.onOk || (() => {});
  const onCancel = input_values.onCancel || (() => {});
  const okText = input_values.okText || "OK";
  const cancelText = input_values.cancelText || "Cancel";

  return (
    <Modal
      title={title}
      width={width}
      open={open}
      closable={closable}
      maskClosable={maskClosable}
      footer={footer}
      onOk={onOk}
      onCancel={onCancel}
      okText={okText}
      cancelText={cancelText}
      destroyOnClose={coerceBoolean(input_values.destroyOnClose, false)}
    >
      {children}
    </Modal>
  );
}
