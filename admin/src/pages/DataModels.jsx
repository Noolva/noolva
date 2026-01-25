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
    Switch,
    message,
    Popconfirm,
    Drawer,
    Tag,
    Typography,
    Row,
    Col,
    Tabs,
    Alert,
    Image
} from 'antd';
import {
    PlusOutlined,
    EditOutlined,
    DeleteOutlined,
    DatabaseOutlined,
    FieldTimeOutlined,
    OrderedListOutlined,
    ExclamationCircleOutlined
} from '@ant-design/icons';
import { api } from '../utils/api';
import { VCDragSortList } from '../components/ViewComponents/displays/VCDragSortList';
import { FieldConfigJsonEditor } from '../components/ViewComponents/inputs/FieldConfigJsonEditor';

const { Option } = Select;
const { TextArea } = Input;
const { Title, Text } = Typography;
const { TabPane } = Tabs;

const DataModels = () => {
    const [dataModels, setDataModels] = useState([]);
    const [loading, setLoading] = useState(false);
    const [fieldTypes, setFieldTypes] = useState([]);
    const [modalVisible, setModalVisible] = useState(false);
    const [fieldDrawerVisible, setFieldDrawerVisible] = useState(false);
    const [fieldEditorDrawerVisible, setFieldEditorDrawerVisible] = useState(false);
    const [fieldOrderingDrawerVisible, setFieldOrderingDrawerVisible] = useState(false);
    const [editingModel, setEditingModel] = useState(null);
    const [selectedModel, setSelectedModel] = useState(null);
    const [fields, setFields] = useState([]);
    const [orderingItems, setOrderingItems] = useState([]);
    const [editingField, setEditingField] = useState(null);
    const [form] = Form.useForm();
    const [fieldForm] = Form.useForm();
    const [confirmModalVisible, setConfirmModalVisible] = useState(false);
    const [pendingChanges, setPendingChanges] = useState(null);
    const [searchText, setSearchText] = useState('');
    const [fieldConfigJson, setFieldConfigJson] = useState({});
    const [selectedFieldType, setSelectedFieldType] = useState(null);

    // Helper function to get asset URL
    const getAssetUrl = (assetPath) => {
        if (!assetPath) return null;
        const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:9001';
        if (assetPath.startsWith('http://') || assetPath.startsWith('https://')) {
            return assetPath;
        }
        // For assets in api/assets folder, they're served from /assets/ path
        return `${apiBaseUrl}/assets/${assetPath}`;
    };

    useEffect(() => {
        loadDataModels();
        loadFieldTypes();
    }, []);

    const loadDataModels = async () => {
        try {
            setLoading(true);
            const limit = 500;
            let offset = 0;
            const all = [];
            // Fetch in chunks (500 max per request)
            // eslint-disable-next-line no-constant-condition
            while (true) {
                const response = await api.getDataModels({ limit, offset });
                const batch = response.data_models || [];
                all.push(...batch);
                offset += batch.length;
                if (!response.has_more || batch.length === 0) break;
            }
            // Default sort by model_name client-side (so API can avoid expensive DB sort)
            all.sort((a, b) => (a.model_name || '').localeCompare(b.model_name || ''));
            setDataModels(all);
        } catch (error) {
            message.error('Failed to load data models: ' + (error.message || 'Unknown error'));
        } finally {
            setLoading(false);
        }
    };

    const loadFieldTypes = async () => {
        try {
            const response = await api.getFieldTypes();
            setFieldTypes(response.field_types || []);
        } catch (error) {
            console.error('Failed to load field types:', error);
        }
    };

    const loadModelFields = async (modelId) => {
        try {
            const response = await api.getDataModel(modelId);
            setFields(response.fields || []);
        } catch (error) {
            message.error('Failed to load fields: ' + (error.message || 'Unknown error'));
        }
    };

    const handleCreate = () => {
        setEditingModel(null);
        form.resetFields();
        setModalVisible(true);
    };

    const handleEdit = async (record) => {
        try {
            setEditingModel(record);
            const response = await api.getDataModel(record.model_id);
            form.setFieldsValue({
                model_name: response.model_name,
                display_name: response.display_name,
                table_name: response.table_name,
                table_alias: response.table_alias,
                model_scope: response.model_scope,
                is_public: response.is_public,
                is_system_model: response.is_system_model,
                is_active: response.is_active,
                description: response.description,
            });
            setFields(response.fields || []);
            setModalVisible(true);
        } catch (error) {
            message.error('Failed to load data model: ' + (error.message || 'Unknown error'));
        }
    };

    const handleDelete = async (modelId) => {
        try {
            await api.deleteDataModel(modelId, false);
            message.success('Data model deleted successfully');
            loadDataModels();
        } catch (error) {
            message.error('Failed to delete data model: ' + (error.message || 'Unknown error'));
        }
    };

    const handleSubmit = async (values) => {
        try {
            if (editingModel) {
                // Check if table_name changed
                if (values.table_name !== editingModel.table_name) {
                    setPendingChanges({
                        type: 'update',
                        modelId: editingModel.model_id,
                        oldTableName: editingModel.table_name,
                        newTableName: values.table_name,
                        values
                    });
                    setConfirmModalVisible(true);
                    return;
                }

                await api.updateDataModel(editingModel.model_id, values);
                message.success('Data model updated successfully');
            } else {
                await api.createDataModel(values);
                message.success('Data model created successfully');
            }
            setModalVisible(false);
            loadDataModels();
        } catch (error) {
            message.error('Failed to save data model: ' + (error.message || 'Unknown error'));
        }
    };

    const handleConfirmChanges = async () => {
        try {
            if (pendingChanges.type === 'update') {
                await api.updateDataModel(pendingChanges.modelId, pendingChanges.values);
                message.success('Data model updated successfully. Table renamed.');
                setModalVisible(false);
                loadDataModels();
            } else if (pendingChanges.type === 'add_field') {
                await api.addDataModelField(pendingChanges.modelId, pendingChanges.values);
                message.success('Field added successfully. Table modified.');
                await loadModelFields(pendingChanges.modelId);
                fieldForm.resetFields();
                setFieldEditorDrawerVisible(false);
                setEditingField(null);
            } else if (pendingChanges.type === 'delete_field') {
                await api.deleteDataModelField(
                    pendingChanges.modelId,
                    pendingChanges.fieldId,
                    true // delete_column = true
                );
                message.success('Field deleted successfully. Column removed from table.');
                await loadModelFields(pendingChanges.modelId);
            }
            setConfirmModalVisible(false);
            setPendingChanges(null);
        } catch (error) {
            message.error('Failed to apply changes: ' + (error.message || 'Unknown error'));
        }
    };

    const handleViewFields = async (record) => {
        setSelectedModel(record);
        await loadModelFields(record.model_id);
        setFieldDrawerVisible(true);
    };

    const openAddFieldDrawer = () => {
        setEditingField(null);
        setSelectedFieldType(null);
        setFieldConfigJson({});
        fieldForm.resetFields();
        fieldForm.setFieldsValue({
            encryption_method: 'none',
            is_required: false,
            is_unique: false,
            is_primary_key: false,
        });
        setFieldEditorDrawerVisible(true);
    };

    const handleFieldSubmit = async (values) => {
        try {
            if (!selectedModel) return;

            // Include field_config_json in values
            const submitValues = {
                ...values,
                field_config_json: Object.keys(fieldConfigJson).length > 0 ? fieldConfigJson : {}
            };

            if (editingField) {
                await api.updateDataModelField(selectedModel.model_id, editingField.field_id, submitValues);
                message.success('Field updated successfully');
                await loadModelFields(selectedModel.model_id);
                setFieldEditorDrawerVisible(false);
                setEditingField(null);
                setFieldConfigJson({});
                return;
            }

            // Adding a field will modify the table -> confirm
            setPendingChanges({ type: 'add_field', modelId: selectedModel.model_id, values: submitValues });
            setConfirmModalVisible(true);
        } catch (error) {
            message.error('Failed to add field: ' + (error.message || 'Unknown error'));
        }
    };

    // Generate SQL preview based on field type and config
    const generateSQLPreview = () => {
        if (!selectedFieldType || !fieldForm.getFieldValue('field_name')) {
            return null;
        }

        const fieldName = fieldForm.getFieldValue('field_name');
        const isRequired = fieldForm.getFieldValue('is_required');
        const defaultValue = fieldForm.getFieldValue('default_value');
        const dbType = selectedFieldType.actual_db_type;
        const tableName = selectedModel?.table_name || 'table_name';

        let colDef = `"${fieldName}"`;

        // Handle VARCHAR with max_length
        if (dbType === 'VARCHAR') {
            const maxLength = fieldConfigJson.max_length || 255;
            colDef += ` VARCHAR(${maxLength})`;
        } else if (dbType === 'NUMERIC') {
            // Handle NUMERIC with precision and scale
            const precision = fieldConfigJson.maximum_digits || fieldConfigJson.precision || 10;
            const scale = fieldConfigJson.allowed_decimal_places || fieldConfigJson.scale || 2;
            colDef += ` NUMERIC(${precision}, ${scale})`;
        } else {
            colDef += ` ${dbType}`;
        }

        if (isRequired && !fieldForm.getFieldValue('is_primary_key')) {
            colDef += ' NOT NULL';
        }

        if (defaultValue) {
            colDef += ` DEFAULT '${defaultValue}'`;
        }

        if (editingField) {
            return `ALTER TABLE public."${tableName}" ALTER COLUMN ${colDef};`;
        } else {
            return `ALTER TABLE public."${tableName}" ADD COLUMN ${colDef};`;
        }
    };

    const handleDeleteField = async (fieldId, fieldName) => {
        try {
            if (!selectedModel) return;

            setPendingChanges({
                type: 'delete_field',
                modelId: selectedModel.model_id,
                fieldId,
                fieldName
            });
            setConfirmModalVisible(true);
        } catch (error) {
            message.error('Failed to delete field: ' + (error.message || 'Unknown error'));
        }
    };

    const handleEditField = (record) => {
        setEditingField(record);
        fieldForm.resetFields();
        const fieldType = fieldTypes.find(ft => ft.field_type_id === record.field_type_id) || {
            field_type_id: record.field_type_id,
            type_name: record.type_name,
            type_code: record.type_code,
            actual_db_type: record.actual_db_type,
            input_type_image: record.input_type_image,
            default_props_json: {}
        };
        setSelectedFieldType(fieldType);
        
        // Parse field_config_json
        let config = {};
        if (record.field_config_json) {
            try {
                config = typeof record.field_config_json === 'string' 
                    ? JSON.parse(record.field_config_json) 
                    : record.field_config_json;
            } catch (e) {
                console.error('Failed to parse field_config_json:', e);
            }
        }
        setFieldConfigJson(config);
        
        fieldForm.setFieldsValue({
            field_name: record.field_name,
            display_name: record.display_name,
            field_type_id: record.field_type_id,
            is_required: record.is_required,
            is_unique: record.is_unique,
            is_primary_key: record.is_primary_key,
            default_value: record.default_value,
            encryption_method: record.encryption_method || 'none',
            ui_component: record.ui_component,
        });
        setFieldEditorDrawerVisible(true);
    };

    const openOrderingDrawer = () => {
        const sorted = [...fields].sort((a, b) => (a.order_no || 0) - (b.order_no || 0));
        setOrderingItems(
            sorted.map((f) => ({
                id: f.field_id,
                primary: f.display_name || f.field_name,
                secondary: f.field_name,
            }))
        );
        setFieldOrderingDrawerVisible(true);
    };

    const saveOrdering = async () => {
        try {
            if (!selectedModel) return;
            const fieldIds = orderingItems.map((i) => i.id);
            await api.reorderDataModelFields(selectedModel.model_id, fieldIds);
            message.success('Field ordering updated');
            await loadModelFields(selectedModel.model_id);
            setFieldOrderingDrawerVisible(false);
        } catch (error) {
            message.error('Failed to update ordering: ' + (error.message || 'Unknown error'));
        }
    };

    const columns = [
        {
            title: 'Model Name',
            dataIndex: 'model_name',
            key: 'model_name',
            sorter: (a, b) => a.model_name.localeCompare(b.model_name),
        },
        {
            title: 'Display Name',
            dataIndex: 'display_name',
            key: 'display_name',
        },
        {
            title: 'Table Name',
            dataIndex: 'table_name',
            key: 'table_name',
            render: (text) => <Tag color="blue">{text}</Tag>,
        },
        {
            title: 'Model Scope',
            dataIndex: 'model_scope',
            key: 'model_scope',
            render: (text) => <Tag>{text}</Tag>,
        },
        {
            title: 'Alias',
            dataIndex: 'table_alias',
            key: 'table_alias',
            render: (text) => text ? <Tag color="purple">{text}</Tag> : <Text type="secondary">—</Text>,
        },
        {
            title: 'Fields',
            dataIndex: 'field_count',
            key: 'field_count',
            render: (count) => <Text>{count || 0}</Text>,
        },
        {
            title: 'Status',
            dataIndex: 'is_active',
            key: 'is_active',
            render: (isActive) => (
                <Tag color={isActive ? 'green' : 'red'}>
                    {isActive ? 'Active' : 'Inactive'}
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
                        icon={<FieldTimeOutlined />}
                        onClick={() => handleViewFields(record)}
                    >
                        Fields
                    </Button>
                    <Button
                        type="link"
                        icon={<EditOutlined />}
                        onClick={() => handleEdit(record)}
                        disabled={record.is_system_model}
                    >
                        Edit
                    </Button>
                    <Popconfirm
                        title="Are you sure you want to delete this data model?"
                        onConfirm={() => handleDelete(record.model_id)}
                        okText="Yes"
                        cancelText="No"
                        disabled={record.is_system_model}
                    >
                        <Button
                            type="link"
                            danger
                            icon={<DeleteOutlined />}
                            disabled={record.is_system_model}
                        >
                            Delete
                        </Button>
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    const fieldColumns = [
        {
            title: 'Field Name',
            dataIndex: 'field_name',
            key: 'field_name',
        },
        {
            title: 'Display Name',
            dataIndex: 'display_name',
            key: 'display_name',
        },
        {
            title: 'Type',
            dataIndex: 'type_name',
            key: 'type_name',
            render: (text, record) => (
                <Space>
                    {record.input_type_image && (
                        <Image
                            src={getAssetUrl(record.input_type_image)}
                            alt={text}
                            width={24}
                            height={24}
                            preview={false}
                            style={{ objectFit: 'contain' }}
                        />
                    )}
                    <Tag>{text} ({record.actual_db_type})</Tag>
                </Space>
            ),
        },
        {
            title: 'Required',
            dataIndex: 'is_required',
            key: 'is_required',
            render: (required) => required ? <Tag color="red">Yes</Tag> : <Tag>No</Tag>,
        },
        {
            title: 'Unique',
            dataIndex: 'is_unique',
            key: 'is_unique',
            render: (unique) => unique ? <Tag color="blue">Yes</Tag> : null,
        },
        {
            title: 'Primary Key',
            dataIndex: 'is_primary_key',
            key: 'is_primary_key',
            render: (pk) => pk ? <Tag color="green">PK</Tag> : null,
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_, record) => (
                <Space>
                    <Button
                        type="link"
                        size="small"
                        icon={<EditOutlined />}
                        onClick={() => handleEditField(record)}
                        disabled={record.is_primary_key}
                    >
                        Edit
                    </Button>
                    <Popconfirm
                        title="Are you sure? This will also delete the column from the table."
                        onConfirm={() => handleDeleteField(record.field_id, record.field_name)}
                        okText="Yes"
                        cancelText="No"
                        disabled={record.is_primary_key}
                    >
                        <Button
                            type="link"
                            danger
                            size="small"
                            icon={<DeleteOutlined />}
                            disabled={record.is_primary_key}
                        >
                            Delete
                        </Button>
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    const filteredModels = useMemo(() => {
        const q = searchText.trim().toLowerCase();
        if (!q) return dataModels;
        return dataModels.filter((m) => {
            const a = (m.model_name || '').toLowerCase();
            const b = (m.display_name || '').toLowerCase();
            const c = (m.table_name || '').toLowerCase();
            return a.includes(q) || b.includes(q) || c.includes(q);
        });
    }, [dataModels, searchText]);

    return (
        <div style={{ padding: '24px' }}>
            <Card>
                <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Title level={4} style={{ margin: 0 }}>
                        <DatabaseOutlined /> Data Models
                    </Title>
                    <Space>
                        <Input
                            placeholder="Search model name / display name / table name"
                            allowClear
                            value={searchText}
                            onChange={(e) => setSearchText(e.target.value)}
                            style={{ width: 360 }}
                        />
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            onClick={handleCreate}
                        >
                            Create Data Model
                        </Button>
                    </Space>
                </div>

                <Table
                    columns={columns}
                    dataSource={filteredModels}
                    rowKey="model_id"
                    loading={loading}
                    pagination={false}
                />
            </Card>

            {/* Create/Edit Modal */}
            <Modal
                title={editingModel ? 'Edit Data Model' : 'Create Data Model'}
                open={modalVisible}
                onCancel={() => setModalVisible(false)}
                footer={null}
                width={800}
            >
                <Form
                    form={form}
                    layout="vertical"
                    onFinish={handleSubmit}
                >
                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item
                                name="model_name"
                                label="Model Name"
                                rules={[{ required: true, message: 'Please enter model name' }]}
                            >
                                <Input disabled={!!editingModel} placeholder="e.g., users" />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item
                                name="display_name"
                                label="Display Name"
                            >
                                <Input placeholder="e.g., Users" />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item
                                name="table_name"
                                label="Table Name"
                                rules={[{ required: true, message: 'Please enter table name' }]}
                            >
                                <Input placeholder="e.g., users" />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item
                                name="model_scope"
                                label="Model Scope"
                                rules={[{ required: true }]}
                            >
                                <Select>
                                    <Option value="saas">SaaS</Option>
                                    <Option value="tenant">Tenant</Option>
                                    <Option value="both">Both</Option>
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item
                                name="table_alias"
                                label="Table Alias"
                            >
                                <Input placeholder="e.g., sc" />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={16}>
                        <Col span={8}>
                            <Form.Item
                                name="is_public"
                                valuePropName="checked"
                            >
                                <Switch checkedChildren="Public" unCheckedChildren="Private" />
                            </Form.Item>
                        </Col>
                        <Col span={8}>
                            <Form.Item
                                name="is_active"
                                valuePropName="checked"
                                initialValue={true}
                            >
                                <Switch checkedChildren="Active" unCheckedChildren="Inactive" />
                            </Form.Item>
                        </Col>
                        <Col span={8}>
                            <Form.Item
                                name="is_system_model"
                                valuePropName="checked"
                            >
                                <Switch checkedChildren="System" unCheckedChildren="Custom" disabled={!!editingModel} />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Form.Item
                        name="description"
                        label="Description"
                    >
                        <TextArea rows={3} placeholder="Description of the data model" />
                    </Form.Item>

                    <Form.Item>
                        <Space>
                            <Button type="primary" htmlType="submit">
                                {editingModel ? 'Update' : 'Create'}
                            </Button>
                            <Button onClick={() => setModalVisible(false)}>Cancel</Button>
                        </Space>
                    </Form.Item>
                </Form>
            </Modal>

            {/* Fields Drawer */}
            <Drawer
                title={`Fields: ${selectedModel?.display_name || selectedModel?.model_name}`}
                placement="right"
                width={800}
                open={fieldDrawerVisible}
                onClose={() => {
                    setFieldDrawerVisible(false);
                    setFieldEditorDrawerVisible(false);
                    setFieldOrderingDrawerVisible(false);
                    setSelectedModel(null);
                    setFields([]);
                    setOrderingItems([]);
                    setEditingField(null);
                }}
            >
                <div style={{ marginBottom: 16 }}>
                    <Space>
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            onClick={openAddFieldDrawer}
                        >
                            Add Field
                        </Button>
                        <Button
                            icon={<OrderedListOutlined />}
                            onClick={openOrderingDrawer}
                            disabled={!fields.length}
                        >
                            Ordering
                        </Button>
                    </Space>
                </div>

                <Table
                    columns={fieldColumns}
                    dataSource={fields}
                    rowKey="field_id"
                    pagination={false}
                    size="small"
                />
            </Drawer>

            {/* Field Editor Drawer (Add/Edit) */}
            <Drawer
                title={editingField ? `Edit Field: ${editingField.field_name}` : 'Add Field'}
                placement="right"
                width={520}
                open={fieldEditorDrawerVisible}
                onClose={() => {
                    setFieldEditorDrawerVisible(false);
                    setEditingField(null);
                    setFieldConfigJson({});
                    setSelectedFieldType(null);
                }}
                mask={false}
            >
                <Form
                    form={fieldForm}
                    layout="vertical"
                    onFinish={handleFieldSubmit}
                >
                    <Form.Item
                        name="field_name"
                        label="Field Name"
                        rules={[{ required: true, message: 'Please enter field name' }]}
                    >
                        <Input disabled={!!editingField} placeholder="e.g., email" />
                    </Form.Item>

                    <Form.Item
                        name="display_name"
                        label="Display Name"
                    >
                        <Input placeholder="e.g., Email Address" />
                    </Form.Item>

                    <Form.Item
                        name="field_type_id"
                        label="Field Type"
                        rules={[{ required: true, message: 'Please select field type' }]}
                    >
                        <Select 
                            placeholder="Select field type"
                            onChange={(value) => {
                                const ft = fieldTypes.find(f => f.field_type_id === value);
                                setSelectedFieldType(ft);
                                // Reset config when field type changes
                                if (ft?.default_props_json) {
                                    try {
                                        const defaultConfig = typeof ft.default_props_json === 'string'
                                            ? JSON.parse(ft.default_props_json)
                                            : ft.default_props_json;
                                        setFieldConfigJson(defaultConfig || {});
                                    } catch (e) {
                                        setFieldConfigJson({});
                                    }
                                } else {
                                    setFieldConfigJson({});
                                }
                            }}
                            optionLabelProp="label"
                        >
                            {fieldTypes.map(ft => (
                                <Option 
                                    key={ft.field_type_id} 
                                    value={ft.field_type_id}
                                    label={ft.type_name}
                                >
                                    <Space>
                                        {ft.input_type_image && (
                                            <img
                                                src={getAssetUrl(ft.input_type_image)}
                                                alt={ft.type_name}
                                                width={20}
                                                height={20}
                                                style={{ objectFit: 'contain', verticalAlign: 'middle' }}
                                                onError={(e) => {
                                                    e.target.style.display = 'none';
                                                }}
                                            />
                                        )}
                                        <span>{ft.type_name} ({ft.actual_db_type})</span>
                                    </Space>
                                </Option>
                            ))}
                        </Select>
                        {selectedFieldType?.input_type_image && (
                            <div style={{ marginTop: 8, textAlign: 'center' }}>
                                <Image
                                    src={getAssetUrl(selectedFieldType.input_type_image)}
                                    alt={selectedFieldType.type_name}
                                    width={64}
                                    height={64}
                                    preview={false}
                                    style={{ objectFit: 'contain' }}
                                />
                            </div>
                        )}
                    </Form.Item>

                    {selectedFieldType && (
                        <Form.Item label="Field Configuration">
                            <FieldConfigJsonEditor
                                fieldTypeId={selectedFieldType.field_type_id}
                                fieldTypeCode={selectedFieldType.type_code}
                                defaultPropsJson={selectedFieldType.default_props_json}
                                value={fieldConfigJson}
                                onChange={setFieldConfigJson}
                            />
                        </Form.Item>
                    )}

                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item
                                name="is_required"
                                valuePropName="checked"
                            >
                                <Switch checkedChildren="Required" unCheckedChildren="Optional" />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item
                                name="is_unique"
                                valuePropName="checked"
                            >
                                <Switch checkedChildren="Unique" unCheckedChildren="Not Unique" />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Form.Item
                        name="encryption_method"
                        label="Encryption"
                    >
                        <Select>
                            <Option value="none">None</Option>
                            <Option value="aes">AES</Option>
                            <Option value="xor_cipher">XOR Cipher</Option>
                        </Select>
                    </Form.Item>

                    <Form.Item
                        name="default_value"
                        label="Default Value"
                    >
                        <Input placeholder="Default value (optional)" />
                    </Form.Item>

                    {generateSQLPreview() && (
                        <Form.Item label="SQL Preview">
                            <TextArea
                                value={generateSQLPreview()}
                                readOnly
                                rows={2}
                                style={{ fontFamily: 'monospace', fontSize: '12px' }}
                            />
                        </Form.Item>
                    )}

                    <Form.Item>
                        <Space>
                            <Button type="primary" htmlType="submit">
                                {editingField ? 'Update Field' : 'Add Field'}
                            </Button>
                            <Button onClick={() => {
                                fieldForm.resetFields();
                                setFieldConfigJson({});
                                setSelectedFieldType(null);
                            }}>Reset</Button>
                        </Space>
                    </Form.Item>
                </Form>
            </Drawer>

            {/* Field Ordering Drawer */}
            <Drawer
                title="Field Ordering"
                placement="right"
                width={520}
                open={fieldOrderingDrawerVisible}
                onClose={() => setFieldOrderingDrawerVisible(false)}
                mask={false}
                extra={
                    <Space>
                        <Button onClick={() => setFieldOrderingDrawerVisible(false)}>Cancel</Button>
                        <Button type="primary" onClick={saveOrdering}>Save</Button>
                    </Space>
                }
            >
                <VCDragSortList
                    items={orderingItems}
                    onReorder={setOrderingItems}
                />
            </Drawer>

            {/* Confirmation Modal for Table Changes */}
            <Modal
                title="Confirm Table Modification"
                open={confirmModalVisible}
                onOk={handleConfirmChanges}
                onCancel={() => {
                    setConfirmModalVisible(false);
                    setPendingChanges(null);
                }}
                okText="Confirm & Apply"
                cancelText="Cancel"
                width={600}
                okButtonProps={{ danger: pendingChanges?.type === 'delete_field' }}
            >
                {pendingChanges && (
                    <div>
                        <Alert
                            message="Warning: This will modify the database table"
                            description={
                                pendingChanges.type === 'update' ? (
                                    <div>
                                        <p>You are about to rename the table:</p>
                                        <p><strong>{pendingChanges.oldTableName}</strong> → <strong>{pendingChanges.newTableName}</strong></p>
                                        <p>This action cannot be easily undone. Are you sure you want to continue?</p>
                                    </div>
                                ) : pendingChanges.type === 'add_field' ? (
                                    <div>
                                        <p>You are about to add a new column to the table:</p>
                                        <p><strong>Field:</strong> {pendingChanges.values.field_name}</p>
                                        <p>This will modify the table structure. Are you sure you want to continue?</p>
                                    </div>
                                ) : pendingChanges.type === 'delete_field' ? (
                                    <div>
                                        <p>You are about to delete a field and remove its column from the table:</p>
                                        <p><strong>Field:</strong> {pendingChanges.fieldName}</p>
                                        <p><strong style={{ color: 'red' }}>This will permanently delete the column and all its data!</strong></p>
                                        <p>Are you sure you want to continue?</p>
                                    </div>
                                ) : null
                            }
                            type="warning"
                            showIcon
                            icon={<ExclamationCircleOutlined />}
                        />
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default DataModels;
