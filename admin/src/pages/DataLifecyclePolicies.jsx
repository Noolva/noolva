import React, { useState, useEffect } from 'react';
import {
    Card,
    Table,
    Button,
    Space,
    Drawer,
    Form,
    Input,
    InputNumber,
    Switch,
    Select,
    message,
    Popconfirm,
    Alert,
} from 'antd';
import { PlusOutlined, EditOutlined, ReloadOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const DEST = ['s3', 'postgres_archive', 'iceberg'].map((v) => ({ value: v, label: v }));
const MOVE = ['move', 'copy'].map((v) => ({ value: v, label: v }));
const SYNC = ['FULL', 'INCREMENTAL'].map((v) => ({ value: v, label: v }));
const TRANSFER = ['time_based', 'condition_based', 'time_and_condition'].map((v) => ({ value: v, label: v }));

const DataLifecyclePolicies = () => {
    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(false);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form] = Form.useForm();
    const [errorModal, setErrorModal] = useState(null);

    const load = async () => {
        try {
            setLoading(true);
            const data = await api.getDataLifecyclePolicies();
            setItems(data.items || []);
        } catch (e) {
            message.error(e.message || 'Failed to load');
            if (e.errorData) setErrorModal(e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        load();
    }, []);

    const openAdd = () => {
        setEditing(null);
        form.resetFields();
        form.setFieldsValue({
            pk_column: 'id',
            transfer_mode: 'time_based',
            sync_batch_size: 1000,
            is_active: true,
            movement_type: 'copy',
            sync_strategy: 'INCREMENTAL',
            is_public_on_s3: false,
        });
        setDrawerOpen(true);
    };

    const openEdit = (r) => {
        setEditing(r);
        form.setFieldsValue({ ...r });
        setDrawerOpen(true);
    };

    const save = async () => {
        try {
            const v = await form.validateFields();
            if (editing) {
                await api.updateDataLifecyclePolicy(editing.id, v);
                message.success('Updated');
            } else {
                await api.createDataLifecyclePolicy(v);
                message.success('Created');
            }
            setDrawerOpen(false);
            load();
        } catch (e) {
            if (e?.errorFields) return;
            message.error(e.response?.data?.detail || e.message);
            if (e.errorData) setErrorModal(e);
        }
    };

    const del = async (r) => {
        try {
            await api.deleteDataLifecyclePolicy(r.id);
            message.success('Deleted');
            load();
        } catch (e) {
            message.error(e.response?.data?.detail || e.message);
        }
    };

    const cols = [
        { title: 'ID', dataIndex: 'id', width: 70 },
        { title: 'Label', dataIndex: 'policy_label' },
        { title: 'Table', dataIndex: 'table_name' },
        { title: 'Destination', dataIndex: 'destination_type' },
        { title: 'Movement', dataIndex: 'movement_type' },
        { title: 'Sync', dataIndex: 'sync_strategy' },
        { title: 'Interval (min)', dataIndex: 'sync_interval_minutes' },
        {
            title: 'Actions',
            key: 'a',
            render: (_, r) => (
                <Space>
                    <Button type="link" icon={<EditOutlined />} onClick={() => openEdit(r)}>
                        Edit
                    </Button>
                    <Popconfirm title="Delete policy?" onConfirm={() => del(r)}>
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
                title="Data Life Cycles"
                extra={
                    <Button icon={<ReloadOutlined />} onClick={load}>
                        Refresh
                    </Button>
                }
            >
                <Alert
                    type="info"
                    showIcon
                    style={{ marginBottom: 16 }}
                    message="Configure tier movement (S3 JSON, Postgres archive, Iceberg stub). Job templates: dispatch_lifecycle_syncs + sync_lifecycle_table. Set sync_interval_minutes for scheduler dispatch."
                />
                <Button type="primary" icon={<PlusOutlined />} style={{ marginBottom: 12 }} onClick={openAdd}>
                    Add policy
                </Button>
                <Table rowKey="id" loading={loading} columns={cols} dataSource={items} pagination={{ pageSize: 15 }} />
            </Card>

            <Drawer
                width={520}
                title={editing ? 'Edit lifecycle policy' : 'Add lifecycle policy'}
                open={drawerOpen}
                onClose={() => setDrawerOpen(false)}
                extra={
                    <Space>
                        <Button onClick={() => setDrawerOpen(false)}>Cancel</Button>
                        <Button type="primary" onClick={save}>
                            Save
                        </Button>
                    </Space>
                }
            >
                <Form form={form} layout="vertical">
                    <Form.Item name="policy_label" label="Policy label" extra="Optional display name.">
                        <Input />
                    </Form.Item>
                    <Form.Item name="table_name" label="Source table" rules={[{ required: true }]}>
                        <Input disabled={!!editing} />
                    </Form.Item>
                    <Form.Item name="pk_column" label="PK column">
                        <Input />
                    </Form.Item>
                    <Form.Item name="transfer_mode" label="Transfer mode" rules={[{ required: true }]}>
                        <Select options={TRANSFER} />
                    </Form.Item>
                    <Form.Item name="time_column" label="Time column" extra="For time_based / time_and_condition.">
                        <Input />
                    </Form.Item>
                    <Form.Item name="filter_condition" label="Filter SQL fragment" extra="For condition modes; validated server-side lightly.">
                        <Input.TextArea rows={2} />
                    </Form.Item>
                    <Form.Item name="destination_type" label="Destination" rules={[{ required: true }]}>
                        <Select options={DEST} />
                    </Form.Item>
                    <Form.Item name="destination_table" label="Destination table" extra="Required for postgres_archive (e.g. archived_orders).">
                        <Input />
                    </Form.Item>
                    <Form.Item name="is_public_on_s3" label="S3 public prefix" valuePropName="checked" extra="For s3: true = public/lifecycle_data/, false = private/.">
                        <Switch />
                    </Form.Item>
                    <Form.Item name="movement_type" label="Movement" rules={[{ required: true }]}>
                        <Select options={MOVE} />
                    </Form.Item>
                    <Form.Item name="sync_strategy" label="Sync strategy" rules={[{ required: true }]}>
                        <Select options={SYNC} />
                    </Form.Item>
                    <Form.Item name="sync_batch_size" label="Batch size">
                        <InputNumber min={1} style={{ width: '100%' }} />
                    </Form.Item>
                    <Form.Item name="sync_interval_minutes" label="Sync interval (minutes)" extra="Required for scheduled dispatch workflow.">
                        <InputNumber min={1} style={{ width: '100%' }} />
                    </Form.Item>
                    <Form.Item name="is_active" label="Active" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                </Form>
            </Drawer>
            {errorModal && (
                <ErrorModal visible={!!errorModal} error={errorModal} onClose={() => setErrorModal(null)} />
            )}
        </div>
    );
};

export default DataLifecyclePolicies;
