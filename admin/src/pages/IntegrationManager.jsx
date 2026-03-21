import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
    Card,
    Table,
    Button,
    Space,
    Typography,
    Modal,
    Form,
    Input,
    Select,
    Switch,
    Tag,
    Alert,
    App,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, ApiOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import { useAuth } from '../contexts/AuthContext';
import ErrorModal from '../components/ErrorModal';

const { Title, Text } = Typography;
const { TextArea } = Input;
const { Option } = Select;

function parseFieldList(raw) {
    if (!raw) return [];
    if (Array.isArray(raw)) return raw;
    if (typeof raw === 'string') {
        try {
            const v = JSON.parse(raw);
            return Array.isArray(v) ? v : [];
        } catch {
            return [];
        }
    }
    return [];
}

function buildCredentialFields(provider) {
    if (!provider) return [];
    const req = parseFieldList(provider.required_fields_json);
    const opt = parseFieldList(provider.optional_fields_json);
    return [...req, ...opt];
}

/** Non-secret credential fields: prefill from integration config (secrets never sent by API). */
function initialCredentialsForEdit(provider, config) {
    const cfg = config && typeof config === 'object' ? config : {};
    const out = {};
    for (const f of buildCredentialFields(provider)) {
        if (f.is_secret) {
            out[f.field_name] = undefined;
            continue;
        }
        let v = cfg[f.field_name];
        if (v === undefined && f.field_name === 'aws_region') {
            v = cfg.region;
        }
        if (v !== undefined && v !== null && String(v).trim() !== '') {
            out[f.field_name] = String(v);
        } else {
            out[f.field_name] = undefined;
        }
    }
    return out;
}

