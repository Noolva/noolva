import React, { useEffect, useMemo, useState } from "react";
import { Button, Card, Col, Form, Input, InputNumber, Modal, Row, Space, Typography, message, App } from "antd";
import { SafetyCertificateOutlined, MobileOutlined, ClockCircleOutlined } from "@ant-design/icons";
import { viewComponentRegistry } from "../components/ViewComponents";
import { getComponentKey, coerceNumber, coerceBoolean, normalizeOptions } from "../components/ViewComponents/vcTypes";
import { api } from "../utils/api";
import { useAuth } from "../contexts/AuthContext";

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
  } else if (fieldType === "duration") {
    vcType = "duration";
    if (cfg?.min != null) input_values.min = cfg.min;
    if (cfg?.max != null) input_values.max = cfg.max;
    if (cfg?.step != null) input_values.step = cfg.step;
    if (cfg?.unit) input_values.unit = cfg.unit;
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

  // Session idle lock (current user's override)
  const [userIdle, setUserIdle] = useState({ idle_timeout_minutes: null, effective_idle_timeout_minutes: 15 });
  const [idleInputValue, setIdleInputValue] = useState(null);
  const [idleSaveLoading, setIdleSaveLoading] = useState(false);
  const { refreshUser } = useAuth();

  // Two-Factor Authentication state
  const [user2FA, setUser2FA] = useState({ enable_2fa: false });
  const [twoFALoading, setTwoFALoading] = useState(false);
  const [twoFASetupModalOpen, setTwoFASetupModalOpen] = useState(false);
  const [twoFASetupData, setTwoFASetupData] = useState(null);
  const [twoFAVerifyLoading, setTwoFAVerifyLoading] = useState(false);
  const [twoFACode, setTwoFACode] = useState("");
  const { message: messageApi } = App.useApp();

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
          if (fieldType === "number" || fieldType === "currency" || fieldType === "percentage" || fieldType === "rating" || fieldType === "duration") {
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

  // Load user context for 2FA and idle timeout
  useEffect(() => {
    let mounted = true;
    const load = async () => {
      try {
        const ctx = await api.getUserContext();
        if (mounted && ctx?.user) {
          setUser2FA({ enable_2fa: !!ctx.user.enable_2fa });
          const effective = ctx.user.effective_idle_timeout_minutes ?? 15;
          const userOverride = ctx.user.idle_timeout_minutes;
          setUserIdle({
            idle_timeout_minutes: userOverride,
            effective_idle_timeout_minutes: effective,
          });
          setIdleInputValue(userOverride ?? null);
        }
      } catch (e) {
        // Ignore; user may not be logged in
      }
    };
    load();
    return () => { mounted = false; };
  }, [twoFASetupModalOpen]); // Refetch when setup modal closes (after verify)

  const handleIdleSave = async () => {
    setIdleSaveLoading(true);
    try {
      await api.updateMyIdleTimeout(idleInputValue);
      await refreshUser();
      const ctx = await api.getUserContext();
      if (ctx?.user) {
        const effective = ctx.user.effective_idle_timeout_minutes ?? 15;
        setUserIdle({
          idle_timeout_minutes: ctx.user.idle_timeout_minutes,
          effective_idle_timeout_minutes: effective,
        });
        setIdleInputValue(ctx.user.idle_timeout_minutes ?? null);
      }
      messageApi.success("Idle lock setting saved");
    } catch (e) {
      messageApi.error(e?.response?.data?.detail || e?.message || "Failed to save");
    } finally {
      setIdleSaveLoading(false);
    }
  };

  const handleIdleResetDefault = async () => {
    setIdleSaveLoading(true);
    try {
      await api.updateMyIdleTimeout(null);
      await refreshUser();
      const ctx = await api.getUserContext();
      if (ctx?.user) {
        const effective = ctx.user.effective_idle_timeout_minutes ?? 15;
        setUserIdle({ idle_timeout_minutes: null, effective_idle_timeout_minutes: effective });
        setIdleInputValue(null);
      }
      messageApi.success("Reset to global default");
    } catch (e) {
      messageApi.error(e?.response?.data?.detail || e?.message || "Failed to reset");
    } finally {
      setIdleSaveLoading(false);
    }
  };

  const handleEnable2FAClick = async () => {
    setTwoFALoading(true);
    try {
      const data = await api.get2FASetup();
      setTwoFASetupData(data);
      setTwoFACode("");
      setTwoFASetupModalOpen(true);
    } catch (e) {
      messageApi.error(e?.message || "Failed to start 2FA setup");
    } finally {
      setTwoFALoading(false);
    }
  };

  const handle2FAVerify = async () => {
    const code = twoFACode.trim();
    if (!code || code.length !== 6) {
      messageApi.warning("Please enter the 6-digit code from your authenticator app");
      return;
    }
    setTwoFAVerifyLoading(true);
    try {
      await api.verify2FA(code);
      messageApi.success("Two-factor authentication enabled");
      setTwoFASetupModalOpen(false);
      setTwoFASetupData(null);
      const ctx = await api.getUserContext();
      if (ctx?.user) setUser2FA({ enable_2fa: true });
    } catch (e) {
      messageApi.error(e?.response?.data?.detail || e?.message || "Invalid code");
    } finally {
      setTwoFAVerifyLoading(false);
    }
  };

  const handleDisable2FA = async () => {
    setTwoFALoading(true);
    try {
      await api.disable2FA();
      messageApi.success("Two-factor authentication disabled");
      setUser2FA({ enable_2fa: false });
    } catch (e) {
      messageApi.error(e?.message || "Failed to disable 2FA");
    } finally {
      setTwoFALoading(false);
    }
  };

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
        if (fieldType === "number" || fieldType === "currency" || fieldType === "percentage" || fieldType === "rating" || fieldType === "duration") {
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

        {/* Session idle lock (current user) */}
        <Col span={24}>
          <Card title="Session idle lock" size="small" style={{ marginBottom: 16 }}>
            <Space direction="vertical" size="middle" style={{ width: "100%" }}>
              <div>
                <Space align="center">
                  <ClockCircleOutlined style={{ fontSize: 18 }} />
                  <Typography.Text strong>Idle session lock (minutes)</Typography.Text>
                </Space>
                <Typography.Text type="secondary" style={{ display: "block", marginTop: 4 }}>
                  Lock session after this many minutes of inactivity; re-enter password (and 2FA if enabled) to continue. -1 = no lock. Leave default to use global setting.
                </Typography.Text>
                <div style={{ marginTop: 12 }}>
                  <Typography.Text type="secondary">Current: </Typography.Text>
                  {userIdle.idle_timeout_minutes === null || userIdle.idle_timeout_minutes === undefined ? (
                    <Typography.Text>Using default ({userIdle.effective_idle_timeout_minutes} min)</Typography.Text>
                  ) : userIdle.idle_timeout_minutes === -1 ? (
                    <Typography.Text>No lock</Typography.Text>
                  ) : (
                    <Typography.Text>{userIdle.idle_timeout_minutes} minutes</Typography.Text>
                  )}
                </div>
                <Space style={{ marginTop: 12 }} wrap>
                  <InputNumber
                    min={-1}
                    max={1440}
                    value={idleInputValue ?? undefined}
                    onChange={(v) => setIdleInputValue(v !== undefined && v !== null ? Number(v) : null)}
                    placeholder="Use global default"
                    addonAfter="minutes"
                    style={{ width: 160 }}
                  />
                  <Button type="primary" size="small" onClick={handleIdleSave} loading={idleSaveLoading}>
                    Save
                  </Button>
                  <Button size="small" onClick={handleIdleResetDefault} loading={idleSaveLoading}>
                    Reset to default
                  </Button>
                </Space>
              </div>
            </Space>
          </Card>
        </Col>

        {/* Two-Factor Authentication */}
        <Col span={24}>
          <Card title="Two-Factor Authentication" size="small" style={{ marginBottom: 16 }}>
            <Space direction="vertical" size="middle" style={{ width: "100%" }}>
              <div>
                <Space align="center">
                  <SafetyCertificateOutlined style={{ fontSize: 18 }} />
                  <Typography.Text strong>Authenticator app</Typography.Text>
                  {user2FA.enable_2fa ? (
                    <Typography.Text type="success">Enabled</Typography.Text>
                  ) : (
                    <Typography.Text type="secondary">Not enabled</Typography.Text>
                  )}
                </Space>
                <div style={{ marginTop: 8 }}>
                  {user2FA.enable_2fa ? (
                    <Button danger size="small" onClick={handleDisable2FA} loading={twoFALoading}>
                      Disable
                    </Button>
                  ) : (
                    <Button type="primary" size="small" onClick={handleEnable2FAClick} loading={twoFALoading}>
                      Enable authenticator app
                    </Button>
                  )}
                </div>
              </div>
              <div>
                <Space align="center">
                  <MobileOutlined style={{ fontSize: 18 }} />
                  <Typography.Text strong>SMS</Typography.Text>
                  <Typography.Text type="secondary">Coming soon (AWS SES)</Typography.Text>
                </Space>
                <div style={{ marginTop: 8 }}>
                  <Button size="small" disabled>
                    Enable SMS
                  </Button>
                </div>
              </div>
            </Space>
          </Card>
        </Col>

        <Col span={24}>
          <Form form={form} layout="vertical" disabled={loading}>
            {tabComponent && VCTab && (
              <VCTab component={tabComponent} />
            )}
          </Form>
        </Col>
      </Row>

      {/* 2FA Setup Modal: show QR + secret + verify code */}
      <Modal
        title="Set up authenticator app"
        open={twoFASetupModalOpen}
        onCancel={() => {
          setTwoFASetupModalOpen(false);
          setTwoFASetupData(null);
        }}
        footer={null}
        destroyOnClose
        width={400}
      >
        {twoFASetupData && (
          <Space direction="vertical" size="middle" style={{ width: "100%" }}>
            <Typography.Text type="secondary">
              Scan the QR code with your authenticator app (e.g. Google Authenticator, Authy), or enter the secret manually.
            </Typography.Text>
            <div style={{ textAlign: "center" }}>
              <img
                src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(twoFASetupData.provisioning_uri || "")}`}
                alt="QR code for authenticator"
                style={{ border: "1px solid #f0f0f0", borderRadius: 8 }}
              />
            </div>
            <div>
              <Typography.Text type="secondary" style={{ fontSize: 12 }}>Manual entry secret:</Typography.Text>
              <Input.TextArea
                readOnly
                value={twoFASetupData.secret || ""}
                rows={2}
                style={{ marginTop: 4, fontFamily: "monospace" }}
              />
            </div>
            <div>
              <Typography.Text>Enter the 6-digit code from your app:</Typography.Text>
              <Input
                placeholder="000000"
                maxLength={6}
                value={twoFACode}
                onChange={(e) => setTwoFACode(e.target.value.replace(/\D/g, ""))}
                style={{ marginTop: 8 }}
              />
            </div>
            <Space>
              <Button type="primary" onClick={handle2FAVerify} loading={twoFAVerifyLoading}>
                Verify and enable
              </Button>
              <Button
                onClick={() => {
                  setTwoFASetupModalOpen(false);
                  setTwoFASetupData(null);
                }}
              >
                Cancel
              </Button>
            </Space>
          </Space>
        )}
      </Modal>
    </>
  );
}

