import React, { useState, useEffect } from "react";
import { Form, Modal, Input, Select, Row, Col, Card, Tag, Space, Empty, Spin, Button, Tooltip, Typography, Divider, Radio } from "antd";
import { SearchOutlined, StarOutlined, EyeOutlined, FilterOutlined, CheckOutlined } from "@ant-design/icons";
import { VCIcon } from "../displays/VCIcon";
import { api } from "../../../utils/api";

const { Option } = Select;
const { Text } = Typography;

export function VCIconChooser({ component }) {
  const input_values = component?.input_values || {};
  const [modalVisible, setModalVisible] = useState(false);
  const [icons, setIcons] = useState([]);
  const [filteredIcons, setFilteredIcons] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [selectedType, setSelectedType] = useState(null);
  const [categories, setCategories] = useState([]);
  const [selectedIcon, setSelectedIcon] = useState(null);
  const [previewSize, setPreviewSize] = useState(32);
  const form = Form.useFormInstance();

  // Get current value from form
  const fieldValue = Form.useWatch(input_values.name, form);

  // Load icons when modal opens
  useEffect(() => {
    if (modalVisible) {
      loadIcons();
      loadCategories();
    }
  }, [modalVisible]);

  // Set selected icon from form value
  useEffect(() => {
    if (fieldValue && icons.length > 0) {
      const icon = icons.find(i => i.icon_code === fieldValue);
      setSelectedIcon(icon || null);
    } else {
      setSelectedIcon(null);
    }
  }, [fieldValue, icons]);

  // Filter icons
  useEffect(() => {
    let filtered = [...icons];

    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(icon =>
        icon.icon_name?.toLowerCase().includes(query) ||
        icon.icon_code?.toLowerCase().includes(query) ||
        icon.description?.toLowerCase().includes(query) ||
        icon.category?.toLowerCase().includes(query) ||
        (icon.tags && icon.tags.some(tag => tag.toLowerCase().includes(query)))
      );
    }

    if (selectedCategory) {
      filtered = filtered.filter(icon => icon.category === selectedCategory);
    }

    if (selectedType) {
      filtered = filtered.filter(icon => icon.icon_type === selectedType);
    }

    setFilteredIcons(filtered);
  }, [icons, searchQuery, selectedCategory, selectedType]);

  const loadIcons = async () => {
    try {
      setLoading(true);
      const response = await api.getIcons({ limit: 10000 });
      const iconsList = response.icons || [];
      setIcons(iconsList);

      // Set selected icon if value exists
      if (fieldValue) {
        const icon = iconsList.find(i => i.icon_code === fieldValue);
        setSelectedIcon(icon || null);
      }
    } catch (error) {
      console.error('Failed to load icons:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadCategories = async () => {
    try {
      const response = await api.getIconCategories();
      setCategories(response.categories || []);
    } catch (error) {
      console.error('Failed to load categories:', error);
    }
  };

  const handleIconSelect = (icon) => {
    setSelectedIcon(icon);
  };

  const handleConfirm = () => {
    if (selectedIcon) {
      form.setFieldValue(input_values.name, selectedIcon.icon_code);
      setModalVisible(false);
      // Reset filters
      setSearchQuery('');
      setSelectedCategory(null);
      setSelectedType(null);
    }
  };

  const handleClear = () => {
    form.setFieldValue(input_values.name, null);
    setSelectedIcon(null);
    setModalVisible(false);
  };

  const renderIcon = (icon) => {
    const component = {
      input_values: {
        icon_code: icon.icon_code,
        icon_data: icon.icon_data || null,
        size: 24,
        color: '#1890ff'
      }
    };
    return <VCIcon component={component} />;
  };

  const renderPreviewIcon = (icon, size) => {
    const component = {
      input_values: {
        icon_code: icon.icon_code,
        icon_data: icon.icon_data || null,
        size: size,
        color: '#1890ff'
      }
    };
    return <VCIcon component={component} />;
  };

  const clearFilters = () => {
    setSearchQuery('');
    setSelectedCategory(null);
    setSelectedType(null);
  };

  const hasActiveFilters = searchQuery || selectedCategory || selectedType;

  return (
    <>
      <Form.Item
        name={input_values.name}
        label={input_values.label}
        rules={input_values.is_required ? [{ required: true, message: `${input_values.label} is required` }] : []}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
            {selectedIcon ? (
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '8px 12px',
                border: '1px solid #d9d9d9',
                borderRadius: '4px',
                background: '#fafafa'
              }}>
                <div style={{ fontSize: '24px' }}>
                  {renderIcon(selectedIcon)}
                </div>
                <div>
                  <Text strong style={{ fontSize: '14px', display: 'block' }}>
                    {selectedIcon.icon_name}
                  </Text>
                  <Text type="secondary" style={{ fontSize: '12px' }}>
                    {selectedIcon.icon_code}
                  </Text>
                </div>
                <Tag size="small" color="blue">{selectedIcon.icon_type}</Tag>
              </div>
            ) : (
              <Text type="secondary">No icon selected</Text>
            )}
          </div>
          <Button
            type={selectedIcon ? "default" : "primary"}
            icon={<StarOutlined />}
            onClick={() => setModalVisible(true)}
          >
            {selectedIcon ? 'Change Icon' : 'Choose Icon'}
          </Button>
          {selectedIcon && (
            <Button
              type="link"
              danger
              onClick={handleClear}
              style={{ marginLeft: '8px' }}
            >
              Clear
            </Button>
          )}
        </div>
      </Form.Item>

      <Modal
        title="Choose Icon"
        open={modalVisible}
        onCancel={() => setModalVisible(false)}
        footer={[
          <Button key="clear" onClick={handleClear}>
            Clear
          </Button>,
          <Button key="cancel" onClick={() => setModalVisible(false)}>
            Cancel
          </Button>,
          <Button
            key="confirm"
            type="primary"
            icon={<CheckOutlined />}
            onClick={handleConfirm}
            disabled={!selectedIcon}
          >
            Confirm
          </Button>
        ]}
        width={900}
        style={{ top: 20 }}
      >
        <div style={{ marginBottom: 16 }}>
          {/* Search and Filters */}
          <Space direction="vertical" size="middle" style={{ width: '100%' }}>
            <Row gutter={8}>
              <Col span={10}>
                <Input
                  placeholder="Search icons..."
                  prefix={<SearchOutlined />}
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  allowClear
                />
              </Col>
              <Col span={7}>
                <Select
                  placeholder="All Categories"
                  value={selectedCategory}
                  onChange={setSelectedCategory}
                  allowClear
                  style={{ width: '100%' }}
                >
                  {categories.map(cat => (
                    <Option key={cat} value={cat}>{cat}</Option>
                  ))}
                </Select>
              </Col>
              <Col span={7}>
                <Select
                  placeholder="All Types"
                  value={selectedType}
                  onChange={setSelectedType}
                  allowClear
                  style={{ width: '100%' }}
                >
                  <Option value="fa">FA</Option>
                  <Option value="antd">AntD</Option>
                  <Option value="smily">Smily</Option>
                  <Option value="custom">Custom</Option>
                </Select>
              </Col>
            </Row>
            {hasActiveFilters && (
              <Button
                size="small"
                onClick={clearFilters}
                icon={<FilterOutlined />}
              >
                Clear Filters
              </Button>
            )}
          </Space>
        </div>

        <Divider />

        {/* Icons Grid */}
        <div style={{ maxHeight: '500px', overflowY: 'auto', border: '1px solid #f0f0f0', borderRadius: '4px', padding: '12px' }}>
          {loading ? (
            <div style={{ textAlign: 'center', padding: '40px' }}>
              <Spin size="large" />
              <div style={{ marginTop: 16 }}>
                <Text type="secondary">Loading icons...</Text>
              </div>
            </div>
          ) : filteredIcons.length === 0 ? (
            <Empty description="No icons found" />
          ) : (
            <Row gutter={[8, 8]}>
              {filteredIcons.map(icon => {
                const isSelected = selectedIcon?.icon_code === icon.icon_code;
                return (
                  <Col xs={8} sm={6} md={4} lg={3} key={icon.icon_id || icon.icon_code}>
                    <Card
                      hoverable
                      size="small"
                      style={{
                        textAlign: 'center',
                        cursor: 'pointer',
                        border: isSelected ? '2px solid #1890ff' : '1px solid #d9d9d9',
                        background: isSelected ? '#e6f7ff' : undefined
                      }}
                      bodyStyle={{ padding: '8px' }}
                      onClick={() => handleIconSelect(icon)}
                    >
                      <div style={{ fontSize: '24px', marginBottom: '4px', minHeight: '28px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {renderIcon(icon)}
                      </div>
                      <Text
                        ellipsis
                        style={{
                          fontSize: '11px',
                          display: 'block',
                          color: isSelected ? '#1890ff' : undefined
                        }}
                      >
                        {icon.icon_name}
                      </Text>
                      <Text
                        type="secondary"
                        ellipsis
                        style={{ fontSize: '10px', display: 'block' }}
                      >
                        {icon.icon_code}
                      </Text>
                    </Card>
                  </Col>
                );
              })}
            </Row>
          )}
        </div>

        {/* Preview Section */}
        {selectedIcon && (
          <>
            <Divider />
            <div style={{ padding: '16px', background: '#fafafa', borderRadius: '4px' }}>
              <Text strong style={{ display: 'block', marginBottom: '12px' }}>
                Preview: {selectedIcon.icon_name}
              </Text>
              <Space direction="vertical" style={{ width: '100%' }}>
                <div>
                  <Text strong>Size: </Text>
                  <Radio.Group
                    value={previewSize}
                    onChange={(e) => setPreviewSize(e.target.value)}
                    size="small"
                  >
                    <Radio.Button value={16}>16px</Radio.Button>
                    <Radio.Button value={24}>24px</Radio.Button>
                    <Radio.Button value={32}>32px</Radio.Button>
                    <Radio.Button value={48}>48px</Radio.Button>
                    <Radio.Button value={64}>64px</Radio.Button>
                  </Radio.Group>
                </div>
                <div style={{ fontSize: `${previewSize}px`, textAlign: 'center', padding: '16px' }}>
                  {renderPreviewIcon(selectedIcon, previewSize)}
                </div>
                <div>
                  <Text code>{selectedIcon.icon_code}</Text>
                </div>
              </Space>
            </div>
          </>
        )}
      </Modal>
    </>
  );
}
