import React, { useState, useEffect } from 'react';
import {
    Card,
    Table,
    Button,
    Space,
    Tabs,
    Form,
    Input,
    InputNumber,
    Switch,
    Select,
    Drawer,
    message,
    Popconfirm,
    Alert,
    Tag,
} from 'antd';
import { PlusOutlined, EditOutlined, ReloadOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const REFRESH_OPTIONS = [
    { value: 'FULL', label: 'FULL' },
    { value: 'INCREMENTAL', label: 'INCREMENTAL' },
    { value: 'VERSIONED', label: 'VERSIONED' },
];

const FlattenedDatas = () => {
    const [tablePolicies, setTablePolicies] = useState([]);
    const [relationPolicies, setRelationPolicies] = useState([]);
    const [loading, setLoading] = useState(false);
    const [errorModal, setErrorModal] = useState(null);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [drawerMode, setDrawerMode] = useState('table');
    const [editingTable, setEditingTable] = useState(null);
    const [editingRelation, setEditingRelation] = useState(null);
    const [form] = Form.useForm();
    const [relForm] = Form.useForm();

    const loadTables = async () => {
        try {
            setLoading(true);
            const data = await api.getFlatteningTablePolicies();
            setTablePolicies(data.items || []);
        } catch (e) {
            message.error(e.message || 'Failed to load table policies');
            if (e.errorData) setErrorModal(e);
        } finally {
            setLoading(false);
        }
    };

    const loadRelations = async () => {
        try {
            const data = await api.getFlatteningRelationPolicies();
            setRelationPolicies(data.items || []);
        } catch (e) {
            message.error(e.message || 'Failed to load relation policies');
            if (e.errorData) setErrorModal(e);
        }
    };

    useEffect(() => {
        loadTables();
        loadRelations();
    }, []);

    const openAddTable = () => {
        setEditingTable(null);
        form.resetFields();
        form.setFieldsValue({
            is_snapshot: true,
            is_active: true,
        });
        setDrawerMode('table');
        setDrawerOpen(true);
    };

    const openEditTable = (record) => {
        setEditingTable(record);
        form.setFieldsValue({
            ...record,
            refresh_strategy: record.refresh_strategy || undefined,
        });
        setDrawerMode('table');
        setDrawerOpen(true);
    };

    const saveTable = async () => {
        try {
            const v = await form.validateFields();
            if (editingTable) {
                await api.updateFlatteningTablePolicy(editingTable.id, v);
                message.success('Updated');
            } else {
                const res = await api.createFlatteningTablePolicy(v);
                message.success('Created');
                if (res.read_endpoints?.length) {
                    message.info(`Read APIs: ${res.read_endpoints.join('; ')}`);
                }
            }
            setDrawerOpen(false);
            loadTables();
        } catch (e) {
            if (e?.errorFields) return;
            message.error(e.response?.data?.detail || e.message || 'Save failed');
            if (e.errorData) setErrorModal(e);
        }
    };

    const deleteTable = async (record) => {
        try {
            await api.deleteFlatteningTablePolicy(record.id);
            message.success('Deleted');
            loadTables();
            loadRelations();
        } catch (e) {
            message.error(e.response?.data?.detail || e.message);
            if (e.errorData) setErrorModal(e);
        }
    };

    const openAddRelation = () => {
        setEditingRelation(null);
        relForm.resetFields();
        relForm.setFieldsValue({ is_required: false, relation_type: 'm2o', strategy: 'denormalize' });
        setDrawerMode('relation');
        setDrawerOpen(true);
    };

    const openEditRelation = (record) => {
        setEditingRelation(record);
        relForm.setFieldsValue({
            ...record,
            include_fields: Array.isArray(record.include_fields) ? record.include_fields.join(', ') : '',
        });
        setDrawerMode('relation');
        setDrawerOpen(true);
    };

    const saveRelation = async () => {
        try {
            const v = await relForm.validateFields();
            const payload = {
                ...v,
                include_fields: Array.isArray(v.include_fields)
                    ? v.include_fields.filter(Boolean)
                    : v.include_fields
                    ? v.include_fields.split(',').map((s) => s.trim()).filter(Boolean)
                    : undefined,
            };
            if (editingRelation) {
                await api.updateFlatteningRelationPolicy(editingRelation.id, payload);
                message.success('Updated');
            } else {
                await api.createFlatteningRelationPolicy(payload);
                message.success('Created');
            }
            setDrawerOpen(false);
            loadRelations();
        } catch (e) {
            if (e?.errorFields) return;
            message.error(e.response?.data?.detail || e.message);
            if (e.errorData) setErrorModal(e);
        }
    };

    const deleteRelation = async (record) => {
        try {
            await api.deleteFlatteningRelationPolicy(record.id);
            message.success('Deleted');
            loadRelations();
        } catch (e) {
            message.error(e.response?.data?.detail || e.message);
        }
    };

    const tableCols = [
        { title: 'ID', dataIndex: 'id', width: 70 },
        { title: 'Table', dataIndex: 'table_name' },
        {
            title: 'Strategy',
            dataIndex: 'refresh_strategy',
            render: (t) => t || <Tag color="default">snapshot</Tag>,
        },
        { title: 'Interval (min)', dataIndex: 'refresh_interval_minutes' },
        { title: 'Snapshot', dataIndex: 'is_snapshot', render: (v) => (v ? 'Yes' : 'No') },
        { title: 'Active', dataIndex: 'is_active', render: (v) => (v ? 'Yes' : 'No') },
        {
            title: 'Actions',
            key: 'a',
            render: (_, r) => (
                <Space>
                    <Button type="link" icon={<EditOutlined />} onClick={() => openEditTable(r)}>
                        Edit
                    </Button>
                    <Popconfirm title="Delete policy and managed read endpoints?" onConfirm={() => deleteTable(r)}>
                        <Button type="link" danger>
                            Delete
                        </Button>
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    const relCols = [
        { title: 'ID', dataIndex: 'id', width: 70 },
        { title: 'Table', dataIndex: 'table_name' },
        { title: 'Relation', dataIndex: 'relation_name' },
        { title: 'Type', dataIndex: 'relation_type' },
        { title: 'Strategy', dataIndex: 'strategy' },
        {
            title: 'Actions',
            key: 'a',
            render: (_, r) => (
                <Space>
                    <Button type="link" icon={<EditOutlined />} onClick={() => openEditRelation(r)}>
                        Edit
                    </Button>
                    <Popconfirm title="Delete?" onConfirm={() => deleteRelation(r)}>
                        <Button type="link" danger>
                            Delete
                        </Button>
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    return (
        <div style={{ padding: 16 }}>
            <Card
                title="Flattened Datas"
                extra={
                    <Button icon={<ReloadOutlined />} onClick={() => { loadTables(); loadRelations(); }}>
                        Refresh
                    </Button>
                }
            >
                <Alert
                    type="info"
                    showIcon
                    style={{ marginBottom: 16 }}
                    message="WARM tier: register the flattened physical table as a Data Model first. Saving a table policy creates GET-only Auto CRUD routes for that model."
                />
                <Tabs
                    items={[
                        {
                            key: 't',
                            label: 'Table policies',
                            children: (
                                <>
                                    <Button type="primary" icon={<PlusOutlined />} style={{ marginBottom: 12 }} onClick={openAddTable}>
                                        Add table policy
                                    </Button>
                                    <Table rowKey="id" loading={loading} columns={tableCols} dataSource={tablePolicies} pagination={{ pageSize: 20 }} />
                                </>
                            ),
                        },
                        {
                            key: 'r',
                            label: 'Relation policies',
                            children: (
                                <>
                                    <Button type="primary" icon={<PlusOutlined />} style={{ marginBottom: 12 }} onClick={openAddRelation}>
                                        Add relation policy
                                    </Button>
                                    <Table rowKey="id" columns={relCols} dataSource={relationPolicies} pagination={{ pageSize: 20 }} />
                                </>
                            ),
                        },
                    ]}
                />
            </Card>

            <Drawer
                width={480}
                title={
                    drawerMode === 'table'
                        ? editingTable
                            ? 'Edit table policy'
                            : 'Add table policy'
                        : editingRelation
                          ? 'Edit relation policy'
                          : 'Add relation policy'
                }
                open={drawerOpen}
                onClose={() => setDrawerOpen(false)}
                extra={
                    <Space>
                        <Button onClick={() => setDrawerOpen(false)}>Cancel</Button>
                        <Button type="primary" onClick={drawerMode === 'table' ? saveTable : saveRelation}>
                            Save
                        </Button>
                    </Space>
                }
            >
                {drawerMode === 'table' ? (
                    <Form form={form} layout="vertical">
                        <Form.Item name="table_name" label="Table name" rules={[{ required: true }]} extra="Must match data_models.table_name for GET endpoints.">
                            <Input disabled={!!editingTable} />
                        </Form.Item>
                        <Form.Item name="is_snapshot" label="Snapshot (no refresh)" valuePropName="checked">
                            <Switch />
                        </Form.Item>
                        <Form.Item name="refresh_strategy" label="Refresh strategy" extra="Required when not snapshot.">
                            <Select allowClear options={REFRESH_OPTIONS} />
                        </Form.Item>
                        <Form.Item name="refresh_interval_minutes" label="Interval (minutes)">
                            <InputNumber min={1} style={{ width: '100%' }} />
                        </Form.Item>
                        <Form.Item name="batch_size" label="Batch size">
                            <InputNumber min={1} style={{ width: '100%' }} />
                        </Form.Item>
                        <Form.Item name="is_active" label="Active" valuePropName="checked">
                            <Switch />
                        </Form.Item>
                    </Form>
                ) : (
                    <Form form={relForm} layout="vertical">
                        <Form.Item name="table_name" label="Flattening table name" rules={[{ required: true }]} extra="Parent row in table policies.">
                            <Input disabled={!!editingRelation} />
                        </Form.Item>
                        <Form.Item name="relation_name" label="Relation name" rules={[{ required: true }]}>
                            <Input disabled={!!editingRelation} />
                        </Form.Item>
                        <Form.Item name="relation_type" label="Relation type" rules={[{ required: true }]}>
                            <Select
                                options={[
                                    { value: 'm2o', label: 'Many2One → denormalize' },
                                    { value: 'o2m', label: 'One2Many → json or separate' },
                                ]}
                            />
                        </Form.Item>
                        <Form.Item name="strategy" label="Strategy" rules={[{ required: true }]}>
                            <Select
                                options={[
                                    { value: 'denormalize', label: 'denormalize' },
                                    { value: 'json', label: 'json' },
                                    { value: 'separate', label: 'separate table' },
                                ]}
                            />
                        </Form.Item>
                        <Form.Item
                            name="include_fields"
                            label="Include fields (denormalize)"
                            extra="Comma-separated or leave empty; ignored for json/separate."
                        >
                            <Input placeholder="field_a, field_b" />
                        </Form.Item>
                        <Form.Item name="target_table" label="Target table (separate)">
                            <Input />
                        </Form.Item>
                        <Form.Item name="is_required" label="Required" valuePropName="checked">
                            <Switch />
                        </Form.Item>
                    </Form>
                )}
            </Drawer>
            {errorModal && (
                <ErrorModal visible={!!errorModal} error={errorModal} onClose={() => setErrorModal(null)} />
            )}
        </div>
    );
};

export default FlattenedDatas;
