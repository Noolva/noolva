import React, { useState, useEffect, useMemo } from 'react';
import {
    Card,
    Input,
    Select,
    Tag,
    Space,
    Button,
    Row,
    Col,
    Typography,
    Empty,
    Spin,
    message,
    Tooltip,
    Divider,
    Badge,
    Modal,
    Radio
} from 'antd';
import {
    SearchOutlined,
    CopyOutlined,
    StarOutlined,
    StarFilled,
    FilterOutlined,
    EyeOutlined,
    CheckOutlined
} from '@ant-design/icons';
import { VCIcon } from '../components/ViewComponents/displays/VCIcon';
import { api } from '../utils/api';

const { Option } = Select;
const { Title, Text } = Typography;
const { Meta } = Card;

const IconExplorer = () => {
    const [icons, setIcons] = useState([]);
    const [filteredIcons, setFilteredIcons] = useState([]);
    const [loading, setLoading] = useState(false);
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedCategory, setSelectedCategory] = useState(null);
    const [selectedType, setSelectedType] = useState(null);
    const [selectedTag, setSelectedTag] = useState(null);
    const [previewIcon, setPreviewIcon] = useState(null);
    const [previewSize, setPreviewSize] = useState(48);
    const [copiedIcon, setCopiedIcon] = useState(null);

    // Fetch icons from database
    useEffect(() => {
        loadIcons();
    }, []);

    // Filter icons based on search, category, type, and tag
    useEffect(() => {
        let filtered = [...icons];

        // Filter by search query
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

        // Filter by category
        if (selectedCategory) {
            filtered = filtered.filter(icon => icon.category === selectedCategory);
        }

        // Filter by type
        if (selectedType) {
            filtered = filtered.filter(icon => icon.icon_type === selectedType);
        }

        // Filter by tag
        if (selectedTag) {
            filtered = filtered.filter(icon => 
                icon.tags && icon.tags.includes(selectedTag)
            );
        }

        setFilteredIcons(filtered);
    }, [icons, searchQuery, selectedCategory, selectedType, selectedTag]);

    const loadIcons = async () => {
        try {
            setLoading(true);
            const response = await api.getIcons({ limit: 10000 });
            // Response format: { icons: [...], count: ... }
            const iconsList = response.icons || [];
            setIcons(iconsList);
        } catch (error) {
            console.error('Failed to load icons:', error);
            message.error('Failed to load icons: ' + (error.message || 'Unknown error'));
            setIcons([]);
        } finally {
            setLoading(false);
        }
    };

    // Get unique categories
    const categories = useMemo(() => {
        const cats = [...new Set(icons.map(icon => icon.category).filter(Boolean))];
        return cats.sort();
    }, [icons]);

    // Get unique tags
    const tags = useMemo(() => {
        const allTags = new Set();
        icons.forEach(icon => {
            if (icon.tags && Array.isArray(icon.tags)) {
                icon.tags.forEach(tag => allTags.add(tag));
            }
        });
        return Array.from(allTags).sort();
    }, [icons]);

    // Get icon types
    const iconTypes = ['fa', 'antd', 'smily', 'custom'];

    const handleCopy = (iconCode) => {
        navigator.clipboard.writeText(iconCode).then(() => {
            setCopiedIcon(iconCode);
            message.success(`Copied: ${iconCode}`);
            setTimeout(() => setCopiedIcon(null), 2000);
        }).catch(() => {
            message.error('Failed to copy to clipboard');
        });
    };

    const handlePreview = (icon) => {
        setPreviewIcon(icon);
    };

    const renderIcon = (icon) => {
        const component = {
            input_values: {
                icon_code: icon.icon_code,
                icon_data: icon.icon_data || null, // Pass icon_data from database
                size: 32,
                color: '#1890ff'
            }
        };

        return <VCIcon component={component} />;
    };

    const renderPreviewIcon = (icon, size) => {
        const component = {
            input_values: {
                icon_code: icon.icon_code,
                icon_data: icon.icon_data || null, // Pass icon_data from database
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
        setSelectedTag(null);
    };

    const hasActiveFilters = searchQuery || selectedCategory || selectedType || selectedTag;

    return (
        <div style={{ padding: '24px', minHeight: '100vh', background: '#f0f2f5' }}>
            <Card style={{ marginBottom: 24 }}>
                <Title level={2} style={{ marginBottom: 24, marginTop: 0 }}>
                    <StarOutlined /> Icon Explorer
                </Title>
                
                {/* Search and Filters */}
                <Space direction="vertical" size="large" style={{ width: '100%' }}>
                    <Row gutter={16}>
                        <Col xs={24} sm={12} md={8}>
                            <Input
                                placeholder="Search icons by name, code, or tag..."
                                prefix={<SearchOutlined />}
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                allowClear
                                size="large"
                            />
                        </Col>
                        <Col xs={24} sm={12} md={4}>
                            <Select
                                placeholder="All Categories"
                                value={selectedCategory}
                                onChange={setSelectedCategory}
                                allowClear
                                size="large"
                                style={{ width: '100%' }}
                            >
                                {categories.map(cat => (
                                    <Option key={cat} value={cat}>{cat}</Option>
                                ))}
                            </Select>
                        </Col>
                        <Col xs={24} sm={12} md={4}>
                            <Select
                                placeholder="All Types"
                                value={selectedType}
                                onChange={setSelectedType}
                                allowClear
                                size="large"
                                style={{ width: '100%' }}
                            >
                                {iconTypes.map(type => (
                                    <Option key={type} value={type}>
                                        {type.toUpperCase()}
                                    </Option>
                                ))}
                            </Select>
                        </Col>
                        <Col xs={24} sm={12} md={4}>
                            <Select
                                placeholder="All Tags"
                                value={selectedTag}
                                onChange={setSelectedTag}
                                allowClear
                                size="large"
                                style={{ width: '100%' }}
                            >
                                {tags.slice(0, 50).map(tag => (
                                    <Option key={tag} value={tag}>{tag}</Option>
                                ))}
                            </Select>
                        </Col>
                        <Col xs={24} sm={12} md={4}>
                            {hasActiveFilters && (
                                <Button
                                    onClick={clearFilters}
                                    icon={<FilterOutlined />}
                                    size="large"
                                    style={{ width: '100%' }}
                                >
                                    Clear Filters
                                </Button>
                            )}
                        </Col>
                    </Row>

                    {/* Stats */}
                    <Row>
                        <Col span={24}>
                            <Space>
                                <Text type="secondary">
                                    Showing {filteredIcons.length} of {icons.length} icons
                                </Text>
                                {hasActiveFilters && (
                                    <>
                                        {selectedCategory && (
                                            <Tag closable onClose={() => setSelectedCategory(null)}>
                                                Category: {selectedCategory}
                                            </Tag>
                                        )}
                                        {selectedType && (
                                            <Tag closable onClose={() => setSelectedType(null)}>
                                                Type: {selectedType.toUpperCase()}
                                            </Tag>
                                        )}
                                        {selectedTag && (
                                            <Tag closable onClose={() => setSelectedTag(null)}>
                                                Tag: {selectedTag}
                                            </Tag>
                                        )}
                                    </>
                                )}
                            </Space>
                        </Col>
                    </Row>
                </Space>
            </Card>

            {/* Icons Grid */}
            {loading ? (
                <Card>
                    <div style={{ 
                        textAlign: 'center', 
                        padding: '100px 20px',
                        minHeight: '400px',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center'
                    }}>
                        <Spin size="large" style={{ marginBottom: 24 }} />
                        <Title level={4} type="secondary" style={{ marginTop: 0 }}>
                            Loading icons...
                        </Title>
                        <Text type="secondary">
                            Please wait while we fetch icons from the database
                        </Text>
                    </div>
                </Card>
            ) : filteredIcons.length === 0 ? (
                <Card>
                    <Empty
                        description={
                            <span>
                                {icons.length === 0 
                                    ? 'No icons found in database' 
                                    : 'No icons match your filters'}
                            </span>
                        }
                    />
                </Card>
            ) : (
                <Row gutter={[16, 16]}>
                    {filteredIcons.map(icon => (
                        <Col xs={12} sm={8} md={6} lg={4} xl={3} key={icon.icon_id || icon.icon_code}>
                            <Card
                                hoverable
                                style={{
                                    textAlign: 'center',
                                    height: '100%',
                                    border: copiedIcon === icon.icon_code ? '2px solid #52c41a' : undefined
                                }}
                                bodyStyle={{ padding: '16px 12px' }}
                                actions={[
                                    <Tooltip title="Copy icon code">
                                        <CopyOutlined
                                            onClick={() => handleCopy(icon.icon_code)}
                                            style={{ fontSize: '16px', color: copiedIcon === icon.icon_code ? '#52c41a' : undefined }}
                                        />
                                    </Tooltip>,
                                    <Tooltip title="Preview">
                                        <EyeOutlined
                                            onClick={() => handlePreview(icon)}
                                            style={{ fontSize: '16px' }}
                                        />
                                    </Tooltip>
                                ]}
                            >
                                <div style={{ 
                                    fontSize: '32px', 
                                    marginBottom: '12px',
                                    minHeight: '40px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center'
                                }}>
                                    {renderIcon(icon)}
                                </div>
                                <Text strong style={{ display: 'block', fontSize: '12px', marginBottom: '4px' }}>
                                    {icon.icon_name}
                                </Text>
                                <Text type="secondary" style={{ fontSize: '11px', display: 'block', marginBottom: '8px' }}>
                                    {icon.icon_code}
                                </Text>
                                <Space size={[4, 4]} wrap style={{ justifyContent: 'center', marginTop: '8px' }}>
                                    <Tag size="small" color="blue">{icon.icon_type}</Tag>
                                    <Tag size="small">{icon.category}</Tag>
                                    {icon.is_popular && (
                                        <Badge dot color="gold">
                                            <StarFilled style={{ fontSize: '10px' }} />
                                        </Badge>
                                    )}
                                </Space>
                            </Card>
                        </Col>
                    ))}
                </Row>
            )}

            {/* Preview Modal */}
            <Modal
                title={`Icon Preview: ${previewIcon?.icon_name}`}
                open={!!previewIcon}
                onCancel={() => setPreviewIcon(null)}
                footer={[
                    <Button key="copy" icon={<CopyOutlined />} onClick={() => handleCopy(previewIcon?.icon_code)}>
                        Copy Code
                    </Button>,
                    <Button key="close" onClick={() => setPreviewIcon(null)}>
                        Close
                    </Button>
                ]}
                width={500}
            >
                {previewIcon && (
                    <div style={{ textAlign: 'center', padding: '20px' }}>
                        <div style={{ marginBottom: 24 }}>
                            <div style={{ fontSize: '80px', marginBottom: 16 }}>
                                {renderPreviewIcon(previewIcon, 80)}
                            </div>
                            <Title level={4}>{previewIcon.icon_name}</Title>
                            <Text code style={{ fontSize: '14px' }}>{previewIcon.icon_code}</Text>
                        </div>

                        <Divider />

                        <div style={{ marginBottom: 16 }}>
                            <Text strong>Size: </Text>
                            <Radio.Group 
                                value={previewSize} 
                                onChange={(e) => setPreviewSize(e.target.value)}
                                style={{ marginLeft: 8 }}
                            >
                                <Radio.Button value={16}>16px</Radio.Button>
                                <Radio.Button value={24}>24px</Radio.Button>
                                <Radio.Button value={32}>32px</Radio.Button>
                                <Radio.Button value={48}>48px</Radio.Button>
                                <Radio.Button value={64}>64px</Radio.Button>
                            </Radio.Group>
                        </div>

                        <div style={{ fontSize: `${previewSize}px`, margin: '20px 0' }}>
                            {renderPreviewIcon(previewIcon, previewSize)}
                        </div>

                        <Divider />

                        <Space direction="vertical" style={{ width: '100%', textAlign: 'left' }}>
                            <div>
                                <Text strong>Type: </Text>
                                <Tag color="blue">{previewIcon.icon_type}</Tag>
                            </div>
                            <div>
                                <Text strong>Category: </Text>
                                <Tag>{previewIcon.category}</Tag>
                            </div>
                            {previewIcon.description && (
                                <div>
                                    <Text strong>Description: </Text>
                                    <Text>{previewIcon.description}</Text>
                                </div>
                            )}
                            {previewIcon.tags && previewIcon.tags.length > 0 && (
                                <div>
                                    <Text strong>Tags: </Text>
                                    {previewIcon.tags.map(tag => (
                                        <Tag key={tag}>{tag}</Tag>
                                    ))}
                                </div>
                            )}
                        </Space>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default IconExplorer;
