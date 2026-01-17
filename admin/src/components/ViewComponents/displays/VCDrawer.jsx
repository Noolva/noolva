import React from "react";
import { Drawer } from "antd";
import { coerceBoolean } from "../vcTypes";

export function VCDrawer({ component, children }) {
  const input_values = component?.input_values || {};
  const title = input_values.title || "Drawer";
  const placement = input_values.placement || "right";
  const width = input_values.width || 520;
  const open = coerceBoolean(input_values.open, false);
  const closable = coerceBoolean(input_values.closable, true);
  const maskClosable = coerceBoolean(input_values.maskClosable, true);
  const onClose = input_values.onClose || (() => {});

  return (
    <Drawer
      title={title}
      placement={placement}
      width={width}
      open={open}
      closable={closable}
      maskClosable={maskClosable}
      onClose={onClose}
      destroyOnClose={coerceBoolean(input_values.destroyOnClose, false)}
    >
      {children}
    </Drawer>
  );
}
