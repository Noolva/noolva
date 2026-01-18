import React, { useState, useEffect } from 'react';
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
    Divider,
    InputNumber,
    Tabs,
    Alert
} from 'antd';
import {
    PlusOutlined,
    EditOutlined,
    DeleteOutlined,
    DatabaseOutlined,
    FieldTimeOutlined,
    ExclamationCircleOutlined
} from '@ant-design/icons';
import { api } from '../utils/api';

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
    const [editingModel, setEditingModel] = useState(null);
    const [selectedModel, setSelectedModel] = useState(null);
    const [fields, setFields] = useState([]);
    const [form] = Form.useForm();
    const [fieldForm] = Form.useForm();
    const [confirmModalVisible, setConfirmModalVisible] = useState(false);
    const [pendingChanges, setPendingChanges] = useState(null);

    useEffect(() => {
        loadDataModels();
        loadFieldTypes();
    }, []);

    const loadDataModels = async () => {
        try {
            setLoading(true);
            const response = await api.getDataModels();
            setDataModels(response.data_models || []);
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
                use_case: response.use_case,
                is_public: response.is_public,
                is_system_model: response.is_system_model,
                is_active: response.is_active,
                description: response.description,
                icon: response.icon,
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

    const handleAddField = () => {
        fieldForm.resetFields();
        fieldForm.setFieldsValue({
            order_no: fields.length + 1,
            encryption_method: 'none',
            is_required: false,
            is_unique: false,
            is_primary_key: false,
        });
        setFieldDrawerVisible(true);
    };

    const handleFieldSubmit = async (values) => {
        try {
            if (!selectedModel) return;
            
            // Check if this will modify the table
            setPendingChanges({
                type: 'add_field',
                modelId: selectedModel.model_id,
                values
            });
            setConfirmModalVisible(true);
        } catch (error) {
            message.error('Failed to add field: ' + (error.message || 'Unknown error'));
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
            title: 'Use Case',
            dataIndex: 'use_case',
            key: 'use_case',
            render: (text) => <Tag>{text}</Tag>,
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
                <Tag>{text} ({record.actual_db_type})</Tag>
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
            title: 'Order',
            dataIndex: 'order_no',
            key: 'order_no',
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_, record) => (
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
            ),
        },
    ];

    return (
        <div style={{ padding: '24px' }}>
            <Card>
                <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Title level={4} style={{ margin: 0 }}>
                        <DatabaseOutlined /> Data Models
                    </Title>
                    <Button
                        type="primary"
                        icon={<PlusOutlined />}
                        onClick={handleCreate}
                    >
                        Create Data Model
                    </Button>
                </div>

                <Table
                    columns={columns}
                    dataSource={dataModels}
                    rowKey="model_id"
                    loading={loading}
                    pagination={{ pageSize: 10 }}
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
                                name="use_case"
                                label="Use Case"
                                rules={[{ required: true }]}
                            >
                                <Select>
                                    <Option value="system">System</Option>
                                    <Option value="tenant">Tenant</Option>
                                    <Option value="app">App</Option>
                                </Select>
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

                    <Form.Item
                        name="icon"
                        label="Icon"
                    >
                        <Input placeholder="e.g., user, database" />
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
                    setSelectedModel(null);
                    setFields([]);
                }}
            >
                <div style={{ marginBottom: 16 }}>
                    <Button
                        type="primary"
                        icon={<PlusOutlined />}
                        onClick={handleAddField}
                    >
                        Add Field
                    </Button>
                </div>

                <Table
                    columns={fieldColumns}
                    dataSource={fields}
                    rowKey="field_id"
                    pagination={false}
                    size="small"
                />

                {/* Add Field Form */}
                {fieldDrawerVisible && (
                    <Card
                        title="Add New Field"
                        style={{ marginTop: 16 }}
                        extra={
                            <Button
                                type="link"
                                onClick={() => fieldForm.resetFields()}
                            >
                                Clear
                            </Button>
                        }
                    >
                        <Form
                            form={fieldForm}
                            layout="vertical"
                            onFinish={handleFieldSubmit}
                        >
                            <Row gutter={16}>
                                <Col span={12}>
                                    <Form.Item
                                        name="field_name"
                                        label="Field Name"
                                        rules={[{ required: true, message: 'Please enter field name' }]}
                                    >
                                        <Input placeholder="e.g., email" />
                                    </Form.Item>
                                </Col>
                                <Col span={12}>
                                    <Form.Item
                                        name="display_name"
                                        label="Display Name"
                                    >
                                        <Input placeholder="e.g., Email Address" />
                                    </Form.Item>
                                </Col>
                            </Row>

                            <Row gutter={16}>
                                <Col span={12}>
                                    <Form.Item
                                        name="field_type_id"
                                        label="Field Type"
                                        rules={[{ required: true, message: 'Please select field type' }]}
                                    >
                                        <Select placeholder="Select field type">
                                            {fieldTypes.map(ft => (
                                                <Option key={ft.field_type_id} value={ft.field_type_id}>
                                                    {ft.type_name} ({ft.actual_db_type})
                                                </Option>
                                            ))}
                                        </Select>
                                    </Form.Item>
                                </Col>
                                <Col span={12}>
                                    <Form.Item
                                        name="order_no"
                                        label="Order"
                                    >
                                        <InputNumber min={0} style={{ width: '100%' }} />
                                    </Form.Item>
                                </Col>
                            </Row>

                            <Row gutter={16}>
                                <Col span={8}>
                                    <Form.Item
                                        name="is_required"
                                        valuePropName="checked"
                                    >
                                        <Switch checkedChildren="Required" unCheckedChildren="Optional" />
                                    </Form.Item>
                                </Col>
                                <Col span={8}>
                                    <Form.Item
                                        name="is_unique"
                                        valuePropName="checked"
                                    >
                                        <Switch checkedChildren="Unique" unCheckedChildren="Not Unique" />
                                    </Form.Item>
                                </Col>
                                <Col span={8}>
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
                                </Col>
                            </Row>

                            <Form.Item
                                name="default_value"
                                label="Default Value"
                            >
                                <Input placeholder="Default value (optional)" />
                            </Form.Item>

                            <Form.Item>
                                <Space>
                                    <Button type="primary" htmlType="submit">
                                        Add Field
                                    </Button>
                                    <Button onClick={() => fieldForm.resetFields()}>Reset</Button>
                                </Space>
                            </Form.Item>
                        </Form>
                    </Card>
                )}
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
