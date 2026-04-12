import React, { useState, useEffect, useCallback } from 'react';
import {
    Card,
    Table,
    Button,
    Space,
    Modal,
    Form,
    Input,
    InputNumber,
    Switch,
    Tabs,
    Alert,
    Typography,
    message,
    Drawer,
    Select,
    Popconfirm,
    Row,
    Col,
    Spin,
} from 'antd';
import {
    PlusOutlined,
    CopyOutlined,
    EyeOutlined,
    EditOutlined,
    ReloadOutlined,
    BookOutlined,
    DownloadOutlined,
} from '@ant-design/icons';
import { api } from '../utils/api';
import { resolveApiBaseUrl } from '../config/runtimeApi';
import ErrorModal from '../components/ErrorModal';

const { Text, Paragraph } = Typography;

const SOURCE_KINDS = [
    { value: 'hot_auto_crud_get', label: 'HOT — Auto CRUD GET (live model)' },
    { value: 'flattened_api_get', label: 'Flattened API GET' },
    { value: 'flattened_s3', label: 'Flattened S3 JSON' },
];

/** Noolva HOT models use `last_updated` for row change tracking; manifest incremental sync uses this name. */
const DEFAULT_INCREMENTAL_FIELD = 'last_updated';

/** Client dataset_key matches the physical table name (normalized lowercase). */
function datasetKeyFromTableName(tableName) {
    const s = String(tableName || '').trim();
    return s ? s.toLowerCase() : '';
}

