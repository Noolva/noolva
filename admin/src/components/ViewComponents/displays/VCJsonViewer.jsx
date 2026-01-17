import React, { useState, useCallback } from "react";
import { Card, Button, Space, message, Tooltip } from "antd";
import { CopyOutlined, ExpandOutlined, CompressOutlined } from "@ant-design/icons";

export function VCJsonViewer({ component }) {
  const input_values = component?.input_values || {};
  const jsonData = input_values.data || input_values.value || input_values.default_value || {};
  const showCollapse = input_values.collapse !== false; // Default true
  const showCopy = input_values.copy !== false; // Default true
  const defaultExpanded = input_values.default_expanded || false;
  const maxHeight = input_values.max_height || '200px';

  const [expanded, setExpanded] = useState(defaultExpanded);
  const [copied, setCopied] = useState(false);
  const [collapsedPaths, setCollapsedPaths] = useState(new Set());

  // Parse JSON if it's a string
  let parsedData;
  try {
    parsedData = typeof jsonData === 'string' ? JSON.parse(jsonData) : jsonData;
  } catch (e) {
    parsedData = { error: "Invalid JSON", raw: jsonData };
  }

  const jsonString = JSON.stringify(parsedData, null, 2);

  const handleCopy = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(jsonString);
      setCopied(true);
      message.success('JSON copied to clipboard');
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      // Fallback for older browsers
      const textArea = document.createElement('textarea');
      textArea.value = jsonString;
      textArea.style.position = 'fixed';
      textArea.style.opacity = '0';
      document.body.appendChild(textArea);
      textArea.select();
      try {
        document.execCommand('copy');
        setCopied(true);
        message.success('JSON copied to clipboard');
        setTimeout(() => setCopied(false), 2000);
      } catch (e) {
        message.error('Failed to copy JSON');
      }
      document.body.removeChild(textArea);
    }
  }, [jsonString]);

  const toggleExpand = useCallback(() => {
    setExpanded(!expanded);
  }, [expanded]);

  const togglePath = useCallback((path) => {
    setCollapsedPaths(prev => {
      const next = new Set(prev);
      if (next.has(path)) {
        next.delete(path);
      } else {
        next.add(path);
      }
      return next;
    });
  }, []);

  const renderJsonValue = useCallback((value, depth = 0, path = '') => {
    if (value === null) {
      return <span style={{ color: '#999' }}>null</span>;
    }
    if (value === undefined) {
      return <span style={{ color: '#999' }}>undefined</span>;
    }
    if (typeof value === 'string') {
      return <span style={{ color: '#50a14f' }}>"{value}"</span>;
    }
    if (typeof value === 'number') {
      return <span style={{ color: '#986801' }}>{value}</span>;
    }
    if (typeof value === 'boolean') {
      return <span style={{ color: '#a626a4' }}>{String(value)}</span>;
    }
    if (Array.isArray(value)) {
      if (value.length === 0) {
        return <span style={{ color: '#999' }}>[]</span>;
      }
      const currentPath = path ? `${path}[]` : '[]';
      const isCollapsed = collapsedPaths.has(currentPath);
      
      return (
        <div style={{ marginLeft: depth * 20 }}>
          <span 
            onClick={() => togglePath(currentPath)}
            style={{ 
              color: '#e45649', 
              cursor: 'pointer',
              userSelect: 'none',
              marginRight: '4px'
            }}
          >
            {isCollapsed ? '▶' : '▼'}
          </span>
          <span style={{ color: '#e45649' }}>[</span>
          {!isCollapsed && (
            <>
              {value.map((item, idx) => {
                const itemPath = `${currentPath}[${idx}]`;
                return (
                  <div key={idx} style={{ marginLeft: 20 }}>
                    {renderJsonValue(item, depth + 1, itemPath)}
                    {idx < value.length - 1 && <span style={{ color: '#e45649' }}>,</span>}
                  </div>
                );
              })}
            </>
          )}
          {isCollapsed && <span style={{ color: '#999', marginLeft: '8px' }}>... {value.length} items</span>}
          <span style={{ color: '#e45649' }}>]</span>
        </div>
      );
    }
    if (typeof value === 'object') {
      const keys = Object.keys(value);
      if (keys.length === 0) {
        return <span style={{ color: '#999' }}>{'{}'}</span>;
      }
      const currentPath = path || '{}';
      const isCollapsed = collapsedPaths.has(currentPath);
      
      return (
        <div style={{ marginLeft: depth * 20 }}>
          <span 
            onClick={() => togglePath(currentPath)}
            style={{ 
              color: '#e45649', 
              cursor: 'pointer',
              userSelect: 'none',
              marginRight: '4px'
            }}
          >
            {isCollapsed ? '▶' : '▼'}
          </span>
          <span style={{ color: '#e45649' }}>{'{'}</span>
          {!isCollapsed && (
            <>
              {keys.map((key, idx) => {
                const keyPath = path ? `${path}.${key}` : key;
                return (
                  <div key={key} style={{ marginLeft: 20 }}>
                    <span style={{ color: '#986801' }}>"{key}"</span>
                    <span style={{ color: '#e45649' }}>: </span>
                    {renderJsonValue(value[key], depth + 1, keyPath)}
                    {idx < keys.length - 1 && <span style={{ color: '#e45649' }}>,</span>}
                  </div>
                );
              })}
            </>
          )}
          {isCollapsed && <span style={{ color: '#999', marginLeft: '8px' }}>... {keys.length} keys</span>}
          <span style={{ color: '#e45649' }}>{'}'}</span>
        </div>
      );
    }
    return <span>{String(value)}</span>;
  }, [collapsedPaths, togglePath]);

  const containerMaxHeight = showCollapse && !expanded ? maxHeight : 'none';
  const containerOverflow = showCollapse && !expanded ? 'auto' : 'visible';

  return (
    <div>
      {(showCopy || showCollapse) && (
        <div style={{ marginBottom: '8px', display: 'flex', justifyContent: 'flex-end' }}>
          <Space>
            {showCollapse && (
              <Tooltip title={expanded ? 'Collapse' : 'Expand'}>
                <Button
                  icon={expanded ? <CompressOutlined /> : <ExpandOutlined />}
                  onClick={toggleExpand}
                  size="small"
                >
                  {expanded ? 'Collapse' : 'Expand'}
                </Button>
              </Tooltip>
            )}
            {showCopy && (
              <Tooltip title="Copy JSON">
                <Button
                  icon={<CopyOutlined />}
                  onClick={handleCopy}
                  size="small"
                  type={copied ? 'primary' : 'default'}
                >
                  {copied ? 'Copied!' : 'Copy'}
                </Button>
              </Tooltip>
            )}
          </Space>
        </div>
      )}
      <Card
        styles={{
          body: {
            padding: '12px',
            backgroundColor: '#fafafa',
            maxHeight: containerMaxHeight,
            overflow: containerOverflow,
            fontFamily: 'monospace',
            fontSize: '13px',
            lineHeight: '1.6',
          }
        }}
        style={{ marginBottom: '16px' }}
      >
        <pre style={{ margin: 0, whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
          {renderJsonValue(parsedData)}
        </pre>
      </Card>
    </div>
  );
}