const IntegrationManager = () => {
    const { message: messageApi } = App.useApp();
    const { user, currentAccount } = useAuth();
    const [providers, setProviders] = useState([]);
    const [integrations, setIntegrations] = useState([]);
    const [loading, setLoading] = useState(false);
    const [providersLoading, setProvidersLoading] = useState(false);
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [submitLoading, setSubmitLoading] = useState(false);
    const [errorModalVisible, setErrorModalVisible] = useState(false);
    const [errorDetails, setErrorDetails] = useState(null);
    /** Set from list API when company was inferred server-side (JWT or first company). */
    const [listCompanyId, setListCompanyId] = useState(null);
    const [form] = Form.useForm();
    const selectedProviderId = Form.useWatch('provider_id', form);
    const editCredentialsSyncedRef = useRef(null);

    const companyId = useMemo(() => {
        // Stored account `id` is Date.now() (local key); DB company is `companyId`
        const fromAccount =
            currentAccount?.companyId ?? currentAccount?.company_id ?? null;
        const fromUser = user?.company_id;
        if (fromAccount != null && fromAccount !== '') return Number(fromAccount);
        if (fromUser != null && fromUser !== '') return Number(fromUser);
        return null;
    }, [currentAccount, user]);

    const effectiveCompanyId = useMemo(() => {
        if (companyId != null) return Number(companyId);
        if (listCompanyId != null) return Number(listCompanyId);
        return null;
    }, [companyId, listCompanyId]);

    const providerById = useMemo(() => {
        const m = new Map();
        providers.forEach((p) => m.set(p.provider_id, p));
        return m;
    }, [providers]);

    const providerForFormFields = useMemo(() => {
        if (editing?.provider_id != null) {
            return providerById.get(editing.provider_id) ?? null;
        }
        if (selectedProviderId != null) {
            return providerById.get(selectedProviderId) ?? null;
        }
        return null;
    }, [editing, editing?.provider_id, selectedProviderId, providerById]);

    const credentialFields = useMemo(
        () => buildCredentialFields(providerForFormFields),
        [providerForFormFields]
    );

    const loadProviders = useCallback(async () => {
        setProvidersLoading(true);
        try {
            const data = await api.listIntegrationProviders();
            setProviders(data.providers || []);
        } catch (err) {
            setErrorDetails(err);
            setErrorModalVisible(true);
        } finally {
            setProvidersLoading(false);
        }
    }, []);

    const loadIntegrations = useCallback(async () => {
        setLoading(true);
        try {
            const data = await api.listIntegrations(companyId != null ? companyId : null);
            setIntegrations(data.integrations || []);
            if (data.company_id != null) {
                setListCompanyId(Number(data.company_id));
            } else {
                setListCompanyId(null);
            }
        } catch (err) {
            setListCompanyId(null);
            setErrorDetails(err);
            setErrorModalVisible(true);
        } finally {
            setLoading(false);
        }
    }, [companyId]);

    useEffect(() => {
        loadProviders();
    }, [loadProviders]);

    useEffect(() => {
        loadIntegrations();
    }, [loadIntegrations]);

    // When providers load after opening edit, fill non-secret defaults from config.
    useEffect(() => {
        if (!modalOpen || !editing) {
            editCredentialsSyncedRef.current = null;
            return;
        }
        const prov = providerById.get(editing.provider_id);
        if (!prov) return;
        const syncKey = String(editing.integration_id);
        if (editCredentialsSyncedRef.current === syncKey) return;
        const credInit = initialCredentialsForEdit(prov, editing.config);
        form.setFieldsValue({ credentials: credInit });
        editCredentialsSyncedRef.current = syncKey;
    }, [modalOpen, editing, providerById, form]);

    const openCreate = () => {
        editCredentialsSyncedRef.current = null;
        setEditing(null);
        form.resetFields();
        form.setFieldsValue({
            is_active: true,
            is_default: false,
            integration_type: 'api',
            credentials: {},
        });
        setModalOpen(true);
    };

    const openEdit = (record) => {
        editCredentialsSyncedRef.current = null;
        setEditing(record);
        const prov = providerById.get(record.provider_id);
        const credInit = prov ? initialCredentialsForEdit(prov, record.config) : {};
        form.resetFields();
        form.setFieldsValue({
            integration_name: record.integration_name,
            is_active: record.is_active,
            is_default: record.is_default,
            integration_type: record.integration_type || 'api',
            credentials: credInit,
            config_json: record.config ? JSON.stringify(record.config, null, 2) : '',
        });
        setModalOpen(true);
    };

    const closeModal = () => {
        setModalOpen(false);
        setEditing(null);
        form.resetFields();
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();

            let config = null;
            if (values.config_json && String(values.config_json).trim()) {
                try {
                    config = JSON.parse(values.config_json);
                } catch {
                    messageApi.error('Config must be valid JSON');
                    return;
                }
            }

            const rawCreds = values.credentials || {};
            const credentials = {};
            Object.entries(rawCreds).forEach(([k, v]) => {
                if (v !== undefined && v !== null && String(v).trim() !== '') {
                    credentials[k] = typeof v === 'string' ? v.trim() : v;
                }
            });

            const companyPayload =
                effectiveCompanyId != null ? { company_id: effectiveCompanyId } : {};

            setSubmitLoading(true);
            if (editing) {
                const payload = {
                    ...companyPayload,
                    integration_name: values.integration_name,
                    is_active: values.is_active,
                    is_default: values.is_default,
                    integration_type: values.integration_type,
                    config: config !== null ? config : undefined,
                };
                if (Object.keys(credentials).length > 0) {
                    payload.credentials = credentials;
                }
                await api.updateIntegration(editing.integration_id, payload);
                messageApi.success('Integration updated');
            } else {
                await api.createIntegration({
                    ...companyPayload,
                    provider_id: values.provider_id,
                    integration_name: values.integration_name,
                    credentials,
                    config: config !== null ? config : undefined,
                    integration_type: values.integration_type || 'api',
                    is_active: values.is_active !== false,
                    is_default: !!values.is_default,
                });
                messageApi.success('Integration created');
            }
            closeModal();
            loadIntegrations();
        } catch (err) {
            if (err?.errorFields) return;
            setErrorDetails(err);
            setErrorModalVisible(true);
        } finally {
            setSubmitLoading(false);
        }
    };

    const handleDelete = (record) => {
        Modal.confirm({
            title: 'Delete integration',
            content: `Remove "${record.integration_name || record.provider_display_name}"? Uploads and jobs that rely on it may fail.`,
            okText: 'Delete',
            okType: 'danger',
            onOk: async () => {
                try {
                    await api.deleteIntegration(
                        record.integration_id,
                        effectiveCompanyId != null ? effectiveCompanyId : null
                    );
                    messageApi.success('Deleted');
                    loadIntegrations();
                } catch (err) {
                    setErrorDetails(err);
                    setErrorModalVisible(true);
                }
            },
        });
    };

    const columns = [
        {
            title: 'Name',
            dataIndex: 'integration_name',
            key: 'integration_name',
            ellipsis: true,
            render: (v, row) => v || row.provider_display_name || row.provider_name,
        },
        {
            title: 'Provider',
            key: 'provider',
            width: 160,
            render: (_, row) => (
                <span>
                    {row.provider_display_name || row.provider_name}
                    {row.provider_category ? (
                        <Tag style={{ marginLeft: 8 }}>{row.provider_category}</Tag>
                    ) : null}
                </span>
            ),
        },
        {
            title: 'Default',
            dataIndex: 'is_default',
            key: 'is_default',
            width: 88,
            render: (v) => (v ? <Tag color="blue">Default</Tag> : '—'),
        },
        {
            title: 'Active',
            dataIndex: 'is_active',
            key: 'is_active',
            width: 80,
            render: (v) => (v ? <Tag color="green">Yes</Tag> : <Tag>No</Tag>),
        },
        {
            title: 'Secrets',
            dataIndex: 'has_credentials',
            key: 'has_credentials',
            width: 90,
            render: (v) => (v ? <Tag color="success">Stored</Tag> : <Tag>Missing</Tag>),
        },
        {
            title: 'Updated',
            dataIndex: 'last_updated',
            key: 'last_updated',
            width: 180,
            render: (v) => (v ? new Date(v).toLocaleString() : '—'),
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 120,
            fixed: 'right',
            render: (_, record) => (
                <Space size="small">
                    <Button type="link" size="small" icon={<EditOutlined />} onClick={() => openEdit(record)}>
                        Edit
                    </Button>
                    <Button
                        type="link"
                        size="small"
                        danger
                        icon={<DeleteOutlined />}
                        onClick={() => handleDelete(record)}
                    >
                        Delete
                    </Button>
                </Space>
            ),
        },
    ];

    return (
        <div style={{ padding: '0 4px' }}>
            <Space align="center" style={{ marginBottom: 16 }}>
                <ApiOutlined style={{ fontSize: 22, color: 'var(--primary-color, #1677ff)' }} />
                <Title level={4} style={{ margin: 0 }}>
                    Integration Manager
                </Title>
            </Space>
            <Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
                Configure external providers (email, storage, SMS, payments) for the active company. Credential
                fields are encrypted on the server and never shown again after save.
            </Text>

            {companyId == null ? (
                <Alert
                    type="info"
                    showIcon
                    message="Company context"
                    description={
                        listCompanyId != null
                            ? `No company is selected in the account switcher. Data is for company_id ${listCompanyId} (server default: your JWT company, or the first company in the database).`
                            : 'If your session has no company, the server uses the first company in the database. Select an account in the header to target a specific company.'
                    }
                    style={{ marginBottom: 16 }}
                />
            ) : null}

            <Card size="small">
                <Space style={{ marginBottom: 12 }}>
                    <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
                        Add integration
                    </Button>
                    <Button onClick={() => loadIntegrations()} loading={loading}>
                        Refresh
                    </Button>
                </Space>
                <Table
                    rowKey="integration_id"
                    loading={loading}
                    columns={columns}
                    dataSource={integrations}
                    pagination={{ pageSize: 10, showSizeChanger: true }}
                    scroll={{ x: 900 }}
                />
            </Card>

            <Modal
                title={editing ? 'Edit integration' : 'New integration'}
                open={modalOpen}
                onCancel={closeModal}
                onOk={handleSubmit}
                confirmLoading={submitLoading}
                width={640}
                destroyOnClose
            >
                <Form form={form} layout="vertical" style={{ marginTop: 12 }}>
                    {!editing ? (
                        <Form.Item
                            name="provider_id"
                            label="Provider"
                            rules={[{ required: true, message: 'Select a provider' }]}
                        >
                            <Select
                                placeholder="Select provider"
                                loading={providersLoading}
                                showSearch
                                optionFilterProp="children"
                            >
                                {providers.map((p) => (
                                    <Option key={p.provider_id} value={p.provider_id}>
                                        {p.provider_display_name} ({p.provider_name})
                                    </Option>
                                ))}
                            </Select>
                        </Form.Item>
                    ) : (
                        <Form.Item label="Provider">
                            <Input
                                disabled
                                value={
                                    editing.provider_display_name
                                        ? `${editing.provider_display_name} (${editing.provider_name})`
                                        : editing.provider_name
                                }
                            />
                        </Form.Item>
                    )}

                    <Form.Item name="integration_name" label="Display name" rules={[{ required: true }]}>
                        <Input placeholder="e.g. Default S3 Bucket" />
                    </Form.Item>

                    {editing && credentialFields.length > 0 ? (
                        <Alert
                            type="warning"
                            showIcon
                            style={{ marginBottom: 16 }}
                            message="Stored secrets are not shown"
                            description={
                                'Passwords, API keys, and other secret fields stay encrypted and are never loaded into this form. Leave a secret field empty to keep the current value, or enter a new value to replace it. Non-secret fields may be prefilled from saved configuration (JSON below) where names match.'
                            }
                        />
                    ) : null}

                    {credentialFields.length > 0 ? (
                        <>
                            {!editing ? (
                                <Text type="secondary" style={{ display: 'block', marginBottom: 8 }}>
                                    Required fields must be filled for this provider.
                                </Text>
                            ) : null}
                            {credentialFields.map((f) => (
                                <Form.Item
                                    key={f.field_name}
                                    label={f.display_name || f.field_name}
                                    name={['credentials', f.field_name]}
                                    tooltip={f.description}
                                >
                                    {f.is_secret ? (
                                        <Input.Password
                                            autoComplete="new-password"
                                            placeholder={
                                                editing
                                                    ? 'Leave empty to keep existing — enter new value to replace'
                                                    : f.description || 'Required'
                                            }
                                        />
                                    ) : (
                                        <Input
                                            placeholder={
                                                editing
                                                    ? f.description || 'Edit if needed'
                                                    : f.description || f.field_name
                                            }
                                        />
                                    )}
                                </Form.Item>
                            ))}
                        </>
                    ) : providerForFormFields && !editing ? (
                        <Alert
                            type="info"
                            message="This provider has no field schema; submit may fail if credentials are required."
                        />
                    ) : editing && !providerForFormFields ? (
                        <Alert
                            type="warning"
                            showIcon
                            message="Provider definitions still loading or missing"
                            description="Refresh the page if credential fields do not appear."
                            style={{ marginBottom: 12 }}
                        />
                    ) : null}

                    <Form.Item
                        name="config_json"
                        label="Non-secret config (JSON, optional)"
                        tooltip="Example for S3: bucket name, region, CDN URL — see existing rows in your database backup."
                    >
                        <TextArea rows={4} placeholder='{"bucket_name":"...","region":"us-east-1","url":"https://..."}' />
                    </Form.Item>

                    <Form.Item name="integration_type" label="Integration type" initialValue="api">
                        <Select
                            options={[
                                { value: 'api', label: 'api' },
                                { value: 'oauth', label: 'oauth' },
                                { value: 'webhook', label: 'webhook' },
                            ]}
                        />
                    </Form.Item>

                    <Space size="large">
                        <Form.Item name="is_active" label="Active" valuePropName="checked">
                            <Switch />
                        </Form.Item>
                        <Form.Item name="is_default" label="Default for provider" valuePropName="checked">
                            <Switch />
                        </Form.Item>
                    </Space>
                </Form>
            </Modal>

            <ErrorModal
                visible={errorModalVisible}
                onClose={() => setErrorModalVisible(false)}
                error={errorDetails}
            />
        </div>
    );
};

export default IntegrationManager;
