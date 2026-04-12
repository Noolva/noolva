import React, { useMemo, useState, useEffect } from 'react';
import {
    Card,
    Table,
    Tag,
    Button,
    Space,
    message,
    Drawer,
    Form,
    Input,
    InputNumber,
    Select,
    Switch,
    Popconfirm,
} from 'antd';
import { ReloadOutlined, FileTextOutlined, PlusOutlined, EditOutlined, StopOutlined, CheckCircleOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';
import { VCJsonEditor } from '../components/ViewComponents/inputs/VCJsonEditor';
import { VCSearchFilterBar } from '../components/ViewComponents/displays/VCSearchFilterBar';

const { Option } = Select;

const HANDLER_TYPES = ['core_function', 'custom_script', 'dedicated_worker'];
const CONCURRENCY_MODES = ['parallel', 'sequential', 'singleton'];
const TEMPLATE_CATEGORIES = [
    { value: 'task', label: 'Task' },
    { value: 'workflow', label: 'Workflow' },
    { value: 'system', label: 'System' },
];

const JobTemplates = () => {
    const [templates, setTemplates] = useState([]);
    const [loading, setLoading] = useState(false);
    const [drawerVisible, setDrawerVisible] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [form] = Form.useForm();
    const [errorModal, setErrorModal] = useState(null);
    const [jsonDrawerVisible, setJsonDrawerVisible] = useState(false);
    const [jsonForm] = Form.useForm();
    const [jsonMeta, setJsonMeta] = useState(null); // { templateId, fieldKey, label, defaultValue }
    const [searchText, setSearchText] = useState('');
    const [filters, setFilters] = useState({
        category: null,
        handlerType: null,
        status: null, // 'active' | 'inactive' | null
        mode: null,
        timeoutMin: null,
        timeoutMax: null,
    });

    const fetchTemplates = async () => {
        try {
            setLoading(true);
            const data = await api.getJobTemplates();
            setTemplates(Array.isArray(data) ? data : []);
        } catch (error) {
            message.error('Failed to load job templates: ' + (error.message || 'Unknown error'));
            if (error.errorData) setErrorModal(error);
            setTemplates([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTemplates();
    }, []);

    const filteredTemplates = useMemo(() => {
        const q = (searchText || '').trim().toLowerCase();
        const hasQuery = !!q;

        const matchesQuery = (t) => {
            if (!hasQuery) return true;
            const hay = [
                t?.name,
                t?.description,
                t?.template_category,
                t?.handler_type,
                t?.handler_function_name,
            ]
                .filter(Boolean)
                .join(' ')
                .toLowerCase();
            return hay.includes(q);
        };

        const matchesFilters = (t) => {
            if (filters.category && t?.template_category !== filters.category) return false;
            if (filters.handlerType && t?.handler_type !== filters.handlerType) return false;
            if (filters.mode && t?.queue_concurrency_mode !== filters.mode) return false;
            if (filters.status === 'active' && t?.is_active === false) return false;
            if (filters.status === 'inactive' && t?.is_active !== false) return false;

            const timeout = typeof t?.default_timeout_seconds === 'number' ? t.default_timeout_seconds : null;
            if (typeof filters.timeoutMin === 'number' && timeout !== null && timeout < filters.timeoutMin) return false;
            if (typeof filters.timeoutMax === 'number' && timeout !== null && timeout > filters.timeoutMax) return false;
            return true;
        };

        return (Array.isArray(templates) ? templates : []).filter((t) => matchesQuery(t) && matchesFilters(t));
    }, [templates, searchText, filters]);

    const resetFilters = () => {
        setSearchText('');
        setFilters({
            category: null,
            handlerType: null,
            status: null,
            mode: null,
            timeoutMin: null,
            timeoutMax: null,
        });
    };

    const openAdd = () => {
        setEditingId(null);
        form.setFieldsValue({
            name: '',
            description: '',
            template_category: 'task',
            handler_type: 'core_function',
            handler_function_name: '',
            default_timeout_seconds: 3600,
            queue_concurrency_mode: 'parallel',
            queue_concurrency_limit: 0,
            is_idempotent: false,
        });
        setDrawerVisible(true);
    };

    const openEdit = async (record) => {
        setEditingId(record.template_id);
        try {
            const data = await api.getJobTemplate(record.template_id);
            form.setFieldsValue({
                name: data.name,
                description: data.description || '',
                template_category: data.template_category || 'task',
                handler_type: data.handler_type || 'core_function',
                handler_function_name: data.handler_function_name || '',
                default_timeout_seconds: data.default_timeout_seconds ?? 3600,
                queue_concurrency_mode: data.queue_concurrency_mode || 'parallel',
                queue_concurrency_limit: data.queue_concurrency_limit ?? 0,
                is_idempotent: data.is_idempotent ?? false,
                is_active: data.is_active !== false,
                version: data.version,
                runnable_in: (data.runnable_in || []).join(', '),
                capabilities: (data.capabilities || []).join(', '),
            });
        } catch (error) {
            message.error(error.message || 'Failed to load template');
            return;
        }
        setDrawerVisible(true);
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            const body = {
                name: values.name.trim(),
                description: values.description?.trim() || null,
                template_category: values.template_category || 'task',
                handler_type: values.handler_type,
                handler_function_name: values.handler_function_name?.trim() || values.name.trim(),
                default_timeout_seconds: values.default_timeout_seconds,
                queue_concurrency_mode: values.queue_concurrency_mode,
                queue_concurrency_limit: values.queue_concurrency_limit,
                is_idempotent: values.is_idempotent,
            };
            if (editingId) {
                if (values.is_active !== undefined) body.is_active = values.is_active;
                await api.updateJobTemplate(editingId, body);
                message.success('Template updated');
            } else {
                await api.createJobTemplate(body);
                message.success('Template created');
            }
            setDrawerVisible(false);
            fetchTemplates();
        } catch (error) {
            if (error.errorFields) return;
            message.error(error.message || 'Failed to save');
            if (error.errorData) setErrorModal(error);
        }
    };

    const handleDeactivate = async (record) => {
        try {
            await api.updateJobTemplate(record.template_id, { is_active: false });
            message.success('Template deactivated');
            fetchTemplates();
        } catch (error) {
            message.error(error.message || 'Failed to deactivate');
            if (error.errorData) setErrorModal(error);
        }
    };

    const handleActivate = async (record) => {
        try {
            await api.updateJobTemplate(record.template_id, { is_active: true });
            message.success('Template activated');
            fetchTemplates();
        } catch (error) {
            message.error(error.message || 'Failed to activate');
            if (error.errorData) setErrorModal(error);
        }
    };

    const openJsonEditor = async (record, fieldKey, label) => {
        try {
            const data = await api.getJobTemplate(record.template_id);
            setJsonMeta({
                templateId: record.template_id,
                fieldKey,
                label,
                defaultValue: data[fieldKey] || '',
            });
            jsonForm.resetFields();
            setJsonDrawerVisible(true);
        } catch (error) {
            message.error(error.message || 'Failed to load template JSON');
        }
    };

    const handleJsonSave = async () => {
        try {
            const values = await jsonForm.validateFields();
            const raw = values.json_value;
            let parsed = null;
            if (raw && typeof raw === 'string' && raw.trim()) {
                parsed = JSON.parse(raw);
            }
            await api.updateJobTemplate(jsonMeta.templateId, { [jsonMeta.fieldKey]: parsed });
            message.success('JSON updated');
            setJsonDrawerVisible(false);
            setJsonMeta(null);
            jsonForm.resetFields();
            fetchTemplates();
        } catch (error) {
            if (error?.errorFields) return;
            message.error(error.message || 'Failed to save JSON');
        }
    };

    const columns = [
        { title: 'Name', dataIndex: 'name', key: 'name' },
        { title: 'Description', dataIndex: 'description', key: 'description', ellipsis: true },
        { title: 'Category', dataIndex: 'template_category', key: 'template_category', width: 100, render: (c) => c && <Tag>{c}</Tag> },
        { title: 'Handler type', dataIndex: 'handler_type', key: 'handler_type', width: 130, render: (t) => t && <Tag>{t}</Tag> },
        { title: 'Handler function', dataIndex: 'handler_function_name', key: 'handler_function_name', ellipsis: true },
        { title: 'Timeout (s)', dataIndex: 'default_timeout_seconds', key: 'default_timeout_seconds', width: 95 },
        { title: 'Mode', dataIndex: 'queue_concurrency_mode', key: 'queue_concurrency_mode', width: 100 },
        { title: 'Limit', dataIndex: 'queue_concurrency_limit', key: 'queue_concurrency_limit', width: 70 },
        {
            title: 'Status',
            dataIndex: 'is_active',
            key: 'is_active',
            width: 90,
            render: (v) => (v === false ? <Tag color="red">Inactive</Tag> : <Tag color="green">Active</Tag>),
        },
        {
            title: 'JSON',
            key: 'json',
            width: 220,
            render: (_, record) => (
                <Space size="small">
                    <Button
                        type="link"
                        size="small"
                        onClick={() => openJsonEditor(record, 'input_schema', 'Input schema (JSON)')}
                    >
                        Input
                    </Button>
                    <Button
                        type="link"
                        size="small"
                        onClick={() => openJsonEditor(record, 'workflow_definition', 'Workflow definition (JSON)')}
                    >
                        Workflow
                    </Button>
                    <Button
                        type="link"
                        size="small"
                        onClick={() => openJsonEditor(record, 'output_schema', 'Output schema (JSON)')}
                    >
                        Output
                    </Button>
                    <Button
                        type="link"
                        size="small"
                        onClick={() => openJsonEditor(record, 'retry_policy_json', 'Retry policy (JSON)')}
                    >
                        Retry
                    </Button>
                </Space>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 160,
            render: (_, record) => (
                <Space>
                    <Button type="link" size="small" icon={<EditOutlined />} onClick={() => openEdit(record)}>
                        Edit
                    </Button>
                    {record.is_active !== false ? (
                        <Popconfirm
                            title="Deactivate this template? Jobs and schedulers using it will no longer run new jobs."
                            onConfirm={() => handleDeactivate(record)}
                        >
                            <Button type="link" size="small" danger icon={<StopOutlined />}>
                                Deactivate
                            </Button>
                        </Popconfirm>
                    ) : (
                        <Button type="link" size="small" icon={<CheckCircleOutlined />} onClick={() => handleActivate(record)}>
                            Activate
                        </Button>
                    )}
                </Space>
            ),
        },
    ];

    return (
        <>
            <Card
                title={
                    <Space>
                        <FileTextOutlined />
                        Job Templates
                    </Space>
                }
                extra={
                    <Space>
                        <Button type="primary" icon={<PlusOutlined />} onClick={openAdd}>
                            Add template
                        </Button>
                        <Button icon={<ReloadOutlined />} onClick={fetchTemplates} loading={loading}>
                            Refresh
                        </Button>
                    </Space>
                }
            >
                <VCSearchFilterBar
                    searchPlaceholder="Search name, description, handler function…"
                    searchValue={searchText}
                    onSearchValueChange={setSearchText}
                    filters={filters}
                    onFiltersChange={setFilters}
                    filterOptions={{
                        categories: TEMPLATE_CATEGORIES,
                        handlerTypes: HANDLER_TYPES,
                        modes: CONCURRENCY_MODES,
                    }}
                    onReset={resetFilters}
                />
                <Table
                    rowKey="template_id"
                    columns={columns}
                    dataSource={filteredTemplates}
                    loading={loading}
                    pagination={{ pageSize: 20 }}
                    size="small"
                />
            </Card>

            <Drawer
                title={editingId ? 'Edit job template' : 'Add job template'}
                open={drawerVisible}
                onClose={() => setDrawerVisible(false)}
                width={800}
                footer={
                    <Space>
                        <Button onClick={() => setDrawerVisible(false)}>Cancel</Button>
                        <Button type="primary" onClick={handleSubmit}>
                            {editingId ? 'Update' : 'Create'}
                        </Button>
                    </Space>
                }
            >
                <Form form={form} layout="vertical">
                    <Form.Item name="name" label="Name" rules={[{ required: true }]}>
                        <Input placeholder="e.g. send_email" disabled={!!editingId} />
                    </Form.Item>
                    <Form.Item name="description" label="Description">
                        <Input.TextArea rows={2} placeholder="Optional" />
                    </Form.Item>
                    <Form.Item name="template_category" label="Category" rules={[{ required: true }]}>
                        <Select placeholder="task | workflow | system">
                            {TEMPLATE_CATEGORIES.map((c) => (
                                <Option key={c.value} value={c.value}>{c.label}</Option>
                            ))}
                        </Select>
                    </Form.Item>
                    <Form.Item name="handler_type" label="Handler type" rules={[{ required: true }]}>
                        <Select>
                            {HANDLER_TYPES.map((t) => (
                                <Option key={t} value={t}>{t}</Option>
                            ))}
                        </Select>
                    </Form.Item>
                    <Form.Item name="handler_function_name" label="Handler function name">
                        <Input placeholder="e.g. send_email (used for core_function)" />
                    </Form.Item>
                    <Form.Item name="default_timeout_seconds" label="Timeout (seconds)">
                        <InputNumber min={1} style={{ width: '100%' }} />
                    </Form.Item>
                    <Form.Item name="queue_concurrency_mode" label="Concurrency mode">
                        <Select>
                            {CONCURRENCY_MODES.map((m) => (
                                <Option key={m} value={m}>{m}</Option>
                            ))}
                        </Select>
                    </Form.Item>
                    <Form.Item name="queue_concurrency_limit" label="Concurrency limit">
                        <InputNumber min={0} style={{ width: '100%' }} />
                    </Form.Item>
                    <Form.Item name="is_idempotent" label="Idempotent" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                    {editingId && (
                        <>
                            <Form.Item name="is_active" label="Active" valuePropName="checked">
                                <Switch checkedChildren="Active" unCheckedChildren="Inactive" />
                            </Form.Item>
                            <Form.Item name="version" label="Version">
                                <InputNumber min={1} style={{ width: '100%' }} disabled />
                            </Form.Item>
                            <Form.Item name="runnable_in" label="Runnable in">
                                <Input placeholder="e.g. local, remote" disabled />
                            </Form.Item>
                            <Form.Item name="capabilities" label="Capabilities">
                                <Input placeholder="comma-separated capabilities" disabled />
                            </Form.Item>
                        </>
                    )}
                </Form>
            </Drawer>

            {errorModal && (
                <ErrorModal
                    visible={!!errorModal}
                    error={errorModal}
                    onClose={() => setErrorModal(null)}
                />
            )}

            <Drawer
                title={jsonMeta ? jsonMeta.label : 'Edit JSON'}
                open={jsonDrawerVisible}
                onClose={() => {
                    setJsonDrawerVisible(false);
                    setJsonMeta(null);
                    jsonForm.resetFields();
                }}
                width={800}
                footer={
                    <Space>
                        <Button
                            onClick={() => {
                                setJsonDrawerVisible(false);
                                setJsonMeta(null);
                                jsonForm.resetFields();
                            }}
                        >
                            Cancel
                        </Button>
                        <Button type="primary" onClick={handleJsonSave}>
                            Save JSON
                        </Button>
                    </Space>
                }
            >
                <Form form={jsonForm} layout="vertical">
                    {jsonMeta && (
                        <VCJsonEditor
                            component={{
                                input_values: {
                                    name: 'json_value',
                                    label: jsonMeta.label,
                                    required: false,
                                    default_open: true,
                                    default_value: jsonMeta.defaultValue || '',
                                },
                            }}
                        />
                    )}
                </Form>
            </Drawer>
        </>
    );
};

export default JobTemplates;
