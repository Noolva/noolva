import React, { useState, useEffect, useMemo } from 'react';
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
    Tag,
    Typography,
    Segmented,
    Tooltip,
    Row,
    Col,
    Statistic,
} from 'antd';
import { PlusOutlined, EditOutlined, ReloadOutlined, WarningOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const { Text, Paragraph } = Typography;

const DEST = [
    { value: 'postgres_archive', label: 'Postgres archive table (recommended)' },
    { value: 's3', label: 'S3 JSON export (not in 1.0.6 engine)' },
    { value: 'iceberg', label: 'Iceberg / Parquet export' },
];
const MOVE = [
    { value: 'move', label: 'Move (archive, then purge hot rows)' },
    { value: 'copy', label: 'Copy (archive only, keep hot rows)' },
];
const SYNC = [
    { value: 'FULL', label: 'FULL (re-check all eligible rows)' },
    { value: 'INCREMENTAL', label: 'INCREMENTAL (only newer than last run)' },
];
const TRANSFER = [
    { value: 'time_based', label: 'Older than a time column' },
    { value: 'condition_based', label: 'Matches a SQL condition only' },
    { value: 'time_and_condition', label: 'Older than time column AND matches condition' },
];
const RETENTION_PRESETS = [
    { value: '1y', label: '1 year', interval: "interval '1 year'" },
    { value: '2y', label: '2 years', interval: "interval '2 years'" },
    { value: '3y', label: '3 years', interval: "interval '3 years'" },
    { value: 'custom', label: 'Custom SQL condition', interval: null },
];
const GRACE_PRESETS = [
    { value: 1440, label: '1 day after archive' },
    { value: 10080, label: '7 days after archive' },
    { value: 20160, label: '14 days after archive' },
    { value: 43200, label: '30 days after archive' },
];
const LOOKBACK_PRESETS = [
    { value: 0, label: 'None (strict watermark)' },
    { value: 1440, label: '1 day safety window' },
    { value: 10080, label: '7 days safety window (recommended)' },
    { value: 43200, label: '30 days safety window' },
];

const MODE_ARCHIVE_ONLY = 'archive_only';
const MODE_ARCHIVE_PURGE = 'archive_purge';

function retentionFromFilter(filter) {
    const m = /interval\s+'(\d+)\s+year/i.exec(filter || '');
    if (!m) return 'custom';
    const n = Number(m[1]);
    if (n === 1) return '1y';
    if (n === 2) return '2y';
    if (n === 3) return '3y';
    return 'custom';
}

function retentionWords(filter) {
    const m = /interval\s+'(\d+)\s+year/i.exec(filter || '');
    if (m) {
        const n = Number(m[1]);
        return `older than ${n} year${n === 1 ? '' : 's'}`;
    }
    if (filter && filter.trim()) return `matching \`${filter.trim()}\``;
    return 'all rows';
}

function fmtMin(n) {
    if (n == null) return '—';
    const v = Number(n);
    if (v % 1440 === 0) return v / 1440 === 1 ? 'daily' : `every ${v / 1440} days`;
    if (v % 60 === 0) return `every ${v / 60} hour${v / 60 === 1 ? '' : 's'}`;
    return `every ${v} min`;
}

function fmtDate(v) {
    if (!v) return '—';
    try {
        return new Date(v).toLocaleString();
    } catch {
        return String(v);
    }
}

const PipelineStrip = ({ r }) => (
    <Row gutter={16} style={{ marginBottom: 8 }}>
        <Col span={6}>
            <Statistic
                title="Last archive run"
                value={fmtDate(r.last_archive_batch_at || r.last_archive_completed_at)}
                valueStyle={{ fontSize: 13 }}
            />
        </Col>
        <Col span={6}>
            <Statistic title="Rows archived (total)" value={r.archive_rows_total ?? 0} valueStyle={{ fontSize: 13 }} />
        </Col>
        <Col span={6}>
            <Statistic
                title="Last purge run"
                value={fmtDate(r.last_purge_batch_at || r.last_purge_completed_at)}
                valueStyle={{ fontSize: 13 }}
            />
        </Col>
        <Col span={6}>
            <Statistic title="Rows purged (total)" value={r.purge_rows_total ?? 0} valueStyle={{ fontSize: 13 }} />
        </Col>
    </Row>
);

const DataLifecyclePolicies = () => {
    const [items, setItems] = useState([]);
    const [sourceOptions, setSourceOptions] = useState([]);
    const [loading, setLoading] = useState(false);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form] = Form.useForm();
    const [errorModal, setErrorModal] = useState(null);

    const lifecycleMode = Form.useWatch('lifecycle_mode', form);
    const retentionPreset = Form.useWatch('retention_preset', form);
    const timeColumn = Form.useWatch('time_column', form);
    const table_name = Form.useWatch('table_name', form);
    const destination_type = Form.useWatch('destination_type', form);
    const destination_table = Form.useWatch('destination_table', form);
    const filter_condition = Form.useWatch('filter_condition', form);
    const sync_interval_minutes = Form.useWatch('sync_interval_minutes', form);
    const purge_after_interval_minutes = Form.useWatch('purge_after_interval_minutes', form);
    const lifecycle_root_table = Form.useWatch('lifecycle_root_table', form);
    const movement_type = Form.useWatch('movement_type', form);
    const transfer_mode = Form.useWatch('transfer_mode', form);
    const sync_strategy = Form.useWatch('sync_strategy', form);
    const incremental_lookback_minutes = Form.useWatch('incremental_lookback_minutes', form);

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

    const loadSources = async () => {
        try {
            const data = await api.getLifecycleSourceTableOptions();
            setSourceOptions(data.items || []);
        } catch {
            setSourceOptions([]);
        }
    };

    useEffect(() => {
        load();
        loadSources();
    }, []);

    const preview = useMemo(() => {
        const src = table_name || '<flat table>';
        const destTable = destination_table || (src ? `archived_${src}` : '<archived_table>');
        const when = fmtMin(sync_interval_minutes);
        const what =
            transfer_mode === 'condition_based'
                ? retentionWords(filter_condition)
                : transfer_mode === 'time_and_condition'
                  ? `${timeColumn || 'time column'} is ${retentionWords(filter_condition)}`
                  : `${timeColumn || 'time column'} is old`;
        const incr =
            sync_strategy === 'INCREMENTAL'
                ? ` Only rows not yet archived (newer than the last run${
                      Number(incremental_lookback_minutes) > 0
                          ? `, plus a ${fmtMin(incremental_lookback_minutes)} re-check window for late rows`
                          : ''
                  }) are considered; already-archived rows are never copied twice.`
                : ' All matching rows are re-checked each run (already-archived rows are skipped).';
        let s = `Every ${when}, copy rows from ${src} where ${what} into ${destTable}.${incr}`;
        if (lifecycleMode === MODE_ARCHIVE_PURGE) {
            const grace = purge_after_interval_minutes
                ? fmtMin(purge_after_interval_minutes).replace('after archive', 'after the last archive')
                : 'after the last archive';
            const root = lifecycle_root_table || 'the hot root table';
            s += ` Then, ${grace}, DELETE those rows from the hot tables: ${src}, ${root} and its child tables (e.g. comments, attachments).`;
        } else {
            s += ' Hot rows are kept (archive only).';
        }
        if (destination_type === 's3') {
            s += ' Note: S3 export is not implemented in the 1.0.6 engine — this policy will not move data yet.';
        }
        if (movement_type === 'move') {
            s += ' Movement = move: deletion happens only via the purge step above, never during archive.';
        }
        return s;
    }, [
        table_name,
        destination_table,
        destination_type,
        sync_interval_minutes,
        transfer_mode,
        timeColumn,
        filter_condition,
        lifecycleMode,
        purge_after_interval_minutes,
        lifecycle_root_table,
        movement_type,
        sync_strategy,
        incremental_lookback_minutes,
    ]);

    // Keep filter_condition in sync with the retention preset + time column
    useEffect(() => {
        if (!retentionPreset || retentionPreset === 'custom') return;
        const preset = RETENTION_PRESETS.find((p) => p.value === retentionPreset);
        if (!preset?.interval || !timeColumn) return;
        const next = `${timeColumn} < now() - ${preset.interval}`;
        if (form.getFieldValue('filter_condition') !== next) {
            form.setFieldsValue({ filter_condition: next, transfer_mode: 'time_and_condition' });
        }
    }, [retentionPreset, timeColumn, form]);

    const openAdd = () => {
        setEditing(null);
        form.resetFields();
        form.setFieldsValue({
            pk_column: 'task_id',
            transfer_mode: 'time_and_condition',
            retention_preset: '1y',
            sync_batch_size: 1000,
            sync_interval_minutes: 1440,
            is_active: true,
            movement_type: 'move',
            sync_strategy: 'INCREMENTAL',
            incremental_lookback_minutes: 10080,
            is_public_on_s3: false,
            destination_type: 'postgres_archive',
            lifecycle_mode: MODE_ARCHIVE_ONLY,
            purge_after_interval_minutes: 10080,
        });
        setDrawerOpen(true);
    };

    const openEdit = (r) => {
        setEditing(r);
        form.resetFields();
        form.setFieldsValue({
            ...r,
            lifecycle_mode: r.purge_enabled ? MODE_ARCHIVE_PURGE : MODE_ARCHIVE_ONLY,
            retention_preset: retentionFromFilter(r.filter_condition),
            purge_after_interval_minutes: r.purge_after_interval_minutes ?? 10080,
            incremental_lookback_minutes: r.incremental_lookback_minutes ?? 0,
        });
        setDrawerOpen(true);
    };

    const buildPayload = (v) => {
        const purge = v.lifecycle_mode === MODE_ARCHIVE_PURGE;
        return {
            policy_label: v.policy_label,
            table_name: v.table_name,
            pk_column: v.pk_column || 'id',
            transfer_mode: v.transfer_mode || 'time_based',
            time_column: v.time_column,
            filter_condition: v.filter_condition,
            destination_type: v.destination_type,
            destination_table: v.destination_table,
            is_public_on_s3: v.is_public_on_s3,
            movement_type: purge ? 'move' : v.movement_type,
            sync_strategy: v.sync_strategy,
            incremental_lookback_minutes:
                v.sync_strategy === 'INCREMENTAL' ? (v.incremental_lookback_minutes ?? 0) : null,
            sync_batch_size: v.sync_batch_size,
            sync_interval_minutes: v.sync_interval_minutes,
            is_active: v.is_active,
            archive_source_table: v.archive_source_table,
            purge_enabled: purge,
            purge_after_interval_minutes: purge ? v.purge_after_interval_minutes : null,
            lifecycle_root_table: purge ? v.lifecycle_root_table : null,
        };
    };

    const save = async () => {
        try {
            const v = await form.validateFields();
            const payload = buildPayload(v);
            if (editing) {
                await api.updateDataLifecyclePolicy(editing.id, payload);
                message.success('Updated');
            } else {
                await api.createDataLifecyclePolicy(payload);
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

    const sourceSelectOptions = useMemo(() => {
        const opts = (sourceOptions || []).map((s) => ({
            value: s.target_table_name,
            label: `${s.target_table_name}  ←  ${s.table_name}`,
        }));
        if (table_name && !opts.some((o) => o.value === table_name)) {
            opts.push({ value: table_name, label: table_name });
        }
        return opts;
    }, [sourceOptions, table_name]);

    const cols = [
        { title: 'ID', dataIndex: 'id', width: 60 },
        {
            title: 'Label',
            dataIndex: 'policy_label',
            render: (v, r) => v || r.table_name,
        },
        { title: 'Source (flat)', dataIndex: 'table_name' },
        {
            title: 'Mode',
            key: 'mode',
            render: (_, r) =>
                r.purge_enabled ? (
                    <Tag color="red" icon={<WarningOutlined />}>
                        Archive + purge
                    </Tag>
                ) : (
                    <Tag color="blue">Archive only</Tag>
                ),
        },
        { title: 'Destination', dataIndex: 'destination_table', render: (v) => v || '—' },
        { title: 'Schedule', dataIndex: 'sync_interval_minutes', render: fmtMin },
        {
            title: 'Last archive',
            key: 'la',
            render: (_, r) => fmtDate(r.last_archive_batch_at || r.last_archive_completed_at),
        },
        {
            title: 'Archived rows',
            dataIndex: 'archive_rows_total',
            render: (v) => v ?? 0,
        },
        {
            title: 'Actions',
            key: 'a',
            render: (_, r) => (
                <Space>
                    <Button type="link" icon={<EditOutlined />} onClick={() => openEdit(r)}>
                        Edit
                    </Button>
                    <Popconfirm title="Delete policy? (does not touch already-archived rows)" onConfirm={() => del(r)}>
                        <Button type="link" danger>
                            Delete
                        </Button>
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    const purgeJustEnabled = lifecycleMode === MODE_ARCHIVE_PURGE && (!editing || !editing.purge_enabled);

    const saveBtn = purgeJustEnabled ? (
        <Popconfirm
            title="Enable auto-purge (danger zone)?"
            description={`After archiving, hot rows in ${table_name || 'the flat table'}, ${
                lifecycle_root_table || 'the root table'
            } and child tables will be DELETED.`}
            okText="Yes, enable purge"
            okButtonProps={{ danger: true }}
            onConfirm={save}
        >
            <Button type="primary" danger>
                Save
            </Button>
        </Popconfirm>
    ) : (
        <Button type="primary" onClick={save}>
            Save
        </Button>
    );

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
                    message="How this works (tiered lifecycle)"
                    description={
                        <>
                            <b>1. Flatten</b> — Flattened Datas keeps a wide flat table (e.g. flat_my_tasks) fresh.
                            <br />
                            <b>2. Archive</b> — this page copies old rows from the flat table into an archived_* table
                            (never deletes).
                            <br />
                            <b>3. Purge (optional)</b> — only after rows are verified in the archive, delete them from
                            the hot flat table, the hot root table (e.g. my_tasks) and child tables (comments,
                            attachments). Jobs run via schedulers every 5 minutes; set the interval below to control how
                            often each policy is considered.
                        </>
                    }
                />
                <Button type="primary" icon={<PlusOutlined />} style={{ marginBottom: 12 }} onClick={openAdd}>
                    Add policy
                </Button>
                <Table
                    rowKey="id"
                    loading={loading}
                    columns={cols}
                    dataSource={items}
                    pagination={{ pageSize: 15 }}
                    expandable={{
                        expandedRowRender: (r) => (
                            <div>
                                <PipelineStrip r={r} />
                                <Text type="secondary" style={{ fontSize: 12 }}>
                                    Source: {r.table_name} · PK: {r.pk_column} · Transfer: {r.transfer_mode} · Time
                                    column: {r.time_column || '—'} · Sync: {r.sync_strategy} · Root: {r.lifecycle_root_table || '—'} ·
                                    Purge grace: {r.purge_after_interval_minutes != null ? fmtMin(r.purge_after_interval_minutes) : '—'}
                                </Text>
                            </div>
                        ),
                    }}
                />
            </Card>

            <Drawer
                width={560}
                title={editing ? 'Edit lifecycle policy' : 'Add lifecycle policy'}
                open={drawerOpen}
                onClose={() => setDrawerOpen(false)}
                extra={
                    <Space>
                        <Button onClick={() => setDrawerOpen(false)}>Cancel</Button>
                        {saveBtn}
                    </Space>
                }
            >
                <Form form={form} layout="vertical">
                    <Form.Item
                        name="lifecycle_mode"
                        label="Mode"
                        extra="Archive only = safe. Archive + purge = deletes hot rows after archive (danger zone)."
                    >
                        <Segmented
                            options={[
                                { value: MODE_ARCHIVE_ONLY, label: 'Archive only' },
                                {
                                    value: MODE_ARCHIVE_PURGE,
                                    label: 'Archive + auto-purge (danger zone)',
                                    className: 'danger-segment',
                                },
                            ]}
                        />
                    </Form.Item>

                    {lifecycleMode === MODE_ARCHIVE_PURGE && (
                        <Alert
                            type="error"
                            showIcon
                            style={{ marginBottom: 16 }}
                            message="Auto-purge will DELETE hot data"
                            description={`Rows that match this policy will be removed from the flat table, the hot root table (lifecycle_root_table) and its child tables after the grace period. They stay available in the archived table.`}
                        />
                    )}

                    <Form.Item name="policy_label" label="Policy label" extra="Optional display name.">
                        <Input />
                    </Form.Item>

                    <Form.Item
                        name="table_name"
                        label="Source table (flat table)"
                        rules={[{ required: true }]}
                        extra="Pick a flattening flat target (e.g. flat_my_tasks). Lifecycle sources must be flat tables, not hot roots."
                    >
                        <Select
                            showSearch
                            optionFilterProp="label"
                            disabled={!!editing}
                            placeholder="e.g. flat_my_tasks"
                            options={sourceSelectOptions}
                        />
                    </Form.Item>

                    <Form.Item
                        name="pk_column"
                        label="PK column"
                        extra="Primary key of the source table (e.g. task_id for my_tasks)."
                    >
                        <Input />
                    </Form.Item>

                    <Form.Item name="transfer_mode" label="What counts as 'old'?" rules={[{ required: true }]}>
                        <Select options={TRANSFER} />
                    </Form.Item>

                    {transfer_mode !== 'condition_based' && (
                        <Form.Item
                            name="time_column"
                            label="Time column"
                            rules={[{ required: true, message: 'Time column is required for time-based modes' }]}
                            extra="e.g. completed_at for finished tasks, idate as fallback."
                        >
                            <Input />
                        </Form.Item>
                    )}

                    <Form.Item
                        name="retention_preset"
                        label="Retention (archive age)"
                        extra="Writes the filter below automatically. Choose Custom to write your own SQL."
                    >
                        <Select options={RETENTION_PRESETS} />
                    </Form.Item>

                    <Form.Item
                        name="filter_condition"
                        label="Filter SQL (advanced)"
                        extra="SQL fragment evaluated per row; must be safe (no semicolons). Preset fills this for you."
                    >
                        <Input.TextArea rows={2} />
                    </Form.Item>

                    <Form.Item
                        name="destination_type"
                        label="Archive destination"
                        rules={[{ required: true }]}
                    >
                        <Select options={DEST} />
                    </Form.Item>

                    <Form.Item
                        name="destination_table"
                        label="Archive table"
                        extra="Leave empty to auto-use archived_<source> (e.g. archived_flat_my_tasks)."
                    >
                        <Input placeholder={table_name ? `archived_${table_name}` : 'archived_...'} />
                    </Form.Item>

                    {destination_type === 's3' && (
                        <Form.Item name="is_public_on_s3" label="S3 public prefix" valuePropName="checked">
                            <Switch />
                        </Form.Item>
                    )}

                    <Form.Item name="movement_type" label="Movement" rules={[{ required: true }]}>
                        <Select options={MOVE} />
                    </Form.Item>

                    <Form.Item
                        name="sync_strategy"
                        label="Sync strategy"
                        rules={[{ required: true }]}
                        extra="INCREMENTAL (recommended): only process rows newer than the last run — scales to millions of rows. FULL: re-check every eligible row each run (small tables / debugging)."
                    >
                        <Select options={SYNC} />
                    </Form.Item>

                    {sync_strategy === 'INCREMENTAL' && (
                        <Form.Item
                            name="incremental_lookback_minutes"
                            label="Late-row safety window"
                            extra="Re-checks rows newer than (last run − window) so late or edited timestamps are still caught. Already-archived rows are skipped by PK dedupe, so overlap is safe."
                        >
                            <Select options={LOOKBACK_PRESETS} />
                        </Form.Item>
                    )}

                    <Form.Item
                        name="sync_batch_size"
                        label="Batch size (rows per run)"
                        extra="Maximum rows copied per operation. Each scheduler run processes up to this many, then continues from where it left off — and keeps going (up to 10 batches) until caught up."
                    >
                        <InputNumber min={1} style={{ width: '100%' }} />
                    </Form.Item>

                    <Form.Item
                        name="sync_interval_minutes"
                        label="How often to scan (minutes)"
                        extra="Scheduler checks every 5 min; this controls how old the last run may be. 1440 = daily."
                    >
                        <InputNumber min={1} style={{ width: '100%' }} />
                    </Form.Item>

                    {lifecycleMode === MODE_ARCHIVE_PURGE && (
                        <>
                            <Form.Item
                                name="lifecycle_root_table"
                                label="Hot root table"
                                rules={[{ required: true, message: 'Required for purge' }]}
                                extra="The live/hot table whose rows (and children) are deleted after archive — e.g. my_tasks."
                            >
                                <Input placeholder="my_tasks" />
                            </Form.Item>
                            <Form.Item
                                name="purge_after_interval_minutes"
                                label="Delete hot rows…"
                                rules={[{ required: true, message: 'Required for purge' }]}
                                extra="Grace period after the last successful archive batch."
                            >
                                <Select options={GRACE_PRESETS} />
                            </Form.Item>
                        </>
                    )}

                    <Form.Item name="is_active" label="Active" valuePropName="checked">
                        <Switch />
                    </Form.Item>

                    <Alert
                        type="success"
                        showIcon
                        style={{ marginTop: 8 }}
                        message="What this policy will do (plain English)"
                        description={<Paragraph style={{ whiteSpace: 'pre-wrap', marginBottom: 0 }}>{preview}</Paragraph>}
                    />
                </Form>
            </Drawer>

            {errorModal && (
                <ErrorModal visible={!!errorModal} error={errorModal} onClose={() => setErrorModal(null)} />
            )}
        </div>
    );
};

export default DataLifecyclePolicies;
