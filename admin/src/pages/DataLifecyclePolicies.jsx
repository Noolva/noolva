import React, { useState, useEffect, useMemo, useCallback } from 'react';
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
    Typography,
    Modal,
    Divider,
} from 'antd';
import { PlusOutlined, EditOutlined, ReloadOutlined, QuestionCircleOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const DEST = ['s3', 'postgres_archive', 'iceberg'].map((v) => ({ value: v, label: v }));
const MOVE = ['move', 'copy'].map((v) => ({ value: v, label: v }));
const SYNC = ['FULL', 'INCREMENTAL'].map((v) => ({ value: v, label: v }));
const TRANSFER = ['time_based', 'condition_based', 'time_and_condition'].map((v) => ({ value: v, label: v }));

const { Text } = Typography;

const DataLifecyclePolicies = () => {
    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(false);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form] = Form.useForm();
    const [errorModal, setErrorModal] = useState(null);
    const [sourceOptions, setSourceOptions] = useState({ flat_sources: [], archived_sources: [] });
    const [hintTimeOptions, setHintTimeOptions] = useState([]);
    const [hintArchiveKey, setHintArchiveKey] = useState('');
    const [hintRoot, setHintRoot] = useState(null);
    const [hintIcebergId, setHintIcebergId] = useState('');
    const [helpOpen, setHelpOpen] = useState(false);

    const watchedTableName = Form.useWatch('table_name', form);
    const watchedDest = Form.useWatch('destination_type', form);
    const watchedIcebergTable = Form.useWatch('destination_table', form);

    const sourceSelectOptions = useMemo(() => {
        const flat = (sourceOptions.flat_sources || []).map((o) => ({
            value: o.value,
            label: o.label || o.value,
        }));
        const arch = (sourceOptions.archived_sources || []).map((o) => ({
            value: o.value,
            label: o.label || o.value,
        }));
        return [
            ...(flat.length ? [{ label: 'Flat (materialized)', options: flat }] : []),
            ...(arch.length ? [{ label: 'Archived (tier-2 / Iceberg source)', options: arch }] : []),
        ];
    }, [sourceOptions]);

    const loadSourceOptions = async () => {
        try {
            const d = await api.getLifecycleSourceTableOptions();
            setSourceOptions(d || { flat_sources: [], archived_sources: [] });
        } catch (e) {
            setSourceOptions({ flat_sources: [], archived_sources: [] });
            message.warning(e.response?.data?.detail || e.message || 'Could not load source options');
        }
    };

    const loadHintMeta = useCallback(async (tableName, applyToForm = false, currentTimeColumn = null) => {
        const tn = (tableName || '').trim();
        if (!tn) {
            setHintTimeOptions([]);
            setHintArchiveKey('');
            setHintRoot(null);
            setHintIcebergId('');
            return null;
        }
        try {
            const h = await api.getLifecycleTableHints(tn);
            setHintArchiveKey(h.archive_export_key || (tn && !tn.startsWith('archived_') ? `archived_${tn}` : ''));
            setHintRoot(h.lifecycle_root_table || null);
            setHintIcebergId(h.suggested_iceberg_identifier || '');
            let opts = (h.time_column_options || []).map((c) => ({ value: c, label: c }));
            const cur = (currentTimeColumn || '').trim();
            if (cur && !opts.some((o) => o.value === cur)) {
                opts = [{ value: cur, label: `${cur} (current)` }, ...opts];
            }
            setHintTimeOptions(opts);
            if (applyToForm) {
                const curLabel = form.getFieldValue('policy_label');
                const dest = form.getFieldValue('destination_type');
                form.setFieldsValue({
                    pk_column: h.pk_column || 'id',
                    time_column: h.time_column || undefined,
                    ...(curLabel ? {} : { policy_label: h.suggested_policy_label }),
                    ...(dest === 'iceberg' && !form.getFieldValue('destination_table')
                        ? { destination_table: h.suggested_iceberg_identifier }
                        : {}),
                });
            }
            return h;
        } catch (e) {
            setHintTimeOptions([]);
            setHintArchiveKey('');
            setHintRoot(null);
            setHintIcebergId('');
            if (applyToForm) message.warning(e.response?.data?.detail || e.message || 'Could not load table hints');
            return null;
        }
    }, [form]);

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
        loadSourceOptions();
    }, []);

    const openAdd = () => {
        setEditing(null);
        form.resetFields();
        setHintTimeOptions([]);
        form.setFieldsValue({
            pk_column: 'id',
            transfer_mode: 'time_based',
            sync_batch_size: 1000,
            is_active: true,
            movement_type: 'copy',
            sync_strategy: 'INCREMENTAL',
            is_public_on_s3: false,
            sync_interval_minutes: 60,
            destination_type: 'postgres_archive',
            purge_enabled: false,
        });
        setHintArchiveKey('');
        setHintRoot(null);
        setHintIcebergId('');
        setDrawerOpen(true);
    };

    const openEdit = async (r) => {
        setEditing(r);
        form.resetFields();
        setHintTimeOptions([]);
        form.setFieldsValue({ ...r });
        setDrawerOpen(true);
        await loadHintMeta(r.table_name, false, r.time_column);
    };

    const onPhysicalSourceChange = async (val) => {
        if (!val || editing) return;
        await loadHintMeta(val, true);
    };

    const onDestTypeChange = (v) => {
        const tn = form.getFieldValue('table_name');
        if (v === 'iceberg' && tn && !form.getFieldValue('destination_table') && hintIcebergId) {
            form.setFieldsValue({ destination_table: hintIcebergId });
        }
    };

    const save = async () => {
        try {
            const v = await form.validateFields();
            const payload = { ...v };
            if (payload.destination_type !== 'iceberg') {
                delete payload.destination_table;
            }
            let res;
            if (editing) {
                res = await api.updateDataLifecyclePolicy(editing.id, payload);
                message.success('Updated');
            } else {
                res = await api.createDataLifecyclePolicy(payload);
                message.success('Created');
            }
            if (res?.read_endpoints_error) {
                message.warning('Policy saved but archive/Iceberg read endpoints failed — check API logs.');
            } else if (res?.lifecycle_archive_read_endpoints?.length || res?.lifecycle_iceberg_read_stub) {
                message.info(
                    'Read APIs: GET auto endpoints for lifecycle archive model (see API Endpoints). Iceberg tier exposes a custom-endpoint stub (501 until implemented).',
                    6,
                );
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

    const archivePreview = useMemo(() => {
        if ((watchedDest || '').toString() === 'iceberg') {
            return (watchedIcebergTable || '').toString().trim() || hintIcebergId || '(Iceberg id on save)';
        }
        if (hintArchiveKey) return hintArchiveKey;
        if ((watchedTableName || '').toString().trim()) return `archived_${(watchedTableName || '').toString().trim()}`;
        return '';
    }, [watchedTableName, hintArchiveKey, watchedDest, hintIcebergId, watchedIcebergTable]);

    const cols = [
        { title: 'ID', dataIndex: 'id', width: 64 },
        { title: 'Label', dataIndex: 'policy_label', ellipsis: true },
        { title: 'Physical source', dataIndex: 'table_name', width: 160, ellipsis: true },
        {
            title: 'Hot root',
            dataIndex: 'lifecycle_root_table',
            width: 120,
            ellipsis: true,
            render: (v) => v || '—',
        },
        { title: 'Dest / key', dataIndex: 'destination_table', ellipsis: true },
        { title: 'Type', dataIndex: 'destination_type', width: 120 },
        {
            title: 'Purge',
            dataIndex: 'purge_enabled',
            width: 64,
            render: (v) => (v ? 'On' : 'Off'),
        },
        { title: 'Sync', dataIndex: 'sync_strategy', width: 100 },
        { title: 'Int.', dataIndex: 'sync_interval_minutes', width: 64 },
        {
            title: 'Actions',
            key: 'a',
            width: 140,
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
                    <Space>
                        <Button icon={<QuestionCircleOutlined />} onClick={() => setHelpOpen(true)}>
                            How archive &amp; purge work
                        </Button>
                        <Button icon={<ReloadOutlined />} onClick={load}>
                            Refresh
                        </Button>
                    </Space>
                }
            >
                <Alert
                    type="info"
                    showIcon
                    style={{ marginBottom: 16 }}
                    message={
                        <>
                            Source must be a <strong>flat materialized</strong> table (from Flattened Datas) for
                            Postgres/S3 archive, or an <strong>archived_*</strong> table for a second-tier Iceberg policy.
                            See <strong>Lifecycle batch ledger</strong> in the menu for run history.
                        </>
                    }
                />
                <Button type="primary" icon={<PlusOutlined />} style={{ marginBottom: 12 }} onClick={openAdd}>
                    Add policy
                </Button>
                <Table rowKey="id" loading={loading} columns={cols} dataSource={items} pagination={{ pageSize: 15 }} />
            </Card>

            <Drawer
                width={540}
                title={editing ? 'Edit lifecycle policy' : 'Add lifecycle policy'}
                open={drawerOpen}
                onClose={() => {
                    setDrawerOpen(false);
                    setHintTimeOptions([]);
                }}
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
                    <Form.Item name="policy_label" label="Policy label" extra="Optional; auto-suggested from physical source.">
                        <Input placeholder="e.g. Lifecycle: orders flat" />
                    </Form.Item>

                    <Form.Item
                        name="table_name"
                        label="Physical source table"
                        rules={[{ required: true, message: 'Select a flat or archived table' }]}
                        extra="Only tables listed here are allowed (flattening targets and archived_*). Not the raw hot root alone."
                    >
                        {editing ? (
                            <Input disabled />
                        ) : (
                            <Select
                                showSearch
                                optionFilterProp="label"
                                placeholder="Select flat or archived_*"
                                options={sourceSelectOptions}
                                onChange={onPhysicalSourceChange}
                            />
                        )}
                    </Form.Item>

                    {(hintRoot || hintIcebergId) && (
                        <Alert
                            type="info"
                            showIcon
                            style={{ marginBottom: 12 }}
                            message={
                                <span>
                                    {hintRoot ? (
                                        <>
                                            Flattening root (for purge): <Text code>{hintRoot}</Text>
                                            <br />
                                        </>
                                    ) : null}
                                    {hintIcebergId ? (
                                        <>
                                            Suggested Iceberg id: <Text code>{hintIcebergId}</Text>
                                        </>
                                    ) : null}
                                </span>
                            }
                        />
                    )}

                    <Form.Item name="pk_column" label="PK column" extra="Primary key on the physical source (and hot root for tier-1 purge).">
                        <Input placeholder="id" />
                    </Form.Item>

                    <Form.Item name="transfer_mode" label="Transfer mode" rules={[{ required: true }]}>
                        <Select options={TRANSFER} />
                    </Form.Item>

                    <Form.Item
                        noStyle
                        shouldUpdate={(p, c) => p.transfer_mode !== c.transfer_mode || p.table_name !== c.table_name}
                    >
                        {({ getFieldValue }) => {
                            const mode = getFieldValue('transfer_mode');
                            const showTime = mode === 'time_based' || mode === 'time_and_condition';
                            if (!showTime) return null;
                            return hintTimeOptions.length > 0 ? (
                                <Form.Item
                                    name="time_column"
                                    label="Time column"
                                    extra="Columns on the physical source table (flat or archived_*)."
                                >
                                    <Select allowClear showSearch optionFilterProp="label" options={hintTimeOptions} placeholder="Select time column" />
                                </Form.Item>
                            ) : (
                                <Form.Item name="time_column" label="Time column" extra="Timestamptz column on the physical source.">
                                    <Input placeholder="e.g. last_updated" />
                                </Form.Item>
                            );
                        }}
                    </Form.Item>

                    <Form.Item name="filter_condition" label="Filter SQL fragment" extra="Fragment for WHERE (no WHERE keyword). Must use columns that exist on the physical source.">
                        <Input.TextArea rows={2} placeholder="e.g. status = 'completed'" />
                    </Form.Item>

                    <Form.Item name="destination_type" label="Destination" rules={[{ required: true }]} extra="postgres_archive: copy flat → archived_&lt;flat&gt;. iceberg: Parquet (+ optional PyIceberg append) from archived_*. s3: stub.">
                        <Select options={DEST} onChange={onDestTypeChange} />
                    </Form.Item>

                    <Form.Item noStyle shouldUpdate={(p, c) => p.destination_type !== c.destination_type}>
                        {({ getFieldValue }) => {
                            const dest = getFieldValue('destination_type');
                            if (dest === 'iceberg') {
                                return (
                                    <Form.Item
                                        name="destination_table"
                                        label="Iceberg logical table id"
                                        rules={[{ required: true, message: 'e.g. lifecycle.archived_flat_orders' }]}
                                        extra="Stored on the policy; Parquet files also use this in folder names. Optional PyIceberg append: ICEBERG_SQL_CATALOG_URI + ICEBERG_APPEND_TABLE."
                                    >
                                        <Input placeholder="lifecycle.archived_flat_orders" />
                                    </Form.Item>
                                );
                            }
                            return null;
                        }}
                    </Form.Item>

                    <Form.Item noStyle shouldUpdate={(p, c) => p.destination_type !== c.destination_type}>
                        {({ getFieldValue }) => {
                            const dest = getFieldValue('destination_type');
                            if (dest !== 's3') return null;
                            return (
                                <Form.Item name="is_public_on_s3" label="S3 public prefix" valuePropName="checked" extra="true = public/lifecycle_data/, false = private/.">
                                    <Switch />
                                </Form.Item>
                            );
                        }}
                    </Form.Item>

                    <Form.Item label="Destination summary (on save)">
                        <Text type="secondary">
                            {editing?.destination_table || archivePreview || 'Select source and destination type.'}
                        </Text>
                    </Form.Item>

                    <Divider orientation="left">Purge</Divider>

                    <Form.Item
                        name="purge_enabled"
                        label="Enable purge job"
                        valuePropName="checked"
                        extra="Tier-1 (postgres_archive): deletes separate flattening child tables, flat row, and root row for PKs in flat ∩ archive. Tier-2 (iceberg): deletes archived rows after a successful export batch recorded in the batch ledger."
                    >
                        <Switch />
                    </Form.Item>

                    <Form.Item
                        name="purge_after_interval_minutes"
                        label="Purge delay after archive (minutes)"
                        extra="Leave empty for 0. Waits after last_archive_completed_at before purge jobs consider this policy."
                    >
                        <InputNumber min={0} style={{ width: '100%' }} placeholder="0" />
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

                    <Form.Item name="sync_interval_minutes" label="Sync interval (minutes)" extra="Required for dispatch workflows.">
                        <InputNumber min={1} style={{ width: '100%' }} />
                    </Form.Item>

                    <Form.Item name="is_active" label="Active" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                </Form>
            </Drawer>

            <Modal
                title="Data lifecycle — archive vs purge"
                open={helpOpen}
                onCancel={() => setHelpOpen(false)}
                footer={[
                    <Button key="c" type="primary" onClick={() => setHelpOpen(false)}>
                        Got it
                    </Button>,
                ]}
                width={640}
            >
                <Typography.Paragraph>
                    <strong>Physical source</strong> is either a flattening <Text code>target_table_name</Text> (flat) or
                    an <Text code>archived_*</Text> Postgres table for a second policy that exports to Iceberg/Parquet.
                </Typography.Paragraph>
                <Typography.Paragraph>
                    <strong>Tier 1:</strong> flat → <Text code>archived_&lt;flat_table&gt;</Text> via{' '}
                    <Text code>sync_lifecycle_table</Text>. Purge (optional) deletes separate child tables using a{' '}
                    <strong>real single-column foreign key</strong> from the child to the hot root (resolved in Postgres
                    metadata — not assumed to match the flat PK name), then flat, then root, when PKs exist in flat ∩ archive.
                </Typography.Paragraph>
                <Typography.Paragraph>
                    <strong>Tier 2:</strong> <Text code>archived_*</Text> → Parquet files under <Text code>ICEBERG_WAREHOUSE</Text>{' '}
                    or <Text code>LIFECYCLE_PARQUET_DIR</Text>; optional append to an existing Iceberg table via env. Purge
                    removes the same PKs from <Text code>archived_*</Text> using the batch ledger.
                </Typography.Paragraph>
            </Modal>

            {errorModal && (
                <ErrorModal visible={!!errorModal} error={errorModal} onClose={() => setErrorModal(null)} />
            )}
        </div>
    );
};

export default DataLifecyclePolicies;
