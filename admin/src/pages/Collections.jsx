import React, { useMemo, useState, useEffect } from 'react';
import {
    Card,
    Table,
    Button,
    Space,
    Modal,
    Form,
    Input,
    Select,
    message,
    Popconfirm,
    Tag,
    Typography,
    Row,
    Col,
    Alert,
    Drawer
} from 'antd';
import {
    PlusOutlined,
    EditOutlined,
    DeleteOutlined,
    UnorderedListOutlined,
    ExclamationCircleOutlined,
    EyeOutlined
} from '@ant-design/icons';
import { api } from '../utils/api';
import { VCJsonViewer } from '../components/ViewComponents/displays/VCJsonViewer';

const { Option } = Select;
const { TextArea } = Input;
const { Title, Text } = Typography;

const Collections = () => {
    const [collections, setCollections] = useState([]);
    const [loading, setLoading] = useState(false);
    const [fieldTypes, setFieldTypes] = useState([]);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingCollection, setEditingCollection] = useState(null);
    const [form] = Form.useForm();
    const [searchText, setSearchText] = useState('');
    const [jsonViewerVisible, setJsonViewerVisible] = useState(false);
    const [viewingJson, setViewingJson] = useState(null);

    useEffect(() => {
        loadCollections();
        loadFieldTypes();
    }, []);

    const loadFieldTypes = async () => {
        try {
            const res = await api.getFieldTypes();
            setFieldTypes(res.field_types || []);
        } catch (e) {
            console.error('Failed to load field types:', e);
        }
    };

    const loadCollections = async () => {
        try {
            setLoading(true);
            const limit = 500;
            let offset = 0;
            const all = [];
            // Fetch in chunks
            // eslint-disable-next-line no-constant-condition
            while (true) {
                const response = await api.getCollections({ limit, offset });
                const batch = response.collections || [];
                all.push(...batch);
                offset += batch.length;
                if (!response.has_more || batch.length === 0) break;
            }
            // Sort by collection_name
            all.sort((a, b) => (a.collection_name || '').localeCompare(b.collection_name || ''));
            setCollections(all);
        } catch (error) {
            message.error('Failed to load collections: ' + (error.message || 'Unknown error'));
        } finally {
            setLoading(false);
        }
    };

    const handleCreate = () => {
        setEditingCollection(null);
        form.resetFields();
        form.setFieldsValue({
            field_config_json: '{}'
        });
        setModalVisible(true);
    };

    const handleEdit = async (record) => {
        try {
            setEditingCollection(record);
            const response = await api.getCollection(record.collection_id);
            const cfg = response.field_config_json || {};
            form.setFieldsValue({
                collection_name: response.collection_name,
                collection_code: response.collection_code,
                field_type_id: response.field_type_id ?? undefined,
                field_config_json: JSON.stringify(cfg, null, 2)
            });
            setModalVisible(true);
        } catch (error) {
            message.error('Failed to load collection: ' + (error.message || 'Unknown error'));
        }
    };

    const handleDelete = async (collectionId) => {
        try {
            await api.deleteCollection(collectionId);
            message.success('Collection deleted successfully');
            loadCollections();
        } catch (error) {
            message.error('Failed to delete collection: ' + (error.message || 'Unknown error'));
        }
    };

    const handleViewJson = (record) => {
        // Ensure field_config_json is parsed if it's a string
        let fieldConfig = record.field_config_json || {};
        if (typeof fieldConfig === 'string') {
            try {
                fieldConfig = JSON.parse(fieldConfig);
            } catch (e) {
                // If parsing fails, keep as is (VCJsonViewer will handle it)
                console.warn('Failed to parse field_config_json:', e);
            }
        }

        setViewingJson({
            collection_name: record.collection_name,
            collection_code: record.collection_code,
            field_config_json: fieldConfig
        });
        setJsonViewerVisible(true);
    };

    const handleSubmit = async (values) => {
        try {
            let fieldConfigJson = {};
            if (values.field_config_json) {
                try {
                    fieldConfigJson = typeof values.field_config_json === 'string'
                        ? JSON.parse(values.field_config_json)
                        : values.field_config_json;
                } catch (e) {
                    message.error('Invalid JSON format in Field Config');
                    return;
                }
            }

            const payload = {
                collection_name: values.collection_name,
                collection_code: values.collection_code,
                field_type_id: values.field_type_id || null,
                field_config_json: fieldConfigJson
            };

            if (editingCollection) {
                await api.updateCollection(editingCollection.collection_id, payload);
                message.success('Collection updated successfully');
            } else {
                await api.createCollection({ ...payload, is_system: false });
                message.success('Collection created successfully');
            }
            setModalVisible(false);
            loadCollections();
        } catch (error) {
            message.error('Failed to save collection: ' + (error.message || 'Unknown error'));
        }
    };

    const columns = [
        {
            title: 'Collection Name',
            dataIndex: 'collection_name',
            key: 'collection_name',
            sorter: (a, b) => (a.collection_name || '').localeCompare(b.collection_name || ''),
        },
        {
            title: 'Collection Code',
            dataIndex: 'collection_code',
            key: 'collection_code',
            render: (text) => <Tag color="blue">{text}</Tag>,
        },
        {
            title: 'Field Type',
            key: 'field_type_id',
            dataIndex: 'field_type_name',
            render: (name, record) =>
                record.field_type_id
                    ? <Tag>{name || `ID ${record.field_type_id}`}</Tag>
                    : <Text type="secondary">—</Text>,
        },
        {
            title: 'Scope',
            key: 'scope',
            render: (_, record) => {
                if (record.tenant_id == null) return <Tag color="green">Global</Tag>;
                return <Tag color="orange">Tenant</Tag>;
            },
        },
        {
            title: 'is_system',
            dataIndex: 'is_system',
            key: 'is_system',
            render: (v) => (
                <Tag color={v ? 'red' : 'default'}>
                    {v ? 'System' : 'Custom'}
                </Tag>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_, record) => (
                <Space>
                    <Button
                        type="link"
                        icon={<EyeOutlined />}
                        onClick={() => handleViewJson(record)}
                    >
                        View JSON
                    </Button>
                    <Button
                        type="link"
                        icon={<EditOutlined />}
                        onClick={() => handleEdit(record)}
                        disabled={record.is_system}
                    >
                        Edit
                    </Button>
                    <Popconfirm
                        title="Are you sure you want to delete this collection?"
                        onConfirm={() => handleDelete(record.collection_id)}
                        okText="Yes"
                        cancelText="No"
                        disabled={record.is_system}
                    >
                        <Button
                            type="link"
                            danger
                            icon={<DeleteOutlined />}
                            disabled={record.is_system}
                        >
                            Delete
                        </Button>
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    const filteredCollections = useMemo(() => {
        const q = searchText.trim().toLowerCase();
        if (!q) return collections;
        return collections.filter((c) => {
            const a = (c.collection_name || '').toLowerCase();
            const b = (c.collection_code || '').toLowerCase();
            return a.includes(q) || b.includes(q);
        });
    }, [collections, searchText]);

    const validateFieldConfigJson = (_, value) => {
        if (!value || (typeof value === 'string' && value.trim() === '')) return Promise.resolve();
        try {
            const parsed = typeof value === 'string' ? JSON.parse(value) : value;
            if (typeof parsed !== 'object' || parsed === null) {
                return Promise.reject('Field config must be a valid JSON object');
            }
            return Promise.resolve();
        } catch (e) {
            return Promise.reject('Invalid JSON: ' + (e.message || 'parse error'));
        }
    };

    return (
        <div style={{ padding: '24px' }}>
            <Card>
                <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Title level={4} style={{ margin: 0 }}>
                        <UnorderedListOutlined /> Collections
                    </Title>
                    <Space>
                        <Input
                            placeholder="Search collection name / code"
                            allowClear
                            value={searchText}
                            onChange={(e) => setSearchText(e.target.value)}
                            style={{ width: 300 }}
                        />
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            onClick={handleCreate}
                        >
                            Create Collection
                        </Button>
                    </Space>
                </div>

                <Table
                    columns={columns}
                    dataSource={filteredCollections}
                    rowKey="collection_id"
                    loading={loading}
                    pagination={false}
                />
            </Card>

            {/* Create/Edit Modal */}
            <Modal
                title={editingCollection ? 'Edit Collection' : 'Create Collection'}
                open={modalVisible}
                onCancel={() => setModalVisible(false)}
                footer={null}
                width={700}
            >
                <Form
                    form={form}
                    layout="vertical"
                    onFinish={handleSubmit}
                >
                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item
                                name="collection_name"
                                label="Collection Name"
                                rules={[{ required: true, message: 'Please enter collection name' }]}
                            >
                                <Input placeholder="e.g., User Types" />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item
                                name="collection_code"
                                label="Collection Code"
                                rules={[{ required: true, message: 'Please enter collection code' }]}
                            >
                                <Input
                                    placeholder="e.g., user_types"
                                    disabled={!!editingCollection}
                                />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Form.Item name="field_type_id" label="Field Type">
                        <Select
                            allowClear
                            placeholder="Select field type (optional)"
                            showSearch
                            optionFilterProp="children"
                        >
                            {fieldTypes.map((ft) => (
                                <Option key={ft.field_type_id} value={ft.field_type_id}>
                                    {ft.type_name} ({ft.type_code})
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item
                        name="field_config_json"
                        label="Field Config (JSON)"
                        rules={[{ validator: validateFieldConfigJson }]}
                    >
                        <TextArea
                            rows={8}
                            placeholder='{"items": [{"label": "A", "value": "a"}]}'
                            style={{ fontFamily: 'monospace' }}
                        />
                    </Form.Item>

                    {editingCollection && editingCollection.is_system && (
                        <Alert
                            message="System Collection"
                            description="This is a system collection and cannot be modified."
                            type="warning"
                            showIcon
                            icon={<ExclamationCircleOutlined />}
                            style={{ marginBottom: 16 }}
                        />
                    )}

                    <Form.Item>
                        <Space>
                            <Button type="primary" htmlType="submit" disabled={editingCollection?.is_system}>
                                {editingCollection ? 'Update' : 'Create'}
                            </Button>
                            <Button onClick={() => setModalVisible(false)}>Cancel</Button>
                        </Space>
                    </Form.Item>
                </Form>
            </Modal>

            {/* JSON Viewer Drawer */}
            <Drawer
                title={`Field Config JSON: ${viewingJson?.collection_name || ''}`}
                placement="right"
                width={700}
                open={jsonViewerVisible}
                onClose={() => {
                    setJsonViewerVisible(false);
                    setViewingJson(null);
                }}
            >
                {viewingJson && (
                    <div>
                        <div style={{ marginBottom: 16 }}>
                            <Text strong>Collection Code: </Text>
                            <Tag color="blue">{viewingJson.collection_code}</Tag>
                        </div>
                        <div style={{ marginBottom: 16 }}>
                            <Text strong>Field Config JSON:</Text>
                        </div>
                        <VCJsonViewer
                            component={{
                                input_values: {
                                    data: viewingJson.field_config_json,
                                    collapse: true,
                                    copy: true,
                                    default_expanded: true,
                                    max_height: '70vh'
                                }
                            }}
                        />
                    </div>
                )}
            </Drawer>
        </div>
    );
};

export default Collections;