function getApiBaseAbsolute() {
    const base = resolveApiBaseUrl().replace(/\/+$/, '');
    if (/^https?:\/\//i.test(base)) return base;
    if (typeof window !== 'undefined' && window.location?.origin) {
        const origin = window.location.origin.replace(/\/$/, '');
        return `${origin}${base.startsWith('/') ? '' : '/'}${base}`;
    }
    return base;
}

function safeHandoutFileSegment(s) {
    const t = String(s || 'instance')
        .replace(/[^a-zA-Z0-9._-]+/g, '_')
        .replace(/^_+|_+$/g, '')
        .slice(0, 48);
    return t || 'instance';
}

function downloadTextFile(filename, text) {
    const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.rel = 'noopener';
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
}

function buildDeveloperHandoutText({ instance, apiBaseAbsolute, manifest, manifestError }) {
    const uuid = instance.instance_uuid;
    const ref = uuid;
    const lines = [
        '================================================================================',
        'NOOLVA — CLIENT INSTANCE DEVELOPER HANDOUT',
        '================================================================================',
        `Generated (UTC): ${new Date().toISOString()}`,
        '',
        'WHAT THIS FILE IS',
        '-----------------',
        'Share this text file with engineers building the native or hybrid app that syncs',
        'with this Noolva instance (offline manifest, schema pack, optional S3 snapshots).',
        'It is not for end users. Treat URLs, UUIDs, and manifest contents as confidential.',
        '',
        'Full protocol and sync guidance: docs/client_offline_sync.md (in the Noolva repo).',
        '',
        'INSTANCE',
        '--------',
        `Name: ${instance.name ?? ''}`,
        `instance_id (numeric, also valid as instance_ref): ${instance.instance_id}`,
        `instance_uuid (recommended instance_ref in URLs): ${uuid}`,
        `company_id (access control; null = see server rules in docs): ${instance.company_id ?? 'null'}`,
        '',
        'OFFLINE SETTINGS (from console; manifest is authoritative at runtime)',
        '-----------------------------------------------------------------------',
        `enable_offline_data: ${instance.enable_offline_data ? 'true' : 'false'}`,
        `schema_pack_version: ${instance.schema_pack_version ?? ''}`,
        '',
        'API BASE (JSON routes; paths are under this prefix)',
        '----------------------------------------------------',
        apiBaseAbsolute,
        '',
        'AUTHENTICATION',
        '---------------',
        'Header on every request:',
        '  Authorization: Bearer <JWT or Personal Access Token>',
        'Use least-privilege PATs in production. Same pattern as POST /api/upload.',
        '',
        'ENDPOINTS (replace {instance_ref} with instance_uuid above)',
        '------------------------------------------------------------',
        `GET ${apiBaseAbsolute}/instances/${ref}/offline/manifest`,
        `GET ${apiBaseAbsolute}/instances/${ref}/offline/schema-pack`,
        '  (requires enable_offline_data on the instance)',
        `GET ${apiBaseAbsolute}/instances/${ref}/offline/snapshot-url?dataset_key=<dataset_key>`,
        '  (requires enable_offline_data; dataset_key values appear in the manifest under datasets)',
        '',
        'MANIFEST SNAPSHOT',
        '-----------------',
    ];
    if (manifestError) {
        lines.push(`(Manifest could not be loaded for this download: ${manifestError})`);
        lines.push('Fetch GET .../manifest yourself with a token that can access this instance.');
    } else {
        lines.push(JSON.stringify(manifest, null, 2));
    }
    lines.push(
        '',
        'NOTES',
        '-----',
        '- Poll the manifest on a schedule; compare schema_pack_version and S3 watermarks',
        '  before downloading large snapshots.',
        '- incremental_field in datasets is typically last_updated for HOT/flattened reads.',
        '- Offline writes only go through allowlisted Auto CRUD routes from the manifest.',
        ''
    );
    return lines.join('\n');
}

function onDatasetSourceKindChange(datasetForm, v) {
    if (v === 'hot_auto_crud_get') {
        datasetForm.setFieldsValue({ flattening_policy_id: undefined, read_endpoint_id: undefined });
    } else if (v === 'flattened_api_get') {
        datasetForm.setFieldsValue({ flattening_policy_id: undefined, read_endpoint_id: undefined });
    } else if (v === 'flattened_s3') {
        datasetForm.setFieldsValue({ flattening_policy_id: undefined, read_endpoint_id: undefined, model_id: undefined });
    }
}

const OPERATOR_GUIDE = (
    <div>
        <Paragraph>
            <strong>What is an instance?</strong> One row = one logical client product (e.g. &quot;Contacts&quot; vs
            &quot;Password vault&quot;). All platforms (iOS, Android, web, desktop) for that product share the{' '}
            <em>same</em> configuration.
        </Paragraph>
        <Paragraph>
            <strong>Read datasets</strong> describe what the app may cache locally (HOT lists, flattened GET routes, or S3
            JSON). <strong>Offline write allowlist</strong> lists specific POST/PUT/PATCH/DELETE Auto CRUD routes that may
            be replayed from a local outbox — never whole modules.
        </Paragraph>
        <Paragraph>
            <strong>Company</strong>: if set, only users (and PATs) with the same <code>company_id</code> can call client
            manifest/schema/snapshot APIs. Leave empty only if you understand the security trade-off (any authenticated
            caller in this deployment).
        </Paragraph>
        <Paragraph>
            Client integration reference: <Text code>docs/client_offline_sync.md</Text> in the Noolva repo.
        </Paragraph>
    </div>
);

const ClientInstances = () => {
    const [instances, setInstances] = useState([]);
    const [loading, setLoading] = useState(false);
    const [errorModal, setErrorModal] = useState(null);
    const [createOpen, setCreateOpen] = useState(false);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [activeInstance, setActiveInstance] = useState(null);
    const [datasets, setDatasets] = useState([]);
    const [writeEps, setWriteEps] = useState([]);
    const [s3Policies, setS3Policies] = useState([]);
    const [writeCandidates, setWriteCandidates] = useState([]);
    const [manifestPreview, setManifestPreview] = useState(null);
    const [handoutDownloading, setHandoutDownloading] = useState(false);
    const [createForm] = Form.useForm();
    const [settingsForm] = Form.useForm();
    const [datasetForm] = Form.useForm();
    const [writeForm] = Form.useForm();
    const [datasetModalOpen, setDatasetModalOpen] = useState(false);
    const [editingDataset, setEditingDataset] = useState(null);
    const [writeModalOpen, setWriteModalOpen] = useState(false);
    const [dataModelOptions, setDataModelOptions] = useState([]);
    const [loadingDataModels, setLoadingDataModels] = useState(false);
    const [postgresFlattenPolicies, setPostgresFlattenPolicies] = useState([]);
    const [loadingPostgresPolicies, setLoadingPostgresPolicies] = useState(false);

    const loadInstances = useCallback(async () => {
        try {
            setLoading(true);
            const data = await api.listClientInstances();
            setInstances(Array.isArray(data) ? data : []);
        } catch (e) {
            message.error(e.message || 'Failed to load instances');
            if (e.errorData) setErrorModal(e);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        loadInstances();
    }, [loadInstances]);

    const openDrawer = async (row) => {
        setActiveInstance(row);
        setDrawerOpen(true);
        settingsForm.setFieldsValue({
            enable_offline_data: !!row.enable_offline_data,
            schema_pack_version: row.schema_pack_version || '1',
            operator_notes: row.operator_notes || '',
        });
        try {
            const [ds, we, pol] = await Promise.all([
                api.listClientInstanceDatasets(row.instance_id),
                api.listClientInstanceWriteEndpoints(row.instance_id),
                api.helperFlatteningS3Policies(),
            ]);
            setDatasets(Array.isArray(ds) ? ds : []);
            setWriteEps(Array.isArray(we) ? we : []);
            setS3Policies(Array.isArray(pol) ? pol : []);
        } catch (e) {
            message.error(e.message || 'Failed to load instance detail');
            if (e.errorData) setErrorModal(e);
        }
    };

    const saveSettings = async () => {
        if (!activeInstance) return;
        try {
            const v = await settingsForm.validateFields();
            await api.updateClientInstanceOfflineSettings(activeInstance.instance_id, v);
            message.success('Offline settings saved');
            loadInstances();
            const updated = await api.getClientInstance(activeInstance.instance_id);
            setActiveInstance(updated);
        } catch (e) {
            if (e?.errorFields) return;
            message.error(e.message || 'Save failed');
            if (e.errorData) setErrorModal(e);
        }
    };

    const onCreate = async () => {
        try {
            const v = await createForm.validateFields();
            await api.createClientInstance({
                name: v.name.trim(),
                description: v.description?.trim() || null,
                company_id: v.company_id ?? null,
            });
            message.success('Instance created');
            setCreateOpen(false);
            createForm.resetFields();
            loadInstances();
        } catch (e) {
            if (e?.errorFields) return;
            message.error(e.message || 'Create failed');
            if (e.errorData) setErrorModal(e);
        }
    };

    const copyText = (t) => {
        navigator.clipboard.writeText(t);
        message.success('Copied');
    };

    const previewManifest = async () => {
        if (!activeInstance) return;
        try {
            const m = await api.getClientOfflineManifest(String(activeInstance.instance_id));
            setManifestPreview(JSON.stringify(m, null, 2));
        } catch (e) {
            message.error(e.message || 'Manifest preview failed');
            if (e.errorData) setErrorModal(e);
        }
    };

    const downloadDeveloperHandout = async () => {
        if (!activeInstance) return;
        const apiBaseAbsolute = getApiBaseAbsolute();
        const uuid = activeInstance.instance_uuid;
        const fname = `noolva-handout-${safeHandoutFileSegment(activeInstance.name)}-${String(uuid).slice(0, 8)}.txt`;
        try {
            setHandoutDownloading(true);
            let manifest = null;
            let manifestError = null;
            try {
                manifest = await api.getClientOfflineManifest(String(uuid));
            } catch (e) {
                manifestError = e.message || 'Request failed';
                message.warning('Handout saved without live manifest — see note inside the file.');
            }
            const text = buildDeveloperHandoutText({
                instance: activeInstance,
                apiBaseAbsolute,
                manifest,
                manifestError,
            });
            downloadTextFile(fname, text);
            message.success('Developer handout downloaded');
        } catch (e) {
            message.error(e.message || 'Download failed');
            if (e.errorData) setErrorModal(e);
        } finally {
            setHandoutDownloading(false);
        }
    };

    const loadDataModelPicker = useCallback(async () => {
        try {
            setLoadingDataModels(true);
            const models = await api.helperDataModelsForInstances({ limit: 300 });
            setDataModelOptions(Array.isArray(models) ? models : []);
        } catch {
            setDataModelOptions([]);
        } finally {
            setLoadingDataModels(false);
        }
    }, []);

    const loadPostgresFlattenPolicies = useCallback(async () => {
        try {
            setLoadingPostgresPolicies(true);
            const rows = await api.helperFlatteningPostgresPolicies();
            setPostgresFlattenPolicies(Array.isArray(rows) ? rows : []);
        } catch {
            setPostgresFlattenPolicies([]);
        } finally {
            setLoadingPostgresPolicies(false);
        }
    }, []);

    const openDatasetModal = async (rec) => {
        setEditingDataset(rec || null);
        if (rec) {
            let lc = rec.local_lifecycle_jsonb;
            if (typeof lc === 'object') lc = JSON.stringify(lc, null, 2);
            const base = { ...rec, local_lifecycle_jsonb: lc || '{}' };
            if (rec.source_kind === 'flattened_api_get') {
                delete base.model_id;
            }
            datasetForm.setFieldsValue(base);
        } else {
            datasetForm.resetFields();
            datasetForm.setFieldsValue({
                source_kind: 'hot_auto_crud_get',
                is_active: true,
                local_lifecycle_jsonb: '{}',
            });
        }
        setDatasetModalOpen(true);
        loadDataModelPicker();
        loadPostgresFlattenPolicies();
    };

    const saveDataset = async () => {
        if (!activeInstance) return;
        try {
            const v = await datasetForm.validateFields();
            let lc = {};
            try {
                lc = v.local_lifecycle_jsonb ? JSON.parse(v.local_lifecycle_jsonb) : {};
            } catch {
                message.error('Local lifecycle must be valid JSON');
                return;
            }
            const useIncremental =
                v.source_kind === 'hot_auto_crud_get' ||
                v.source_kind === 'flattened_api_get' ||
                v.source_kind === 'flattened_s3';

            let modelId = v.model_id ?? null;
            let flatteningPolicyId = v.flattening_policy_id ?? null;
            let resolvedTableName = '';
            if (v.source_kind === 'hot_auto_crud_get') {
                flatteningPolicyId = null;
                const m = dataModelOptions.find((x) => x.model_id === v.model_id);
                resolvedTableName = m?.table_name || '';
            } else if (v.source_kind === 'flattened_api_get') {
                const p = postgresFlattenPolicies.find((x) => x.flattening_policy_id === flatteningPolicyId);
                modelId = p?.model_id ?? null;
                resolvedTableName = p?.table_name || '';
                if (flatteningPolicyId == null || modelId == null) {
                    message.error('Select a Postgres flattening table');
                    return;
                }
            } else if (v.source_kind === 'flattened_s3') {
                modelId = null;
                if (flatteningPolicyId == null) {
                    message.error('Select an S3 flattening policy');
                    return;
                }
                const pol = s3Policies.find((x) => x.id === flatteningPolicyId);
                resolvedTableName = pol?.table_name || '';
            }

            if (!resolvedTableName && editingDataset) {
                const sameHot =
                    v.source_kind === 'hot_auto_crud_get' &&
                    Number(editingDataset.model_id) === Number(v.model_id);
                const sameFlat =
                    v.source_kind === 'flattened_api_get' &&
                    Number(editingDataset.flattening_policy_id) === Number(flatteningPolicyId);
                const sameS3 =
                    v.source_kind === 'flattened_s3' &&
                    Number(editingDataset.flattening_policy_id) === Number(flatteningPolicyId);
                if (sameHot || sameFlat || sameS3) {
                    resolvedTableName = editingDataset.dataset_key || '';
                }
            }

            const datasetKey = datasetKeyFromTableName(resolvedTableName);
            if (!datasetKey) {
                message.error('Could not determine dataset key from the selected table');
                return;
            }

            const payload = {
                dataset_key: datasetKey,
                label: null,
                source_kind: v.source_kind,
                model_id: modelId,
                flattening_policy_id: flatteningPolicyId,
                read_endpoint_id: null,
                incremental_field: useIncremental ? DEFAULT_INCREMENTAL_FIELD : null,
                batch_size: v.batch_size ?? null,
                local_lifecycle_jsonb: lc,
                is_active: v.is_active !== false,
            };
            if (editingDataset) {
                await api.updateClientInstanceDataset(activeInstance.instance_id, editingDataset.id, payload);
                message.success('Dataset updated');
            } else {
                await api.createClientInstanceDataset(activeInstance.instance_id, payload);
                message.success('Dataset added');
            }
            setDatasetModalOpen(false);
            const ds = await api.listClientInstanceDatasets(activeInstance.instance_id);
            setDatasets(Array.isArray(ds) ? ds : []);
        } catch (e) {
            if (e?.errorFields) return;
            message.error(e.message || 'Save dataset failed');
            if (e.errorData) setErrorModal(e);
        }
    };

    const loadWriteCandidates = async (q) => {
        try {
            const rows = await api.helperAutoCrudWriteEndpoints({ q, limit: 100 });
            setWriteCandidates(
                (rows || []).map((r) => ({
                    value: r.endpoint_id,
                    label: `${r.method} ${r.path}${r.model_name ? ` — ${r.model_name}` : ''}`,
                }))
            );
        } catch {
            setWriteCandidates([]);
        }
    };

    const openWriteModal = () => {
        writeForm.resetFields();
        setWriteModalOpen(true);
        loadWriteCandidates('');
    };

    const saveWriteEndpoint = async () => {
        if (!activeInstance) return;
        try {
            const v = await writeForm.validateFields();
            await api.createClientInstanceWriteEndpoint(activeInstance.instance_id, {
                endpoint_id: v.endpoint_id,
                notes: v.notes?.trim() || null,
                is_active: true,
            });
            message.success('Write endpoint allowlisted');
            setWriteModalOpen(false);
            const we = await api.listClientInstanceWriteEndpoints(activeInstance.instance_id);
            setWriteEps(Array.isArray(we) ? we : []);
        } catch (e) {
            if (e?.errorFields) return;
            message.error(e.message || 'Failed');
            if (e.errorData) setErrorModal(e);
        }
    };

    const sk = Form.useWatch('source_kind', datasetForm);

    useEffect(() => {
        if (!datasetModalOpen || !editingDataset?.id) return;
        if (editingDataset.source_kind !== 'flattened_api_get') return;
        if (editingDataset.flattening_policy_id) return;
        const mid = editingDataset.model_id;
        if (mid == null || !postgresFlattenPolicies.length) return;
        const p = postgresFlattenPolicies.find((x) => x.model_id === mid);
        if (p) {
            datasetForm.setFieldsValue({ flattening_policy_id: p.flattening_policy_id });
        }
    }, [
        datasetModalOpen,
        editingDataset?.id,
        editingDataset?.source_kind,
        editingDataset?.model_id,
        editingDataset?.flattening_policy_id,
        postgresFlattenPolicies,
        datasetForm,
    ]);

    const instanceColumns = [
        { title: 'Name', dataIndex: 'name', key: 'name' },
        { title: 'UUID', key: 'uuid', render: (_, r) => <Text copyable={{ text: r.instance_uuid }}>{String(r.instance_uuid).slice(0, 8)}…</Text> },
        { title: 'Company', dataIndex: 'company_id', key: 'company_id', render: (v) => v ?? '—' },
        { title: 'Offline', key: 'off', render: (_, r) => (r.enable_offline_data ? 'On' : 'Off') },
        { title: 'Active', dataIndex: 'is_active', key: 'is_active', render: (v) => (v === false ? 'No' : 'Yes') },
        {
            title: '',
            key: 'act',
            render: (_, r) => (
                <Button type="link" onClick={() => openDrawer(r)}>
                    Configure
                </Button>
            ),
        },
    ];

    return (
        <div style={{ padding: 16 }}>
            <ErrorModal visible={!!errorModal} error={errorModal} onClose={() => setErrorModal(null)} />

            <Card
                title={
                    <Space>
                        <span>Client instances</span>
                        <BookOutlined />
                    </Space>
                }
                extra={
                    <Space>
                        <Button icon={<ReloadOutlined />} onClick={loadInstances}>
                            Refresh
                        </Button>
                        <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateOpen(true)}>
                            New instance
                        </Button>
                    </Space>
                }
            >
                <Alert
                    type="warning"
                    showIcon
                    style={{ marginBottom: 16 }}
                    message="Sensitive configuration"
                    description="Misconfigured datasets or write allowlists can expose data or allow unintended offline replay. Use company scoping, least-privilege PATs, and review docs/client_offline_sync.md before production."
                />
                <Table rowKey="instance_id" loading={loading} dataSource={instances} columns={instanceColumns} pagination={false} />
            </Card>

            <Modal title="New instance" open={createOpen} onCancel={() => setCreateOpen(false)} onOk={onCreate} okText="Create">
                <Form form={createForm} layout="vertical">
                    <Form.Item name="name" label="Name" rules={[{ required: true, message: 'Required' }]}>
                        <Input placeholder="e.g. contacts_app" />
                    </Form.Item>
                    <Form.Item name="description" label="Description">
                        <Input.TextArea rows={2} />
                    </Form.Item>
                    <Form.Item name="company_id" label="Company ID (optional)">
                        <InputNumber style={{ width: '100%' }} placeholder="Restrict manifest access to this company" />
                    </Form.Item>
                </Form>
            </Modal>

            <Drawer
                title={activeInstance ? `Instance: ${activeInstance.name}` : 'Instance'}
                width={720}
                open={drawerOpen}
                onClose={() => setDrawerOpen(false)}
                extra={
                    <Space wrap>
                        <Button icon={<EyeOutlined />} onClick={previewManifest}>
                            Preview manifest
                        </Button>
                        <Button
                            icon={<DownloadOutlined />}
                            loading={handoutDownloading}
                            onClick={downloadDeveloperHandout}
                        >
                            Developer handout (.txt)
                        </Button>
                    </Space>
                }
            >
                {activeInstance && (
                    <Tabs
                        items={[
                            {
                                key: 'guide',
                                label: 'Guide',
                                children: (
                                    <>
                                        <Alert
                                            type="info"
                                            showIcon
                                            style={{ marginBottom: 16 }}
                                            message="Share with client / app developers"
                                            description="After you configure read datasets and offline settings, download a single .txt handout for the team building the mobile, desktop, or WebView shell. It includes instance UUID, full API paths, authentication notes, and a snapshot of the current offline manifest. Do not post publicly or send to end users."
                                            action={
                                                <Button
                                                    type="primary"
                                                    size="small"
                                                    icon={<DownloadOutlined />}
                                                    loading={handoutDownloading}
                                                    onClick={downloadDeveloperHandout}
                                                >
                                                    Download .txt
                                                </Button>
                                            }
                                        />
                                        <Space wrap style={{ marginBottom: 12 }}>
                                            <Text>Instance ID: {activeInstance.instance_id}</Text>
                                            <Button size="small" icon={<CopyOutlined />} onClick={() => copyText(String(activeInstance.instance_id))}>
                                                Copy ID
                                            </Button>
                                            <Button size="small" icon={<CopyOutlined />} onClick={() => copyText(activeInstance.instance_uuid)}>
                                                Copy UUID
                                            </Button>
                                        </Space>
                                        <Alert type="info" message="Operator notes" description={OPERATOR_GUIDE} />
                                    </>
                                ),
                            },
                            {
                                key: 'settings',
                                label: 'Offline settings',
                                children: (
                                    <>
                                        <Form form={settingsForm} layout="vertical">
                                            <Form.Item name="enable_offline_data" label="Enable offline data" valuePropName="checked">
                                                <Switch />
                                            </Form.Item>
                                            <Form.Item
                                                name="schema_pack_version"
                                                label="Schema pack version"
                                                rules={[{ required: true, message: 'Required' }]}
                                                extra="Bump when SQLite shape must be rebuilt on clients."
                                            >
                                                <Input />
                                            </Form.Item>
                                            <Form.Item name="operator_notes" label="Operator notes (internal)">
                                                <Input.TextArea rows={3} />
                                            </Form.Item>
                                            <Button type="primary" onClick={saveSettings}>
                                                Save settings
                                            </Button>
                                        </Form>
                                    </>
                                ),
                            },
                            {
                                key: 'datasets',
                                label: 'Read datasets',
                                children: (
                                    <>
                                        <Button type="primary" icon={<PlusOutlined />} onClick={() => openDatasetModal(null)} style={{ marginBottom: 12 }}>
                                            Add dataset
                                        </Button>
                                        <Table
                                            size="small"
                                            rowKey="id"
                                            dataSource={datasets}
                                            columns={[
                                                { title: 'Key', dataIndex: 'dataset_key' },
                                                { title: 'Kind', dataIndex: 'source_kind' },
                                                { title: 'Active', dataIndex: 'is_active', render: (v) => (v === false ? 'No' : 'Yes') },
                                                {
                                                    title: '',
                                                    render: (_, r) => (
                                                        <Button type="link" icon={<EditOutlined />} onClick={() => openDatasetModal(r)}>
                                                            Edit
                                                        </Button>
                                                    ),
                                                },
                                                {
                                                    title: '',
                                                    render: (_, r) => (
                                                        <Popconfirm title="Delete?" onConfirm={async () => {
                                                            await api.deleteClientInstanceDataset(activeInstance.instance_id, r.id);
                                                            message.success('Deleted');
                                                            const ds = await api.listClientInstanceDatasets(activeInstance.instance_id);
                                                            setDatasets(Array.isArray(ds) ? ds : []);
                                                        }}>
                                                            <Button type="link" danger>
                                                                Delete
                                                            </Button>
                                                        </Popconfirm>
                                                    ),
                                                },
                                            ]}
                                        />
                                    </>
                                ),
                            },
                            {
                                key: 'writes',
                                label: 'Offline write allowlist',
                                children: (
                                    <>
                                        <Alert
                                            type="warning"
                                            showIcon
                                            style={{ marginBottom: 12 }}
                                            message="HOT Auto CRUD only"
                                            description="Add one row per POST/PUT/PATCH/DELETE route. Flattened and S3 snapshots are never writable from clients."
                                        />
                                        <Button type="primary" icon={<PlusOutlined />} onClick={openWriteModal} style={{ marginBottom: 12 }}>
                                            Add endpoint
                                        </Button>
                                        <Table
                                            size="small"
                                            rowKey="id"
                                            dataSource={writeEps}
                                            columns={[
                                                { title: 'Method', dataIndex: 'method' },
                                                { title: 'Path', dataIndex: 'path' },
                                                { title: 'Model', dataIndex: 'model_name' },
                                                {
                                                    title: '',
                                                    render: (_, r) => (
                                                        <Popconfirm title="Remove?" onConfirm={async () => {
                                                            await api.deleteClientInstanceWriteEndpoint(activeInstance.instance_id, r.id);
                                                            message.success('Removed');
                                                            const we = await api.listClientInstanceWriteEndpoints(activeInstance.instance_id);
                                                            setWriteEps(Array.isArray(we) ? we : []);
                                                        }}>
                                                            <Button type="link" danger>
                                                                Remove
                                                            </Button>
                                                        </Popconfirm>
                                                    ),
                                                },
                                            ]}
                                        />
                                    </>
                                ),
                            },
                        ]}
                    />
                )}
            </Drawer>

            <Modal
                title={editingDataset ? 'Edit dataset' : 'Add dataset'}
                open={datasetModalOpen}
                onCancel={() => setDatasetModalOpen(false)}
                onOk={saveDataset}
                width={920}
                styles={{ body: { maxHeight: 'calc(100vh - 200px)', overflowY: 'auto' } }}
            >
                <Form form={datasetForm} layout="vertical">
                    <Row gutter={[16, 8]}>
                        <Col xs={24} md={12}>
                            <Form.Item name="source_kind" label="Source kind" rules={[{ required: true }]}>
                                <Select
                                    options={SOURCE_KINDS}
                                    onChange={(val) => onDatasetSourceKindChange(datasetForm, val)}
                                />
                            </Form.Item>
                        </Col>
                        <Col xs={24} md={12}>
                            <Form.Item name="batch_size" label="Batch size (optional)">
                                <InputNumber style={{ width: '100%' }} min={1} placeholder="Page size hints for clients" />
                            </Form.Item>
                        </Col>
                        {sk === 'hot_auto_crud_get' && (
                            <Col span={24}>
                                <Form.Item
                                    name="model_id"
                                    label="Model (live HOT table)"
                                    rules={[{ required: true, message: 'Select a model' }]}
                                    extra={`Dataset key in the manifest is this model’s table name (lowercase). Incremental sync uses ${DEFAULT_INCREMENTAL_FIELD}.`}
                                >
                                    <Select
                                        showSearch
                                        allowClear
                                        loading={loadingDataModels}
                                        placeholder="Search by name or table…"
                                        optionFilterProp="searchText"
                                        optionLabelProp="selectedLabel"
                                        options={dataModelOptions.map((m) => {
                                            const title = m.display_name || m.model_name;
                                            return {
                                                value: m.model_id,
                                                searchText: `${m.display_name || ''} ${m.model_name} ${m.table_name}`,
                                                selectedLabel: `${title} (${m.table_name}, id ${m.model_id})`,
                                                model_name: m.model_name,
                                                display_name: m.display_name,
                                                label: (
                                                    <div>
                                                        <div>{title}</div>
                                                        <Text type="secondary" style={{ fontSize: 12 }}>
                                                            {m.table_name} · id {m.model_id}
                                                        </Text>
                                                    </div>
                                                ),
                                            };
                                        })}
                                        notFoundContent={loadingDataModels ? <Spin size="small" /> : 'No models found'}
                                    />
                                </Form.Item>
                            </Col>
                        )}
                        {sk === 'flattened_api_get' && (
                            <Col span={24}>
                                <Form.Item
                                    name="flattening_policy_id"
                                    label="Flattening table (Postgres)"
                                    rules={[{ required: true, message: 'Select a flattened table' }]}
                                    extra={`Dataset key in the manifest is this table name. The manifest includes every flattening read GET route for that model. Uses ${DEFAULT_INCREMENTAL_FIELD} for incremental hints.`}
                                >
                                    <Select
                                        showSearch
                                        allowClear
                                        loading={loadingPostgresPolicies}
                                        placeholder="Search by table name…"
                                        optionFilterProp="searchText"
                                        optionLabelProp="selectedLabel"
                                        options={postgresFlattenPolicies.map((p) => ({
                                            value: p.flattening_policy_id,
                                            searchText: `${p.table_name} ${p.model_name} ${p.display_name || ''}`,
                                            selectedLabel: p.table_name,
                                            table_name: p.table_name,
                                            model_name: p.model_name,
                                            display_name: p.display_name,
                                            label: (
                                                <div>
                                                    <div>{p.table_name}</div>
                                                    <Text type="secondary" style={{ fontSize: 12 }}>
                                                        {(p.display_name || p.model_name) + ` · model ${p.model_id}`}
                                                    </Text>
                                                </div>
                                            ),
                                        }))}
                                        notFoundContent={
                                            loadingPostgresPolicies ? (
                                                <Spin size="small" />
                                            ) : (
                                                'No Postgres flattening policies with read routes'
                                            )
                                        }
                                    />
                                </Form.Item>
                            </Col>
                        )}
                        <Col xs={24} md={12}>
                            <Form.Item name="is_active" label="Active" valuePropName="checked">
                                <Switch />
                            </Form.Item>
                        </Col>
                    </Row>
                    {sk === 'flattened_s3' && (
                        <Row gutter={[16, 8]}>
                            <Col span={24}>
                                <Form.Item
                                    name="flattening_policy_id"
                                    label="Flattening policy (S3)"
                                    rules={[{ required: true }]}
                                    extra={`Incremental metadata uses ${DEFAULT_INCREMENTAL_FIELD} (Noolva default).`}
                                >
                                    <Select
                                        showSearch
                                        optionFilterProp="label"
                                        options={s3Policies.map((p) => ({
                                            value: p.id,
                                            label: `${p.id} — ${p.table_name} (public=${String(p.is_public_on_s3)})`,
                                        }))}
                                        placeholder="Select S3 flattening policy"
                                    />
                                </Form.Item>
                            </Col>
                        </Row>
                    )}
                    <Row gutter={[16, 8]}>
                        <Col span={24}>
                            <Form.Item name="local_lifecycle_jsonb" label="Local lifecycle JSON (client hints)">
                                <Input.TextArea rows={3} placeholder="{}" style={{ fontFamily: 'monospace', fontSize: 12 }} />
                            </Form.Item>
                        </Col>
                    </Row>
                </Form>
            </Modal>

            <Modal title="Allowlist write endpoint" open={writeModalOpen} onCancel={() => setWriteModalOpen(false)} onOk={saveWriteEndpoint}>
                <Form form={writeForm} layout="vertical">
                    <Form.Item name="endpoint_id" label="Endpoint" rules={[{ required: true }]}>
                        <Select
                            showSearch
                            filterOption={false}
                            onSearch={loadWriteCandidates}
                            onDropdownVisibleChange={(o) => o && loadWriteCandidates('')}
                            options={writeCandidates}
                            placeholder="Search POST/PUT/PATCH/DELETE Auto CRUD"
                        />
                    </Form.Item>
                    <Form.Item name="notes" label="Notes">
                        <Input />
                    </Form.Item>
                </Form>
            </Modal>

            <Modal title="Manifest preview (JSON)" open={!!manifestPreview} footer={null} onCancel={() => setManifestPreview(null)} width={800}>
                <pre style={{ maxHeight: 480, overflow: 'auto', fontSize: 11 }}>{manifestPreview}</pre>
            </Modal>
        </div>
    );
};

export default ClientInstances;
