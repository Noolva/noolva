import React from "react";
import { Button, Col, Input, InputNumber, Row, Select, Space } from "antd";

const { Option } = Select;

export function VCSearchFilterBar({
  searchPlaceholder = "Search…",
  searchValue,
  onSearchValueChange,
  filters,
  onFiltersChange,
  filterOptions,
  onReset,
}) {
  const opts = filterOptions || {};
  const f = filters || {};

  const setFilter = (key, value) => {
    onFiltersChange?.({ ...f, [key]: value });
  };

  return (
    <Row gutter={[12, 12]} align="middle" style={{ marginBottom: 12 }}>
      <Col xs={24} sm={24} md={10} lg={8} xl={8}>
        <Input
          allowClear
          placeholder={searchPlaceholder}
          value={searchValue}
          onChange={(e) => onSearchValueChange?.(e.target.value)}
        />
      </Col>

      <Col xs={24} sm={12} md={7} lg={4} xl={4}>
        <Select
          allowClear
          placeholder="Category"
          style={{ width: "100%" }}
          value={f.category || undefined}
          onChange={(v) => setFilter("category", v)}
        >
          {(opts.categories || []).map((c) => (
            <Option key={c.value ?? c} value={c.value ?? c}>
              {c.label ?? c}
            </Option>
          ))}
        </Select>
      </Col>

      <Col xs={24} sm={12} md={7} lg={4} xl={4}>
        <Select
          allowClear
          placeholder="Handler type"
          style={{ width: "100%" }}
          value={f.handlerType || undefined}
          onChange={(v) => setFilter("handlerType", v)}
        >
          {(opts.handlerTypes || []).map((t) => (
            <Option key={t} value={t}>
              {t}
            </Option>
          ))}
        </Select>
      </Col>

      <Col xs={24} sm={12} md={7} lg={4} xl={4}>
        <Select
          allowClear
          placeholder="Status"
          style={{ width: "100%" }}
          value={f.status || undefined}
          onChange={(v) => setFilter("status", v)}
        >
          <Option value="active">Active</Option>
          <Option value="inactive">Inactive</Option>
        </Select>
      </Col>

      <Col xs={24} sm={12} md={7} lg={4} xl={4}>
        <Select
          allowClear
          placeholder="Mode"
          style={{ width: "100%" }}
          value={f.mode || undefined}
          onChange={(v) => setFilter("mode", v)}
        >
          {(opts.modes || []).map((m) => (
            <Option key={m} value={m}>
              {m}
            </Option>
          ))}
        </Select>
      </Col>

      <Col xs={24} sm={12} md={8} lg={5} xl={5}>
        <Space.Compact style={{ width: "100%" }}>
          <InputNumber
            min={0}
            placeholder="Timeout min"
            style={{ width: "50%" }}
            value={typeof f.timeoutMin === "number" ? f.timeoutMin : undefined}
            onChange={(v) => setFilter("timeoutMin", typeof v === "number" ? v : null)}
          />
          <InputNumber
            min={0}
            placeholder="max"
            style={{ width: "50%" }}
            value={typeof f.timeoutMax === "number" ? f.timeoutMax : undefined}
            onChange={(v) => setFilter("timeoutMax", typeof v === "number" ? v : null)}
          />
        </Space.Compact>
      </Col>

      <Col xs={24} sm={12} md={8} lg={3} xl={3}>
        <Button style={{ width: "100%" }} onClick={onReset}>
          Reset
        </Button>
      </Col>
    </Row>
  );
}

