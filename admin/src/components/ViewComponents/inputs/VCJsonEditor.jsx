import React, { useState, useEffect } from "react";
import { Form, Input, Button, Space, message, Tooltip } from "antd";
import { CheckOutlined, CloseOutlined, ReloadOutlined } from "@ant-design/icons";

const { TextArea } = Input;

export function VCJsonEditor({ component }) {
  const input_values = component?.input_values || {};
  const [isOpen, setIsOpen] = useState(input_values.default_open || false);
  const [jsonString, setJsonString] = useState('');
  const [isValid, setIsValid] = useState(true);
  const [error, setError] = useState(null);

  // Initialize with default value
  useEffect(() => {
    const defaultValue = input_values.default_value || input_values.value || '';
    if (defaultValue) {
      try {
        const parsed = typeof defaultValue === 'string' ? JSON.parse(defaultValue) : defaultValue;
        setJsonString(JSON.stringify(parsed, null, 2));
        setIsValid(true);
        setError(null);
      } catch (e) {
        setJsonString(typeof defaultValue === 'string' ? defaultValue : JSON.stringify(defaultValue));
        setIsValid(false);
        setError(e.message);
      }
    }
  }, [input_values.default_value, input_values.value]);

  const validateJson = (text) => {
    if (!text.trim()) {
      setIsValid(true);
      setError(null);
      return true;
    }
    try {
      JSON.parse(text);
      setIsValid(true);
      setError(null);
      return true;
    } catch (e) {
      setIsValid(false);
      setError(e.message);
      return false;
    }
  };

  const handleChange = (e) => {
    const value = e.target.value;
    setJsonString(value);
    validateJson(value);
  };

  const handleFormat = () => {
    if (!jsonString.trim()) {
      message.info('No JSON to format');
      return;
    }
    try {
      const parsed = JSON.parse(jsonString);
      const formatted = JSON.stringify(parsed, null, 2);
      setJsonString(formatted);
      setIsValid(true);
      setError(null);
      message.success('JSON formatted successfully');
    } catch (e) {
      message.error(`Invalid JSON: ${e.message}`);
      setIsValid(false);
      setError(e.message);
    }
  };

  const handleReset = () => {
    const defaultValue = input_values.default_value || input_values.value || '';
    if (defaultValue) {
      try {
        const parsed = typeof defaultValue === 'string' ? JSON.parse(defaultValue) : defaultValue;
        setJsonString(JSON.stringify(parsed, null, 2));
        setIsValid(true);
        setError(null);
        message.success('JSON reset to default value');
      } catch (e) {
        setJsonString(typeof defaultValue === 'string' ? defaultValue : JSON.stringify(defaultValue));
        setIsValid(false);
        setError(e.message);
      }
    } else {
      setJsonString('');
      setIsValid(true);
      setError(null);
      message.success('JSON cleared');
    }
  };

  const toggleOpen = () => {
    setIsOpen(!isOpen);
    // Trigger validation when opening
    if (!isOpen) {
      validateJson(jsonString);
    }
  };

  // Get value for form submission
  const getValue = () => {
    if (!jsonString.trim()) {
      return null;
    }
    try {
      return JSON.parse(jsonString);
    } catch (e) {
      return jsonString; // Return as string if invalid
    }
  };

  return (
    <Form.Item
      name={input_values.name}
      label={input_values.label}
      rules={[
        {
          validator: () => {
            if (input_values.required && !jsonString.trim()) {
              return Promise.reject(new Error(`${input_values.label || 'This field'} is required`));
            }
            if (!isValid && jsonString.trim()) {
              return Promise.reject(new Error(`Invalid JSON: ${error}`));
            }
            return Promise.resolve();
          },
        },
      ]}
      getValueFromEvent={() => getValue()}
      getValueProps={(value) => {
        if (value === null || value === undefined) {
          return { value: '' };
        }
        try {
          const jsonStr = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
          return { value: jsonStr };
        } catch (e) {
          return { value: String(value) };
        }
      }}
    >
      <div>
        <div style={{ marginBottom: '8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Space>
            <Button
              type={isOpen ? 'default' : 'primary'}
              onClick={toggleOpen}
              size="small"
            >
              {isOpen ? <CloseOutlined /> : <CheckOutlined />}
              {isOpen ? ' Close Editor' : ' Open Editor'}
            </Button>
            {isOpen && (
              <>
                <Button
                  icon={<ReloadOutlined />}
                  onClick={handleFormat}
                  size="small"
                  disabled={!jsonString.trim()}
                >
                  Format
                </Button>
                <Button
                  icon={<ReloadOutlined />}
                  onClick={handleReset}
                  size="small"
                >
                  Reset
                </Button>
              </>
            )}
          </Space>
          {isOpen && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              {isValid ? (
                <Tooltip title="Valid JSON">
                  <span style={{ color: '#52c41a', fontSize: '12px' }}>
                    <CheckOutlined /> Valid
                  </span>
                </Tooltip>
              ) : (
                <Tooltip title={error}>
                  <span style={{ color: '#ff4d4f', fontSize: '12px' }}>
                    <CloseOutlined /> Invalid
                  </span>
                </Tooltip>
              )}
            </div>
          )}
        </div>
        {isOpen && (
          <TextArea
            value={jsonString}
            onChange={handleChange}
            placeholder={input_values.place_holder || 'Enter JSON...'}
            rows={input_values.rows || 8}
            style={{
              fontFamily: 'monospace',
              fontSize: '13px',
              borderColor: isValid ? undefined : '#ff4d4f',
            }}
          />
        )}
        {!isOpen && jsonString && (
          <div
            style={{
              padding: '8px 12px',
              backgroundColor: '#f5f5f5',
              borderRadius: '4px',
              fontFamily: 'monospace',
              fontSize: '12px',
              color: '#666',
              maxHeight: '100px',
              overflow: 'auto',
            }}
          >
            {jsonString.length > 100 ? `${jsonString.substring(0, 100)}...` : jsonString}
          </div>
        )}
        {error && isOpen && (
          <div style={{ marginTop: '8px', color: '#ff4d4f', fontSize: '12px' }}>
            Error: {error}
          </div>
        )}
      </div>
    </Form.Item>
  );
}
