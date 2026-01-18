import React, { useEffect, useMemo, useState } from "react";
import { Button, Card, Col, Form, Row, Typography, message } from "antd";
import { viewComponentRegistry } from "../components/ViewComponents";
import { getComponentKey, coerceNumber, coerceBoolean, normalizeOptions } from "../components/ViewComponents/vcTypes";
import { api } from "../utils/api";

// Convert color value to hex string format
function convertColorToHex(colorValue) {
  if (!colorValue) return colorValue;
  
  // If it's already a string (hex), return it
  if (typeof colorValue === "string") {
    // Remove quotes if present
    const cleaned = colorValue.replace(/^["']+|["']+$/g, '');
    // Check if it's a valid hex color
    if (/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(cleaned)) {
      return cleaned;
    }
    return cleaned;
  }
  
  // If it's an object with color properties, convert to hex
  if (typeof colorValue === "object" && colorValue !== null) {
    // Handle metaColor object
    if (colorValue.metaColor) {
      const meta = colorValue.metaColor;
      if (meta.r !== undefined && meta.g !== undefined && meta.b !== undefined) {
        const r = Math.round(meta.r).toString(16).padStart(2, '0');
        const g = Math.round(meta.g).toString(16).padStart(2, '0');
        const b = Math.round(meta.b).toString(16).padStart(2, '0');
        return `#${r}${g}${b}`;
      }
    }
    
    // Handle direct color object with r, g, b properties
    if (colorValue.r !== undefined && colorValue.g !== undefined && colorValue.b !== undefined) {
      const r = Math.round(colorValue.r).toString(16).padStart(2, '0');
      const g = Math.round(colorValue.g).toString(16).padStart(2, '0');
      const b = Math.round(colorValue.b).toString(16).padStart(2, '0');
      return `#${r}${g}${b}`;
    }
    
    // If object has a toHexString method, use it
    if (typeof colorValue.toHexString === 'function') {
      return colorValue.toHexString();
    }
    
    // If object has a hex property
    if (colorValue.hex) {
      return colorValue.hex;
    }
  }
  
  return colorValue;
}

// Parse a value that might be JSON-stringified (handles double-encoded JSON strings)
function parseValue(value, fieldType) {
  if (value == null || value === "") return value;
  
  // If it's a string, try to parse it as JSON (handles cases like "\"Noolva SaaS\"")
  if (typeof value === "string") {
    let trimmed = value.trim();
    
    // Skip if empty after trim
    if (!trimmed) return value;
    
    // Try JSON.parse first (handles double-encoded strings)
    try {
      const parsed = JSON.parse(trimmed);
      // If still a string, try parsing again (double encoding)
      if (typeof parsed === "string" && parsed.trim()) {
        try {
          const doubleParsed = JSON.parse(parsed.trim());
          return doubleParsed;
        } catch (e) {
          return parsed;
        }
      }
      return parsed;
    } catch (e) {
      // JSON.parse failed, clean manually
    }
    
    // Manual cleaning: Remove surrounding quotes (single or double)
    let cleaned = trimmed.replace(/^["']+|["']+$/g, '');
    
    // Replace escaped quotes
    cleaned = cleaned.replace(/\\"/g, '"').replace(/\\'/g, "'");
    
    // Remove any remaining surrounding quotes after unescaping
    cleaned = cleaned.replace(/^["']+|["']+$/g, '');
    
    // If cleaned is different, return it
    if (cleaned !== trimmed) {
      return cleaned;
    }
  }
  
  return value;
}

function mapSettingToVC(setting) {
  const fieldType = setting.field_type_code || "text";
  let cfg = setting.field_config_json || {};
  
  // If field_config_json is a string, try to parse it as JSON
  if (typeof cfg === "string") {
    try {
      cfg = JSON.parse(cfg);
    } catch (e) {
      console.warn(`Failed to parse field_config_json for ${setting.setting_key}:`, cfg);
      cfg = {};
    }
  }

  // Map field_types.type_code -> VC type (ui_component_types)
  // Keep this mapping minimal and swappable.
  let vcType = "text";
  const input_values = {
    name: setting.setting_key,
    label: setting.setting_name,
    place_holder: setting.description || "",
  };

  if (fieldType === "text" || fieldType === "email" || fieldType === "phone" || fieldType === "url" || fieldType === "password") {
    vcType = "text";
  } else if (fieldType === "paragraph" || fieldType === "rich_text" || fieldType === "json") {
    vcType = "textarea";
    if (cfg?.rows) input_values.rows = cfg.rows;
  } else if (fieldType === "number" || fieldType === "currency" || fieldType === "percentage" || fieldType === "rating") {
    vcType = "number";
    if (cfg?.min != null) input_values.min = cfg.min;
    if (cfg?.max != null) input_values.max = cfg.max;
  } else if (fieldType === "boolean") {
    vcType = "switch";
  } else if (fieldType === "color") {
    vcType = "color";
  } else if (fieldType === "single_choice") {
    vcType = "select";
    // Pass field_config_json and default_props_json to component for options_mode handling
    input_values.field_config_json = cfg;
    // Get default_props_json from field_types if available
    if (setting.default_props_json) {
      let defaultProps = setting.default_props_json;
      if (typeof defaultProps === "string") {
        try {
          defaultProps = JSON.parse(defaultProps);
        } catch (e) {
          defaultProps = {};
        }
      }
      input_values.default_props_json = defaultProps;
    }
    
    // Legacy support: if options_mode is not set, use old behavior
    if (!cfg?.options_mode && !setting.default_props_json?.options_mode) {
      let rawOptions = cfg?.options;
      
      // Handle different formats of options
      if (rawOptions && typeof rawOptions === "string") {
        try {
          rawOptions = JSON.parse(rawOptions);
        } catch (e) {
          rawOptions = rawOptions.split(",").map(s => s.trim()).filter(Boolean);
        }
      }
      
      if (!Array.isArray(rawOptions)) {
        rawOptions = [];
      }
      
      input_values.options = normalizeOptions(rawOptions);
    }
  } else if (fieldType === "multi_choice") {
    vcType = "select";
    input_values.mode = "multiple";
    // Pass field_config_json and default_props_json to component for options_mode handling
    input_values.field_config_json = cfg;
    // Get default_props_json from field_types if available
    if (setting.default_props_json) {
      let defaultProps = setting.default_props_json;
      if (typeof defaultProps === "string") {
        try {
          defaultProps = JSON.parse(defaultProps);
        } catch (e) {
          defaultProps = {};
        }
      }
      input_values.default_props_json = defaultProps;
    }
    
    // Legacy support: if options_mode is not set, use old behavior
    if (!cfg?.options_mode && !setting.default_props_json?.options_mode) {
      let rawOptions = cfg?.options;
      
      // Handle different formats of options
      if (rawOptions && typeof rawOptions === "string") {
        try {
          rawOptions = JSON.parse(rawOptions);
        } catch (e) {
          rawOptions = rawOptions.split(",").map(s => s.trim()).filter(Boolean);
        }
      }
      
      if (!Array.isArray(rawOptions)) {
        rawOptions = [];
      }
      
      input_values.options = normalizeOptions(rawOptions);
    }
  } else if (fieldType === "date" || fieldType === "datetime" || fieldType === "time") {
    vcType = "date";
  } else if (fieldType === "image" || fieldType === "file" || fieldType === "video" || fieldType === "audio") {
    vcType = "upload";
    if (cfg?.multiple != null) input_values.multiple = cfg.multiple;
    if (cfg?.accept) input_values.accept = cfg.accept;
  }

  return {
    uuid: setting.setting_key,
    id: setting.setting_id,
    type: vcType,
    input_values,
    _raw: setting,
  };
}

export default function Settings() {
  const [saving, setSaving] = useState({});
  const [msgApi, ctxHolder] = message.useMessage();
  const [settingsRows, setSettingsRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeGroup, setActiveGroup] = useState(null);
  const [defaultValues, setDefaultValues] = useState({});
  const [initialValues, setInitialValues] = useState({});
  const [form] = Form.useForm();

  useEffect(() => {
    let mounted = true;
    const load = async () => {
      setLoading(true);
      try {
        const res = await api.getSettingsDefinitions({ scope: "global" });
        const rows = res?.settings || [];
        if (!mounted) return;
        setSettingsRows(rows);
        setActiveGroup(rows?.[0]?.group_name || null);

        // Build initial form values from value (fallback already applied by API)
        // Parse JSON strings and coerce types appropriately
        const formValues = {};
        const defaults = {};
        for (const r of rows) {
          const fieldType = r.field_type_code || "text";
          let parsedValue = parseValue(r.value, fieldType);
          
          // For select fields, ensure value matches option format
          if (fieldType === "single_choice" || fieldType === "multi_choice") {
            let cfg = r.field_config_json || {};
            
            // If field_config_json is a string, try to parse it as JSON
            if (typeof cfg === "string") {
              try {
                cfg = JSON.parse(cfg);
              } catch (e) {
                cfg = {};
              }
            }
            
            // Handle options in different formats
            let rawOptions = cfg?.options;
            if (rawOptions && typeof rawOptions === "string") {
              try {
                rawOptions = JSON.parse(rawOptions);
              } catch (e) {
                rawOptions = rawOptions.split(",").map(s => s.trim()).filter(Boolean);
              }
            }
            
            if (!Array.isArray(rawOptions)) {
              rawOptions = [];
            }
            
            const normalizedOptions = normalizeOptions(rawOptions);
            
            // Aggressively clean the value - remove all quotes and escaped quotes
            if (parsedValue != null) {
              let cleanedValue = parsedValue;
              
              // If it's a string, clean it more aggressively - always remove quotes
              if (typeof cleanedValue === "string") {
                // First try JSON.parse to handle double-encoded strings
                try {
                  const jsonParsed = JSON.parse(cleanedValue.trim());
                  if (typeof jsonParsed === "string") {
                    // If it's still a string after parsing, it was double-encoded
                    cleanedValue = jsonParsed;
                  } else {
                    cleanedValue = jsonParsed;
                  }
                } catch (e) {
                  // JSON.parse failed, continue with manual cleaning
                }
                
                // Always remove surrounding quotes (single or double) from string
                if (typeof cleanedValue === "string") {
                  // Remove all surrounding quotes (single or double)
                  cleanedValue = cleanedValue.replace(/^["']+|["']+$/g, '');
                  // Replace escaped quotes
                  cleanedValue = cleanedValue.replace(/\\"/g, '"').replace(/\\'/g, "'");
                  // Remove quotes again in case they were nested
                  cleanedValue = cleanedValue.replace(/^["']+|["']+$/g, '');
                }
              }
              
              // Now try to match with options
              if (normalizedOptions.length > 0) {
                const matched = normalizedOptions.find(opt => {
                  const optValue = String(opt.value || '');
                  const optLabel = String(opt.label || '');
                  const cleanedStr = String(cleanedValue || '');
                  return (
                    optValue === cleanedStr ||
                    optLabel === cleanedStr ||
                    optValue === cleanedValue ||
                    optLabel === cleanedValue ||
                    optValue.toLowerCase() === cleanedStr.toLowerCase() ||
                    optLabel.toLowerCase() === cleanedStr.toLowerCase()
                  );
                });
                
                if (matched) {
                  parsedValue = matched.value;
                } else {
                  // If no match found, log for debugging but use the cleaned value (without quotes)
                  console.warn(`No option match found for setting ${r.setting_key}. Original: ${r.value}, Parsed: ${parsedValue}, Cleaned: ${cleanedValue}, Options:`, normalizedOptions);
                  parsedValue = cleanedValue;
                }
              } else {
                // No options available, but still clean the value (remove quotes)
                if (typeof cleanedValue === "string") {
                  parsedValue = cleanedValue.replace(/^["']+|["']+$/g, '');
                } else {
                  parsedValue = cleanedValue;
                }
              }
            }
          }
          
          // Coerce to appropriate type
          if (fieldType === "number" || fieldType === "currency" || fieldType === "percentage" || fieldType === "rating") {
            parsedValue = coerceNumber(parsedValue, parsedValue);
          } else if (fieldType === "boolean") {
            parsedValue = coerceBoolean(parsedValue, false);
          } else if (fieldType === "color") {
            // Convert color object to hex string if needed
            parsedValue = convertColorToHex(parsedValue);
          }
          
          formValues[r.setting_key] = parsedValue;
          defaults[r.setting_key] = parseValue(r.default_value, fieldType);
        }
        setInitialValues(formValues);
        setDefaultValues(defaults);
        form.setFieldsValue(formValues);
      } catch (e) {
        msgApi.error(e?.message || "Failed to load settings");
      } finally {
        if (mounted) setLoading(false);
      }
    };
    load();
    return () => {
      mounted = false;
    };
  }, [form, msgApi]);

  const groups = useMemo(() => {
    const map = new Map();
    for (const r of settingsRows) {
      if (!map.has(r.group_name)) map.set(r.group_name, []);
      map.get(r.group_name).push(r);
    }
    return Array.from(map.entries()).map(([groupName, rows]) => ({
      groupName,
      rows,
    }));
  }, [settingsRows]);

  const saveGroup = async (groupName) => {
    setSaving((prev) => ({ ...prev, [groupName]: true }));
    try {
      const values = await form.validateFields();
      const groupSettings = {};
      const group = groups.find(g => g.groupName === groupName);
      if (group) {
        group.rows.forEach(row => {
          if (values[row.setting_key] !== undefined) {
            groupSettings[row.setting_key] = values[row.setting_key];
          }
        });
      }
      await api.updateSettings({ scope: "global", settings: groupSettings });
      msgApi.success(`Settings saved for ${groupName}`);
      // Update initial values after save
      setInitialValues((prev) => ({ ...prev, ...groupSettings }));
    } catch (e) {
      msgApi.error(e?.message || `Failed to save settings for ${groupName}`);
    } finally {
      setSaving((prev) => ({ ...prev, [groupName]: false }));
    }
  };

  const resetGroup = (groupName) => {
    const group = groups.find(g => g.groupName === groupName);
    if (group) {
      const groupDefaults = {};
      group.rows.forEach(row => {
        const fieldType = row.field_type_code || "text";
        let defaultValue = defaultValues[row.setting_key];
        
        // If default value is not set, parse from row.default_value
        if (defaultValue === undefined) {
          defaultValue = parseValue(row.default_value, fieldType);
        }
        
        // Coerce to appropriate type
        if (fieldType === "number" || fieldType === "currency" || fieldType === "percentage" || fieldType === "rating") {
          defaultValue = coerceNumber(defaultValue, defaultValue);
        } else if (fieldType === "boolean") {
          defaultValue = coerceBoolean(defaultValue, false);
        } else if (fieldType === "color") {
          defaultValue = convertColorToHex(defaultValue);
        } else if (fieldType === "single_choice" || fieldType === "multi_choice") {
          let cfg = row.field_config_json || {};
          
          // If field_config_json is a string, try to parse it as JSON
          if (typeof cfg === "string") {
            try {
              cfg = JSON.parse(cfg);
            } catch (e) {
              cfg = {};
            }
          }
          
          // Handle options in different formats
          let rawOptions = cfg?.options;
          if (rawOptions && typeof rawOptions === "string") {
            try {
              rawOptions = JSON.parse(rawOptions);
            } catch (e) {
              rawOptions = rawOptions.split(",").map(s => s.trim()).filter(Boolean);
            }
          }
          
          if (!Array.isArray(rawOptions)) {
            rawOptions = [];
          }
          
          const normalizedOptions = normalizeOptions(rawOptions);
          if (normalizedOptions.length > 0 && defaultValue) {
            const matched = normalizedOptions.find(opt => 
              opt.value === defaultValue || opt.label === defaultValue || String(opt.value) === String(defaultValue)
            );
            if (matched) defaultValue = matched.value;
          }
        }
        
        groupDefaults[row.setting_key] = defaultValue;
      });
      form.setFieldsValue(groupDefaults);
      msgApi.info(`Settings reset to default for ${groupName}`);
    }
  };

  const tabComponent = useMemo(() => {
    const VCTab = viewComponentRegistry.tab;
    if (!VCTab) return null;
    
    const tabs = groups.map((g) => ({
      key: g.groupName,
      label: g.groupName,
      children: (
        <Card variant="outlined">
          {g.rows.map((row) => {
            const component = mapSettingToVC(row);
            const Cmp = viewComponentRegistry[component.type];
            if (!Cmp) return null;
            const key = getComponentKey(component);
            return <Cmp key={key} component={component} />;
          })}
          <div style={{ marginTop: 24, display: "flex", justifyContent: "flex-end", gap: 8 }}>
            <Button 
              onClick={() => resetGroup(g.groupName)}
              disabled={loading || saving[g.groupName]}
            >
              Reset to Default
            </Button>
            <Button 
              type="primary" 
              onClick={() => saveGroup(g.groupName)} 
              loading={saving[g.groupName]} 
              disabled={loading}
            >
              Save {g.groupName}
            </Button>
          </div>
        </Card>
      ),
    }));

    return {
      uuid: "settings-tabs",
      type: "tab",
      input_values: {
        tabs,
        tab_position: "left",
        active_key: activeGroup,
        on_change: setActiveGroup,
      },
    };
  }, [groups, activeGroup, saving, loading, resetGroup, saveGroup]);

  const VCTab = viewComponentRegistry.tab;

  return (
    <>
      {ctxHolder}
      <Row gutter={[12, 12]}>
        <Col span={24}>
          <Typography.Title level={4} style={{ margin: 0 }}>
            Settings
          </Typography.Title>
          <Typography.Text type="secondary">
            Settings are loaded dynamically by group.
          </Typography.Text>
        </Col>

        <Col span={24}>
          <Form form={form} layout="vertical" disabled={loading}>
            {tabComponent && VCTab && (
              <VCTab component={tabComponent} />
            )}
          </Form>
        </Col>
      </Row>
    </>
  );
}

