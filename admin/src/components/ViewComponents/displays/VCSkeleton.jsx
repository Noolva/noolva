import React from "react";
import { Skeleton } from "antd";

export function VCSkeleton({ component }) {
  const input_values = component?.input_values || {};
  const active = input_values.active !== undefined ? input_values.active : true;
  const avatar = input_values.avatar || false;
  const paragraph = input_values.paragraph || { rows: 4 };
  const loading = input_values.loading !== undefined ? input_values.loading : true;
  const round = input_values.round || false;

  return (
    <Skeleton
      active={active}
      avatar={avatar}
      paragraph={paragraph}
      loading={loading}
      round={round}
      title={input_values.title !== undefined ? input_values.title : true}
    />
  );
}
