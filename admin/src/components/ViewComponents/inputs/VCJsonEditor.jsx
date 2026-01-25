import React, { useState, useEffect, useRef } from "react";
import { Form, Input, Button, Space, message, Tooltip } from "antd";
import { CheckOutlined, CloseOutlined, ReloadOutlined } from "@ant-design/icons";

const { TextArea } = Input;

export function VCJsonEditor({ component }) {
  const input_values = component?.input_values || {};
  const [isOpen, setIsOpen] = useState(input_values.default_open || false);
  const [jsonString, setJsonString] = useState('');
  const [isValid, setIsValid] = useState(true);
  const [error, setError] = useState(null);
  // Use ref to always have the latest value for getValueFromEvent
  const jsonStringRef = useRef('');

  // Initialize with default value
  useEffect(() => {
    const defaultValue = input_values.default_value || input_values.value || '';
    if (defaultValue) {
      try {
        const parsed = typeof defaultValue === 'string' ? JSON.parse(defaultValue) : defaultValue;
        const formatted = JSON.stringify(parsed, null, 2);
        setJsonString(formatted);
        jsonStringRef.current = formatted; // Sync ref
        setIsValid(true);
        setError(null);
      } catch (e) {
        const strValue = typeof defaultValue === 'string' ? defaultValue : JSON.stringify(defaultValue);
        setJsonString(strValue);
        jsonStringRef.current = strValue; // Sync ref
        setIsValid(false);
        setError(e.message);
      }
    } else if (jsonString === '') {
      // Only reset if jsonString is empty to avoid overwriting user input
      setJsonString('');
      jsonStringRef.current = '';
      setIsValid(true);
      setError(null);
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
    // Always update state and ref immediately to keep TextArea in sync
    setJsonString(value);
    jsonStringRef.current = value; // Keep ref in sync
    // Validate asynchronously to avoid blocking input
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
      jsonStringRef.current = formatted;
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
        const formatted = JSON.stringify(parsed, null, 2);
        setJsonString(formatted);
        jsonStringRef.current = formatted;
        setIsValid(true);
        setError(null);
        message.success('JSON reset to default value');
      } catch (e) {
        const strValue = typeof defaultValue === 'string' ? defaultValue : JSON.stringify(defaultValue);
        setJsonString(strValue);
        jsonStringRef.current = strValue;
        setIsValid(false);
        setError(e.message);
      }
    } else {
      setJsonString('');
      jsonStringRef.current = '';
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
      getValueFromEvent={() => {
        // Always return the current value from ref (most up-to-date)
        // This ensures we get exactly what the user typed, including all values like 0
        const currentValue = jsonStringRef.current.trim();
        if (!currentValue) {
          return null;
        }
        // Return the raw JSON string as-is from ref
        // Don't parse and re-stringify as that could lose values
        return currentValue;
      }}
      normalize={(value) => {
        // Normalize: if it's an object, convert to JSON string; if it's already a string, use it
        if (value === null || value === undefined) {
          return null;
        }
        if (typeof value === 'string') {
          return value;
        }
        if (typeof value === 'object') {
          try {
            return JSON.stringify(value, null, 2);
          } catch (e) {
            return JSON.stringify(value);
          }
        }
        return String(value);
      }}
      getValueProps={(value) => {
        // This is called by Ant Design Form to get props for the input
        // But we control the TextArea ourselves via jsonString state
        // So we only use this to sync initial values, not to control the input
        if (value === null || value === undefined) {
          return { value: jsonString || '' };
        }
        // If form provides a value and our state is empty, sync it
        if (typeof value === 'string' && !jsonString) {
          setJsonString(value);
          jsonStringRef.current = value;
          validateJson(value);
        } else if (typeof value === 'object' && !jsonString) {
          try {
            const jsonStr = JSON.stringify(value, null, 2);
            setJsonString(jsonStr);
            jsonStringRef.current = jsonStr;
            validateJson(jsonStr);
          } catch (e) {
            // Ignore
          }
        }
        // Always return jsonString state value to keep TextArea controlled by our state
        return { value: jsonString };
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
            onBlur={() => {
              // Ensure state is synced on blur
              validateJson(jsonString);
            }}
            placeholder={input_values.place_holder || 'Enter JSON...'}
            rows={input_values.rows || 8}
            style={{
              fontFamily: 'monospace',
              fontSize: '13px',
              borderColor: isValid ? undefined : '#ff4d4f',
            }}
            // Prevent form from controlling this input directly
            autoComplete="off"
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
