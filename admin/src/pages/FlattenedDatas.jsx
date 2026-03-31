import React, { useMemo, useState, useEffect } from 'react';
import {
    Card,
    Table,
    Button,
    Space,
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
    Typography,
} from 'antd';
import { PlusOutlined, EditOutlined, ReloadOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const { Text } = Typography;

const REFRESH_OPTIONS = [
    { value: 'FULL', label: 'FULL' },
    { value: 'INCREMENTAL', label: 'INCREMENTAL' },
];

const FlattenedDatas = () => {
    const [tablePolicies, setTablePolicies] = useState([]);
    const [relationPolicies, setRelationPolicies] = useState([]); // cached for counts
    const [dataModels, setDataModels] = useState([]);
    const [loading, setLoading] = useState(false);
    const [errorModal, setErrorModal] = useState(null);
    const [tableDrawerOpen, setTableDrawerOpen] = useState(false);
    const [relationListDrawerOpen, setRelationListDrawerOpen] = useState(false);
    const [relationEditDrawerOpen, setRelationEditDrawerOpen] = useState(false);
    const [activeTableName, setActiveTableName] = useState(null);
    const [editingTable, setEditingTable] = useState(null);
    const [editingRelation, setEditingRelation] = useState(null);
    const [relationCandidates, setRelationCandidates] = useState([]); // normalized candidates from API
    const [targetModelFields, setTargetModelFields] = useState([]); // [{ value,label }]
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

    const loadDataModels = async () => {
        try {
            const limit = 500;
            let offset = 0;
            const all = [];
            // eslint-disable-next-line no-constant-condition
            while (true) {
                const resp = await api.getDataModels({ limit, offset });
                const batch = resp.data_models || [];
                all.push(...batch);
                offset += batch.length;
                if (!resp.has_more || batch.length === 0) break;
            }
            all.sort((a, b) => (a.model_name || '').localeCompare(b.model_name || ''));
            setDataModels(all);
        } catch (e) {
            message.error(e.message || 'Failed to load data models');
            if (e.errorData) setErrorModal(e);
        }
    };

    useEffect(() => {
        loadTables();
        loadRelations();
        loadDataModels();
    }, []);

    const relCountByTable = useMemo(() => {
        const m = {};
        for (const r of relationPolicies || []) {
            const tn = r?.table_name;
            if (!tn) continue;
            m[tn] = (m[tn] || 0) + 1;
        }
        return m;
    }, [relationPolicies]);

    const openAddTable = () => {
        setEditingTable(null);
        form.resetFields();
        form.setFieldsValue({
            refresh_strategy: 'FULL',
            is_active: true,
        });
        setActiveTableName(null);
        setTableDrawerOpen(true);
    };

    const openEditTable = (record) => {
        setEditingTable(record);
        form.setFieldsValue({
            ...record,
            refresh_strategy: record.refresh_strategy || undefined,
        });
        setActiveTableName(record?.table_name || null);
        setTableDrawerOpen(true);
    };

    const openRelationDrawer = async (tableName) => {
        try {
            setActiveTableName(tableName);
            setEditingRelation(null);
            relForm.resetFields();
            setRelationListDrawerOpen(true);
            setRelationCandidates([]);
            setTargetModelFields([]);
            const data = await api.getFlatteningRelationPolicies(tableName);
            // Keep global cache fresh too (for counts)
            const next = Array.isArray(data.items) ? data.items : [];
            setRelationPolicies((prev) => {
                const other = (prev || []).filter((x) => x?.table_name !== tableName);
                return [...other, ...next];
            });
            const cand = await api.getFlatteningRelationCandidates(tableName);
            const out = Array.isArray(cand.outgoing) ? cand.outgoing : [];
            const inc = Array.isArray(cand.incoming) ? cand.incoming : [];
            setRelationCandidates([...out, ...inc]);
        } catch (e) {
            message.error(e.response?.data?.detail || e.message || 'Failed to load relation policies');
            if (e.errorData) setErrorModal(e);
        }
    };

    const saveTable = async () => {
        try {
            const v = await form.validateFields();
            const payload = { ...v, is_snapshot: false };
            if (!payload.batch_size) payload.batch_size = null;
            if (editingTable) {
                await api.updateFlatteningTablePolicy(editingTable.id, payload);
                message.success('Updated');
            } else {
                const res = await api.createFlatteningTablePolicy(payload);
                message.success('Created');
                if (res.read_endpoints?.length) {
                    message.info(`Read APIs: ${res.read_endpoints.join('; ')}`);
                }
            }
            setTableDrawerOpen(false);
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
        relForm.setFieldsValue({
            table_name: activeTableName,
            is_required: false,
            relation_type: 'm2o',
            strategy: 'denormalize',
        });
        setRelationEditDrawerOpen(true);
    };

    const openEditRelation = (record) => {
        setEditingRelation(record);
        relForm.setFieldsValue({
            ...record,
            include_fields: Array.isArray(record.include_fields) ? record.include_fields : [],
        });
        setRelationEditDrawerOpen(true);
    };

    const maybeLoadTargetFields = async (relationName) => {
        const cand = (relationCandidates || []).find((c) => c.key === relationName);
        const targetModelName = cand?.target_model;
        if (!targetModelName) {
            setTargetModelFields([]);
            return;
        }
        const target = (dataModels || []).find((m) => m?.model_name === targetModelName || m?.table_name === targetModelName);
        if (!target?.model_id) {
            setTargetModelFields([]);
            return;
        }
        try {
            const dm = await api.getDataModel(target.model_id, true);
            const fields = Array.isArray(dm.fields) ? dm.fields : [];
            const sys = new Set(['idate', 'created_by', 'last_updated', 'row_exposure_mode_id', 'deleted_at']);
            const opts = fields
                .filter((f) => !sys.has(f.field_name) && (f.type_code || '').toLowerCase() !== 'relation')
                .map((f) => ({ value: f.field_name, label: `${f.field_name}${f.display_name ? ` — ${f.display_name}` : ''}` }));
            setTargetModelFields(opts);

            // Default include_fields to name/title/display_name if present (only for denormalize)
            const preferred = ['display_name', 'name', 'title', 'code', 'email'];
            const found = preferred.filter((p) => opts.some((o) => o.value === p)).slice(0, 3);
            if (found.length) {
                relForm.setFieldsValue({ include_fields: found });
            }
        } catch (e) {
            setTargetModelFields([]);
        }
    };

    const saveRelation = async () => {
        try {
            const v = await relForm.validateFields();
            const payload = {
                ...v,
                include_fields: Array.isArray(v.include_fields) ? v.include_fields.filter(Boolean) : undefined,
            };
            if (editingRelation) {
                await api.updateFlatteningRelationPolicy(editingRelation.id, payload);
                message.success('Updated');
            } else {
                await api.createFlatteningRelationPolicy(payload);
                message.success('Created');
            }
            setRelationEditDrawerOpen(false);
            await openRelationDrawer(activeTableName);
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
            await openRelationDrawer(activeTableName);
        } catch (e) {
            message.error(e.response?.data?.detail || e.message);
        }
    };

    const tableCols = [
        { title: 'ID', dataIndex: 'id', width: 70 },
        { title: 'Table', dataIndex: 'table_name' },
        {
            title: 'Relation policies',
            key: 'rels',
            render: (_, r) => {
                const tn = r?.table_name;
                const c = relCountByTable[tn] || 0;
                return (
                    <Button type="link" onClick={() => openRelationDrawer(tn)}>
                        {c} policy{c === 1 ? '' : 'ies'}
                    </Button>
                );
            },
        },
        {
            title: 'Strategy',
            dataIndex: 'refresh_strategy',
            render: (t) => t || <Tag color="default">legacy</Tag>,
        },
        { title: 'Interval (min)', dataIndex: 'refresh_interval_minutes' },
        { title: 'Active', dataIndex: 'is_active', render: (v) => (v ? 'Yes' : 'No') },
        {
            title: 'Actions',
            key: 'a',
            render: (_, r) => (
                <Space>
                    <Button type="link" icon={<EditOutlined />} onClick={() => openEditTable(r)}>
                        Edit
                    </Button>
                    <Button type="link" onClick={() => openRelationDrawer(r.table_name)}>
                        Relations
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
        { title: 'Relation', dataIndex: 'relation_name' },
        { title: 'Type', dataIndex: 'relation_type' },
        { title: 'Strategy', dataIndex: 'strategy' },
        { title: 'Target table', dataIndex: 'target_table' },
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
                <Button type="primary" icon={<PlusOutlined />} style={{ marginBottom: 12 }} onClick={openAddTable}>
                    Add table policy
                </Button>
                <Table rowKey="id" loading={loading} columns={tableCols} dataSource={tablePolicies} pagination={{ pageSize: 20 }} />
            </Card>

            {/* Drawer 1: Table policy add/edit */}
            <Drawer
                width={480}
                title={editingTable ? 'Edit table policy' : 'Add table policy'}
                open={tableDrawerOpen}
                onClose={() => setTableDrawerOpen(false)}
                extra={
                    <Space>
                        <Button onClick={() => setTableDrawerOpen(false)}>Close</Button>
                        <Button type="primary" onClick={saveTable}>
                            Save
                        </Button>
                    </Space>
                }
            >
                <Form form={form} layout="vertical">
                    <Form.Item
                        name="table_name"
                        label="Table name (Data Model)"
                        rules={[{ required: true }]}
                        extra="Select a Data Model table. GET-only Auto CRUD endpoints are created for this model."
                    >
                        <Select
                            showSearch
                            optionFilterProp="label"
                            disabled={!!editingTable}
                            placeholder={dataModels?.length ? 'Select a Data Model table' : 'Loading data models…'}
                            options={(dataModels || [])
                                .map((m) => ({
                                    value: m.table_name,
                                    label: `${m.table_name}${m.display_name ? ` — ${m.display_name}` : ''}`,
                                }))
                                .filter((o) => !!o.value)}
                        />
                    </Form.Item>
                    <Form.Item name="refresh_strategy" label="Refresh strategy">
                        <Select allowClear options={REFRESH_OPTIONS} />
                    </Form.Item>
                    <Form.Item noStyle shouldUpdate={(prev, cur) => prev.refresh_strategy !== cur.refresh_strategy}>
                        {({ getFieldValue }) => {
                            const strat = getFieldValue('refresh_strategy');
                            if (!strat) return null;
                            return (
                                <>
                                    <Form.Item
                                        name="refresh_interval_minutes"
                                        label="Interval (minutes)"
                                        rules={[{ required: true, message: 'Interval is required' }]}
                                    >
                                        <InputNumber min={1} style={{ width: '100%' }} />
                                    </Form.Item>
                                    {strat === 'INCREMENTAL' && (
                                        <Form.Item name="batch_size" label="Batch size" extra="Optional; used by the refresh job engine later.">
                                            <InputNumber min={1} style={{ width: '100%' }} />
                                        </Form.Item>
                                    )}
                                </>
                            );
                        }}
                    </Form.Item>
                    <Form.Item name="is_active" label="Active" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                </Form>
            </Drawer>

            {/* Drawer 2: Relation policy list (stays open) */}
            <Drawer
                width={720}
                title={`Relation policies — ${activeTableName || ''}`}
                open={relationListDrawerOpen}
                onClose={() => {
                    setRelationListDrawerOpen(false);
                    setRelationEditDrawerOpen(false);
                    setEditingRelation(null);
                }}
                extra={
                    <Space>
                        <Button type="primary" icon={<PlusOutlined />} onClick={openAddRelation}>
                            Add relation policy
                        </Button>
                    </Space>
                }
            >
                <div style={{ marginBottom: 8 }}>
                    <Text type="secondary">Parent table: </Text>
                    <Text strong>{activeTableName}</Text>
                </div>
                <Table
                    rowKey="id"
                    columns={relCols}
                    dataSource={(relationPolicies || []).filter((x) => x?.table_name === activeTableName)}
                    pagination={{ pageSize: 10 }}
                />
            </Drawer>

            {/* Drawer 3: Relation policy add/edit (opens on top, list remains visible) */}
            <Drawer
                width={520}
                title={editingRelation ? `Edit relation policy — ${activeTableName || ''}` : `Add relation policy — ${activeTableName || ''}`}
                open={relationEditDrawerOpen}
                mask={false}
                onClose={() => {
                    setRelationEditDrawerOpen(false);
                    setEditingRelation(null);
                }}
                extra={
                    <Space>
                        <Button onClick={() => setRelationEditDrawerOpen(false)}>Close</Button>
                        <Button type="primary" onClick={saveRelation}>
                            Save
                        </Button>
                    </Space>
                }
            >
                <Form form={relForm} layout="vertical">
                    <Form.Item name="table_name" label="Flattening table name" rules={[{ required: true }]} extra="Parent row in table policies.">
                        <Input disabled />
                    </Form.Item>
                    <Form.Item
                        name="relation_name"
                        label="Relation name (FK field)"
                        rules={[{ required: true }]}
                        extra="Auto populated from Data Model relation fields; you can also type a custom name."
                    >
                        <Select
                            showSearch
                            disabled={!!editingRelation}
                            placeholder={relationCandidates?.length ? 'Select relation field' : 'No relation fields found (check Data Model fields)'}
                            options={(relationCandidates || []).map((c) => ({
                                value: c.key,
                                label: c.label || c.key,
                            }))}
                            onChange={(val) => {
                                const c = (relationCandidates || []).find((x) => x.key === val);
                                const rt = c?.suggested_relation_type || 'm2o';
                                const st = c?.suggested_strategy || (rt === 'o2m' ? 'json' : 'denormalize');
                                relForm.setFieldsValue({
                                    relation_type: rt,
                                    strategy: st,
                                    target_table: null,
                                    include_fields: [],
                                });
                                if (rt === 'm2o') {
                                    maybeLoadTargetFields(val);
                                } else {
                                    setTargetModelFields([]);
                                }
                            }}
                        />
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
                    <Form.Item noStyle shouldUpdate={(p, c) => p.strategy !== c.strategy || p.relation_type !== c.relation_type}>
                        {({ getFieldValue }) => {
                            const st = getFieldValue('strategy');
                            if (st !== 'denormalize') return null;
                            return (
                                <Form.Item
                                    name="include_fields"
                                    label="Include fields (denormalize)"
                                    extra="Auto suggested from target model fields; you can adjust."
                                >
                                    <Select
                                        mode="multiple"
                                        allowClear
                                        options={targetModelFields}
                                        placeholder={targetModelFields?.length ? 'Select fields to copy' : 'Select relation first to load fields'}
                                    />
                                </Form.Item>
                            );
                        }}
                    </Form.Item>
                    <Form.Item name="target_table" label="Target table (separate)" extra="Required when strategy = separate.">
                        <Input />
                    </Form.Item>
                    <Form.Item name="is_required" label="Required" valuePropName="checked">
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

export default FlattenedDatas;
