import React, { useEffect, useState, useMemo, useRef } from "react";
import { Button, Card, Col, Form, Row, Typography, message, Tabs, Space, Modal, Input, Checkbox } from "antd";
import { viewComponentRegistry } from "../components/ViewComponents";
import { getComponentKey, coerceNumber, coerceBoolean, normalizeOptions } from "../components/ViewComponents/vcTypes";
import { api } from "../utils/api";
import { useAuth } from "../contexts/AuthContext";
import { useTheme } from "../contexts/ThemeContext";

const APP_SCOPE = import.meta.env.VITE_APP_SCOPE || "saas";

function convertColorToHex(colorValue) {
  if (!colorValue) return colorValue;
  if (typeof colorValue === "string") {
    const cleaned = colorValue.replace(/^["']+|["']+$/g, "");
    if (/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(cleaned)) return cleaned;
    return cleaned;
  }
  if (typeof colorValue === "object" && colorValue !== null) {
    if (colorValue.metaColor) {
      const meta = colorValue.metaColor;
      if (meta.r !== undefined && meta.g !== undefined && meta.b !== undefined) {
        const r = Math.round(meta.r).toString(16).padStart(2, "0");
        const g = Math.round(meta.g).toString(16).padStart(2, "0");
        const b = Math.round(meta.b).toString(16).padStart(2, "0");
        return `#${r}${g}${b}`;
      }
    }
    if (colorValue.r !== undefined && colorValue.g !== undefined && colorValue.b !== undefined) {
      const r = Math.round(colorValue.r).toString(16).padStart(2, "0");
      const g = Math.round(colorValue.g).toString(16).padStart(2, "0");
      const b = Math.round(colorValue.b).toString(16).padStart(2, "0");
      return `#${r}${g}${b}`;
    }
    if (typeof colorValue.toHexString === "function") return colorValue.toHexString();
    if (colorValue.hex) return colorValue.hex;
  }
  return colorValue;
}

function parseValue(value, fieldType) {
  if (value == null || value === "") return value;
  if (typeof value === "string") {
    try {
      const parsed = JSON.parse(value.trim());
      if (typeof parsed === "string" && parsed.trim()) {
        try {
          return JSON.parse(parsed.trim());
        } catch (e) {
          return parsed;
        }
      }
      return parsed;
    } catch (e) { }
    const cleaned = value.replace(/^["']+|["']+$/g, "");
    return cleaned !== value ? cleaned : value;
  }
  return value;
}

const THEME_FIELDS_GLOBAL_BASE = [
  { key: "theme", label: "Theme", type: "select", options: [{ label: "Default Corporate", value: "default" }, { label: "Slate Corporate", value: "slate" }] },
  { key: "theme_color_primary", label: "Primary Color", type: "color" },
  { key: "theme_color_secondary", label: "Secondary Color", type: "color" },
  { key: "header_bg_color", label: "Header Background", type: "color", allow_none: true },
  { key: "sidebar_bg_color", label: "Sidebar Background", type: "color", allow_none: true },
  { key: "font_size_base", label: "Base Font Size (px)", type: "number", min: 12, max: 18 },
  { key: "font_size_small", label: "Small Font Size (px)", type: "number", min: 10, max: 16 },
  { key: "font_size_large", label: "Large Font Size (px)", type: "number", min: 14, max: 22 },
];

// My Account: hide theme select - only colors and fonts
const THEME_FIELDS_ACCOUNT = THEME_FIELDS_GLOBAL_BASE.filter((f) => f.key !== "theme");

function mapFieldToVC(field, extraProps = {}) {
  const input_values = {
    name: field.key,
    label: field.label,
    place_holder: field.label,
    ...extraProps,
  };
  if (field.type === "number" && (field.min != null || field.max != null)) {
    if (field.min != null) input_values.min = field.min;
    if (field.max != null) input_values.max = field.max;
  }
  if (field.type === "select" && field.options) {
    input_values.options = normalizeOptions(field.options);
  }
  let vcType = "text";
  if (field.type === "color") {
    vcType = "color";
    if (field.allow_none) input_values.allow_none = true;
  }
  else if (field.type === "number") vcType = "number";
  else if (field.type === "select") vcType = "select";
  return { type: vcType, input_values, _raw: field };
}

export default function Themes() {
  const { user } = useAuth();
  const { setPrimarySecondary, selectThemeByKey, setFontBase, setFontSmall, setFontLarge, setHeaderBgColor, setSidebarBgColor } = useTheme();
  const [msgApi, ctxHolder] = message.useMessage();
  const [activeTab, setActiveTab] = useState("global");
  const [globalThemes, setGlobalThemes] = useState([]);
  const [userThemes, setUserThemes] = useState([]);
  const [activeTheme, setActiveTheme] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();
  const [saveAsNewModal, setSaveAsNewModal] = useState({ visible: false });
  const [newThemeName, setNewThemeName] = useState("");
  const [applyDefaultSaas, setApplyDefaultSaas] = useState(false);
  const [applyDefaultTenant, setApplyDefaultTenant] = useState(false);
  const [formDirty, setFormDirty] = useState(false);
  const initialValuesRef = useRef(null);

  const scope = APP_SCOPE;

  // Global theme options: built-in + custom global themes
  const globalThemeOptions = useMemo(() => {
    const builtin = [{ label: "Default Corporate", value: "default" }, { label: "Slate Corporate", value: "slate" }];
    const custom = (globalThemes || [])
      .filter((t) => !t.is_builtin)
      .map((t) => ({ label: t.theme_name, value: t.theme_key }));
    return [...builtin, ...custom];
  }, [globalThemes]);

  const THEME_FIELDS_GLOBAL = useMemo(
    () =>
      THEME_FIELDS_GLOBAL_BASE.map((f) => {
        if (f.key === "theme") {
          return { ...f, options: globalThemeOptions };
        }
        return f;
      }),
    [globalThemeOptions]
  );

  useEffect(() => {
    let mounted = true;
    const load = async () => {
      setLoading(true);
      try {
        const [globalRes, userRes] = await Promise.all([
          api.getThemes({ scope, user_id: null }),
          user ? api.getThemes({ scope, user_id: user.user_id }) : Promise.resolve({ themes: [] }),
        ]);
        if (!mounted) return;
        setGlobalThemes(globalRes?.themes || []);
        setUserThemes(userRes?.themes || []);

        const activeRes = await api.getActiveTheme({ scope, user_id: activeTab === "account" ? user?.user_id : null });
        if (!mounted) return;
        setActiveTheme(activeRes?.theme || null);
        const rawTj = activeRes?.theme?.theme_json;
        const tj = (() => {
          if (!rawTj) return {};
          if (typeof rawTj === 'string') {
            try { return JSON.parse(rawTj); } catch { return {}; }
          }
          return rawTj;
        })();
        const formValues = {};
        const fields = activeTab === "account" ? THEME_FIELDS_ACCOUNT : THEME_FIELDS_GLOBAL;
        fields.forEach((f) => {
          let v = tj[f.key];
          if (v != null) {
            if (f.type === "color") v = convertColorToHex(v);
            else if (f.type === "number") v = coerceNumber(v, v);
          }
          formValues[f.key] = v ?? (f.key === "theme" ? "default" : f.key === "theme_color_primary" ? "#1890ff" : f.key === "theme_color_secondary" ? "#52c41a" : f.key === "header_bg_color" ? "#2563eb" : f.key === "sidebar_bg_color" ? "#f1f5f9" : f.key === "font_size_base" ? 14 : f.key === "font_size_small" ? 12 : 16);
        });
        // For My Account, theme comes from active theme key
        if (activeTab === "account") formValues.theme = activeRes?.theme?.theme_key || tj?.theme || "default";
        form.setFieldsValue(formValues);
        initialValuesRef.current = { ...formValues };
        setFormDirty(false);
      } catch (e) {
        msgApi.error(e?.message || "Failed to load themes");
      } finally {
        if (mounted) setLoading(false);
      }
    };
    load();
    return () => { mounted = false; };
  }, [scope, activeTab, user?.user_id, form, msgApi]);

  const handleSave = async (saveAsNew = false) => {
    setSaving(true);
    try {
      const values = await form.validateFields();
      const themeKey = activeTab === "account" ? (activeTheme?.theme_key || activeTheme?.theme_json?.theme || "default") : (values.theme || "default");
      const themeJson = {
        theme: themeKey,
        theme_color_primary: typeof values.theme_color_primary === "string" ? values.theme_color_primary : convertColorToHex(values.theme_color_primary),
        theme_color_secondary: typeof values.theme_color_secondary === "string" ? values.theme_color_secondary : convertColorToHex(values.theme_color_secondary),
        header_bg_color: values.header_bg_color === "none" ? "none" : (typeof values.header_bg_color === "string" ? values.header_bg_color : convertColorToHex(values.header_bg_color)) || "none",
        sidebar_bg_color: values.sidebar_bg_color === "none" ? "none" : (typeof values.sidebar_bg_color === "string" ? values.sidebar_bg_color : convertColorToHex(values.sidebar_bg_color)) || "none",
        theme_mode: "light",
        font_size_base: coerceNumber(values.font_size_base, 14),
        font_size_small: coerceNumber(values.font_size_small, 12),
        font_size_large: coerceNumber(values.font_size_large, 16),
      };

      if (activeTab === "account") {
        // My Account: always upsert (one record per user)
        await api.upsertMyTheme({ theme_json: themeJson, scope });
        msgApi.success("Theme saved");
        const [globalRes, userRes] = await Promise.all([
          api.getThemes({ scope, user_id: null }),
          api.getThemes({ scope, user_id: user?.user_id }),
        ]);
        setGlobalThemes(globalRes?.themes || []);
        setUserThemes(userRes?.themes || []);
      } else if (saveAsNew) {
        // Global: create new theme with optional apply defaults
        const name = newThemeName.trim() || `Custom Theme ${Date.now()}`;
        const key = `global_${Date.now()}`;
        await api.createTheme({
          theme_name: name,
          theme_key: key,
          theme_json: themeJson,
          scope,
          tenant_id: null,
          apply_default_saas: applyDefaultSaas,
          apply_default_tenant: applyDefaultTenant,
        });
        msgApi.success("Theme saved as new");
        setSaveAsNewModal({ visible: false });
        setNewThemeName("");
        setApplyDefaultSaas(false);
        setApplyDefaultTenant(false);
        setFormDirty(false);
        initialValuesRef.current = form.getFieldsValue();
        const [globalRes] = await Promise.all([api.getThemes({ scope, user_id: null })]);
        setGlobalThemes(globalRes?.themes || []);
      }

      setPrimarySecondary(themeJson.theme_color_primary, themeJson.theme_color_secondary);
      selectThemeByKey(themeJson.theme);
      setFontBase(themeJson.font_size_base);
      setFontSmall(themeJson.font_size_small);
      setFontLarge(themeJson.font_size_large);
      setHeaderBgColor(themeJson.header_bg_color === "none" ? "" : themeJson.header_bg_color || "#2563eb");
      setSidebarBgColor(themeJson.sidebar_bg_color === "none" ? "" : themeJson.sidebar_bg_color || "#f1f5f9");
    } catch (e) {
      msgApi.error(e?.message || "Failed to save theme");
    } finally {
      setSaving(false);
    }
  };

  const handleSaveAsNew = () => {
    setSaveAsNewModal({ visible: false });
    handleSave(true);
  };

  const handleResetToDefault = async () => {
    setSaving(true);
    try {
      const activeRes = await api.getActiveTheme({ scope, user_id: null });
      const defaultTheme = activeRes?.theme;
      if (!defaultTheme?.theme_json) {
        msgApi.error("Could not load default theme");
        return;
      }
      const themeJson = defaultTheme.theme_json;
      await api.upsertMyTheme({ theme_json, scope });
      msgApi.success("Theme reset to default");
      const vals = {};
      THEME_FIELDS_ACCOUNT.forEach((f) => {
        let v = themeJson[f.key];
        if (v != null) {
          if (f.type === "color") v = convertColorToHex(v);
          else if (f.type === "number") v = coerceNumber(v, v);
        }
        vals[f.key] = v ?? (f.key === "theme_color_primary" ? "#1890ff" : f.key === "theme_color_secondary" ? "#52c41a" : f.key === "header_bg_color" ? "#2563eb" : f.key === "sidebar_bg_color" ? "#f1f5f9" : f.key === "font_size_base" ? 14 : f.key === "font_size_small" ? 12 : 16);
      });
      form.setFieldsValue(vals);
      setPrimarySecondary(themeJson.theme_color_primary, themeJson.theme_color_secondary);
      selectThemeByKey(themeJson.theme || "default");
      setFontBase(themeJson.font_size_base || 14);
      setFontSmall(themeJson.font_size_small || 12);
      setFontLarge(themeJson.font_size_large || 16);
      setHeaderBgColor(themeJson.header_bg_color === "none" ? "" : themeJson.header_bg_color || "#2563eb");
      setSidebarBgColor(themeJson.sidebar_bg_color === "none" ? "" : themeJson.sidebar_bg_color || "#f1f5f9");
      const [globalRes, userRes] = await Promise.all([
        api.getThemes({ scope, user_id: null }),
        api.getThemes({ scope, user_id: user?.user_id }),
      ]);
      setGlobalThemes(globalRes?.themes || []);
      setUserThemes(userRes?.themes || []);
      setActiveTheme({ ...defaultTheme, user_id: user?.user_id });
    } catch (e) {
      msgApi.error(e?.message || "Failed to reset theme");
    } finally {
      setSaving(false);
    }
  };

  const handleGlobalFormChange = (changedValues, allValues) => {
    // When theme dropdown changes, load that theme's data into the form
    if (changedValues && "theme" in changedValues) {
      handleGlobalThemeSelect(changedValues.theme);
      return;
    }
    const current = allValues || form.getFieldsValue();
    const initial = initialValuesRef.current;
    if (!initial) return;
    const dirty = Object.keys(current).some((k) => {
      const c = current[k];
      const i = initial[k];
      if (typeof c === "string" && typeof i === "string") return c !== i;
      return JSON.stringify(c) !== JSON.stringify(i);
    });
    setFormDirty(dirty);
  };

  // When user selects a different theme on Global tab, load that theme's data
  const handleGlobalThemeSelect = (themeKey) => {
    if (!themeKey) return;
    const theme = globalThemes.find((t) => t.theme_key === themeKey);
    if (!theme) return;
    const rawTj = theme.theme_json;
    const tj = (() => {
      if (!rawTj) return {};
      if (typeof rawTj === "string") {
        try { return JSON.parse(rawTj); } catch { return {}; }
      }
      return rawTj;
    })();
    const vals = { theme: themeKey };
    ["theme_color_primary", "theme_color_secondary", "header_bg_color", "sidebar_bg_color", "font_size_base", "font_size_small", "font_size_large"].forEach((key) => {
      let v = tj[key];
      if (v != null) {
        if (key.startsWith("theme_color")) v = convertColorToHex(v);
        else if (key.startsWith("font_")) v = coerceNumber(v, v);
      }
      vals[key] = v ?? (key === "theme_color_primary" ? "#1890ff" : key === "theme_color_secondary" ? "#52c41a" : key === "header_bg_color" ? "#2563eb" : key === "sidebar_bg_color" ? "#f1f5f9" : key === "font_size_base" ? 14 : key === "font_size_small" ? 12 : 16);
    });
    form.setFieldsValue(vals);
    setActiveTheme(theme);
    initialValuesRef.current = { ...vals };
    setFormDirty(false);
    // Apply selected theme to live UI (preview)
    setPrimarySecondary(vals.theme_color_primary, vals.theme_color_secondary);
    selectThemeByKey(vals.theme);
    setFontBase(vals.font_size_base);
    setFontSmall(vals.font_size_small);
    setFontLarge(vals.font_size_large);
    setHeaderBgColor(vals.header_bg_color === "none" ? "" : vals.header_bg_color || "#2563eb");
    setSidebarBgColor(vals.sidebar_bg_color === "none" ? "" : vals.sidebar_bg_color || "#f1f5f9");
  };

  // Global: NO Save. Only "Save as New Theme" when form is modified (dirty)
  const showGlobalSaveAsNew = activeTab === "global" && formDirty;

  // My Account: always show Save (upsert - one record per user)
  const showAccountSave = activeTab === "account";

  return (
    <>
      {ctxHolder}
      <Row gutter={[12, 12]}>
        <Col span={24}>
          <Typography.Title level={4} style={{ margin: 0 }}>
            Themes
          </Typography.Title>
          <Typography.Text type="secondary">
            Customize global (SAAS) or your account theme. Theme mode (light/dark) is in the header.
          </Typography.Text>
        </Col>

        <Col span={24}>
          <Tabs
            activeKey={activeTab}
            onChange={setActiveTab}
            items={[
              {
                key: "global",
                label: "Global Theme",
                children: (
                  <Card title="Global Theme" loading={loading}>
                    <Form form={form} layout="vertical" onValuesChange={handleGlobalFormChange}>
                      {THEME_FIELDS_GLOBAL.map((f) => {
                        const extraProps = f.key === "theme" ? { onChange: handleGlobalThemeSelect } : {};
                        const comp = mapFieldToVC(f, extraProps);
                        const Cmp = viewComponentRegistry[comp.type];
                        if (!Cmp) return null;
                        return <Cmp key={f.key} component={comp} />;
                      })}
                      <Space style={{ marginTop: 16 }}>
                        {showGlobalSaveAsNew && (
                          <Button
                            type="primary"
                            onClick={() => setSaveAsNewModal({ visible: true })}
                            loading={saving}
                            disabled={loading}
                          >
                            Save as New Theme
                          </Button>
                        )}
                      </Space>
                    </Form>
                  </Card>
                ),
              },
              {
                key: "account",
                label: "My Account Theme",
                disabled: !user,
                children: (
                  <Card title="My Account Theme" loading={loading}>
                    {user ? (
                      <Form form={form} layout="vertical">
                        {THEME_FIELDS_ACCOUNT.map((f) => {
                          const comp = mapFieldToVC(f);
                          const Cmp = viewComponentRegistry[comp.type];
                          if (!Cmp) return null;
                          return <Cmp key={f.key} component={comp} />;
                        })}
                        <Space style={{ marginTop: 16 }}>
                          {showAccountSave && (
                            <>
                              <Button type="primary" onClick={() => handleSave(false)} loading={saving} disabled={loading}>
                                Save
                              </Button>
                              <Button onClick={handleResetToDefault} loading={saving} disabled={loading}>
                                Reset
                              </Button>
                            </>
                          )}
                        </Space>
                      </Form>
                    ) : (
                      <Typography.Text type="secondary">Sign in to customize your account theme.</Typography.Text>
                    )}
                  </Card>
                ),
              },
            ]}
          />
        </Col>
      </Row>

      <Modal
        title="Save as New Theme"
        open={saveAsNewModal.visible}
        onOk={handleSaveAsNew}
        onCancel={() => setSaveAsNewModal({ visible: false })}
        okText="Save as New"
      >
        <p>Do not modify existing defaults. Save your changes as a new global theme.</p>
        <Input
          placeholder="New theme name"
          value={newThemeName}
          onChange={(e) => setNewThemeName(e.target.value)}
          style={{ marginTop: 8, marginBottom: 16 }}
        />
        <Space direction="vertical">
          {scope !== "tenant" && (
            <Checkbox checked={applyDefaultSaas} onChange={(e) => setApplyDefaultSaas(e.target.checked)}>
              Apply as default for SAAS
            </Checkbox>
          )}
          <Checkbox checked={applyDefaultTenant} onChange={(e) => setApplyDefaultTenant(e.target.checked)}>
            Apply as default for Tenant
          </Checkbox>
        </Space>
      </Modal>
    </>
  );
}
