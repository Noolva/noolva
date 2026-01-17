import React from "react";
import { Table as AntTable } from "antd";
import { coerceBoolean } from "../vcTypes";

function normalizeColumns(cols) {
  if (!Array.isArray(cols)) return null;
  return cols.map((c, idx) => ({
    title: c.title ?? c.label ?? c.name ?? `Column ${idx + 1}`,
    dataIndex: c.dataIndex ?? c.key ?? c.name ?? `col_${idx}`,
    key: c.key ?? c.dataIndex ?? c.name ?? `col_${idx}`,
    ...c,
  }));
}

export function VCTable({ component }) {
  const input_values = component?.input_values || {};
  const columns = normalizeColumns(input_values.columns);
  const pagination = coerceBoolean(input_values.pagination, false);

  // Placeholder dataset until you bind to real data source per view.
  const dataSource = input_values.dataSource || [];

  const fallbackColumns = [
    { title: "Name", dataIndex: "name", key: "name" },
    { title: "Age", dataIndex: "age", key: "age" },
    { title: "Address", dataIndex: "address", key: "address" },
  ];
  const fallbackData = [
    { key: "1", name: "John Brown", age: 32, address: "New York No. 1 Lake Park" },
    { key: "2", name: "Jim Green", age: 42, address: "London No. 1 Lake Park" },
  ];

  return (
    <AntTable
      columns={columns || fallbackColumns}
      dataSource={Array.isArray(dataSource) && dataSource.length ? dataSource : fallbackData}
      bordered
      pagination={pagination}
      size="middle"
      rowKey={(r) => r.key || r.id}
    />
  );
}

