import React, { useEffect, useState } from "react";
import { Form, Select } from "antd";
import { normalizeOptions } from "../vcTypes";
import { api } from "../../../utils/api";

export function VCSelect({ component }) {
  const input_values = component?.input_values || {};
  const mode = input_values.mode || undefined; // 'multiple' | 'tags' etc.
  const [options, setOptions] = useState([]);
  const [loading, setLoading] = useState(false);

  // Get options_mode from field_config_json or default_props_json
  const fieldConfig = input_values.field_config_json || {};
  const defaultProps = input_values.default_props_json || {};
  const optionsMode = fieldConfig.options_mode || defaultProps.options_mode;
  const collectionId = fieldConfig.collection_id || defaultProps.collection_id;
  const tableColumn = fieldConfig.table_column || defaultProps.table_column;
  const displayColumns = fieldConfig.display_columns || defaultProps.display_columns;
  const customOptions = fieldConfig.options || defaultProps.options;

  // Fetch options based on options_mode
  useEffect(() => {
    const fetchOptions = async () => {
      // If options_mode is not set, use legacy behavior (options from input_values)
      if (!optionsMode) {
        const legacyOptions = normalizeOptions(input_values.options);
        setOptions(legacyOptions);
        return;
      }

      // If custom_collection, use options from config
      if (optionsMode === "custom_collection") {
        const normalized = normalizeOptions(customOptions || []);
        setOptions(normalized);
        return;
      }

      // For collections or foreign_key, fetch from API
      if (optionsMode === "collections" || optionsMode === "foreign_key") {
        setLoading(true);
        try {
          const payload = {
            options_mode: optionsMode,
          };

          if (optionsMode === "collections") {
            if (!collectionId) {
              console.warn(`VCSelect: collection_id is required for collections mode`);
              setOptions([]);
              setLoading(false);
              return;
            }
            payload.collection_id = collectionId;
          } else if (optionsMode === "foreign_key") {
            if (!tableColumn) {
              console.warn(`VCSelect: table_column is required for foreign_key mode`);
              setOptions([]);
              setLoading(false);
              return;
            }
            payload.table_column = tableColumn;
            if (displayColumns) {
              payload.display_columns = displayColumns;
            }
          }

          const response = await api.post("/field-options/fetch", payload);
          if (response.data && response.data.options) {
            setOptions(response.data.options);
          } else {
            setOptions([]);
          }
        } catch (error) {
          console.error(`VCSelect: Failed to fetch options for ${input_values.name}:`, error);
          setOptions([]);
        } finally {
          setLoading(false);
        }
      }
    };

    fetchOptions();
  }, [optionsMode, collectionId, tableColumn, displayColumns, customOptions, input_values.options, input_values.name]);

  // Debug: Always log for select fields
  console.log(`VCSelect: ${input_values.name}`, {
    optionsMode,
    rawOptions: input_values.options,
    normalizedOptions: options,
    mode,
    loading,
  });

  // Normalize form value - remove quotes if present
  const normalizeValue = (value) => {
    if (value == null) return value;
    if (typeof value === "string") {
      // Remove surrounding quotes
      let cleaned = value.replace(/^["']+|["']+$/g, '');
      // Try JSON parse if it looks like JSON
      try {
        const parsed = JSON.parse(value.trim());
        if (typeof parsed === "string") {
          cleaned = parsed.replace(/^["']+|["']+$/g, '');
        } else {
          cleaned = parsed;
        }
      } catch (e) {
        // Not JSON, use cleaned value
      }
      return cleaned;
    }
    return value;
  };

  return (
    <Form.Item
      name={input_values.name}
      label={input_values.label}
      normalize={normalizeValue}
    >
      <Select
        mode={mode}
        placeholder={input_values.place_holder}
        options={options}
        allowClear
        showSearch
        optionFilterProp="label"
        loading={loading}
        onChange={input_values.onChange}
        notFoundContent={loading ? "Loading..." : (options.length === 0 ? "No options available" : undefined)}
      />
    </Form.Item>
  );
}

