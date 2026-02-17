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
    Select,
    Switch,
    message,
    Popconfirm,
    Tag,
    Typography,
    Alert,
    Modal,
    Pagination
} from 'antd';
import {
    PlusOutlined,
    EditOutlined,
    DeleteOutlined,
    ApiOutlined,
    SearchOutlined,
    CodeOutlined,
    DatabaseOutlined,
    PlayCircleOutlined,
    WarningOutlined,
} from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';
import QueryBuilderModal from '../components/ViewComponents/inputs/QueryBuilderModal';

const { Option } = Select;
const { TextArea } = Input;
const { Text } = Typography;

const METHOD_OPTIONS = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];
const TYPE_OPTIONS = [
    { value: 'auto_crud', label: 'Auto CRUD', desc: 'Standard REST on a model' },
    { value: 'custom_query', label: 'Custom Query', desc: 'Ad-hoc SQL with table joins' },
    { value: 'flattened_view', label: 'Flattened View', desc: 'Read-optimized view' },
];

const ApiEndpoints = () => {
    const [endpoints, setEndpoints] = useState([]);
    const [loading, setLoading] = useState(false);
    const [dataModels, setDataModels] = useState([]);
    const [drawerVisible, setDrawerVisible] = useState(false);
    const [editingEndpoint, setEditingEndpoint] = useState(null);
    const [form] = Form.useForm();
    const [searchText, setSearchText] = useState('');
    const [typeFilter, setTypeFilter] = useState(null);
    const [customQuerySql, setCustomQuerySql] = useState('');
    const [queryBuilderModalVisible, setQueryBuilderModalVisible] = useState(false);
    const [errorModal, setErrorModal] = useState(null);
    const [testerVisible, setTesterVisible] = useState(false);
    const [testerEndpoint, setTesterEndpoint] = useState(null);
    const [testerLoading, setTesterLoading] = useState(false);
    const [testerResult, setTesterResult] = useState(null);
    const [testerError, setTesterError] = useState(null);
    const [testerLimit, setTesterLimit] = useState(10);
    const [testerOffset, setTesterOffset] = useState(0);
    const [testerRecordId, setTesterRecordId] = useState('');
    const [testerFields, setTesterFields] = useState('');
    const [testerBody, setTesterBody] = useState('{}');
    const [orphanedModalVisible, setOrphanedModalVisible] = useState(false);
    const [orphanedList, setOrphanedList] = useState([]);
    const [orphanedLoading, setOrphanedLoading] = useState(false);

    useEffect(() => {
        loadDataModels();
    }, []);

    const loadEndpoints = async () => {
        try {
            setLoading(true);
            const limit = 500;
            let offset = 0;
            const all = [];
            while (true) {
                const response = await api.getApiEndpoints({
                    limit,
                    offset,
                    search: searchText || null,
                    type: typeFilter || null,
                });
                const batch = response.api_endpoints || [];
                all.push(...batch);
                offset += batch.length;
                if (!response.has_more || batch.length === 0) break;
            }
            setEndpoints(all);
        } catch (error) {
            message.error('Failed to load endpoints: ' + (error.message || 'Unknown error'));
            if (error.errorData) setErrorModal(error);
        } finally {
            setLoading(false);
        }
    };

    const loadDataModels = async () => {
        try {
            const response = await api.getDataModels({ limit: 500 });
            setDataModels(response.data_models || []);
        } catch (e) {
            console.error('Failed to load data models:', e);
        }
    };

    const handleFindOrphanedAutoCrud = async () => {
        try {
            setOrphanedLoading(true);
            const res = await api.getOrphanedAutoCrudEndpoints();
            setOrphanedList(res.orphaned || []);
            setOrphanedModalVisible(true);
        } catch (e) {
            message.error('Failed to load orphaned endpoints: ' + (e.message || 'Unknown error'));
            if (e.errorData) setErrorModal(e);
        } finally {
            setOrphanedLoading(false);
        }
    };

    const handleDeleteOrphaned = async (endpointId) => {
        try {
            await api.deleteApiEndpoint(endpointId);
            message.success('Endpoint deleted');
            setOrphanedList((prev) => prev.filter((e) => e.endpoint_id !== endpointId));
        } catch (e) {
            message.error('Delete failed: ' + (e.message || 'Unknown error'));
        }
    };

    useEffect(() => {
        loadEndpoints();
    }, [searchText, typeFilter]);

    const handleCreate = () => {
        setEditingEndpoint(null);
        form.resetFields();
        setCustomQuerySql('');
        form.setFieldsValue({
            method: 'GET',
            type: 'auto_crud',
            reference_model_ids: [],
            is_builtin: false,
        });
        setDrawerVisible(true);
    };

    const handleEdit = async (record) => {
        try {
            const response = await api.getApiEndpoint(record.endpoint_id);
            setEditingEndpoint(response);
            const customJson = response.custom_json || {};
            const query = typeof customJson === 'object' ? (customJson.query || '') : '';
            setCustomQuerySql(query);
            form.setFieldsValue({
                path: response.path,
                method: response.method,
                type: response.type,
                related_model_id: response.related_model_id ?? undefined,
                reference_model_ids: response.reference_model_ids || [],
                permission_required: response.permission_required,
                is_builtin: response.is_builtin,
            });
            setDrawerVisible(true);
        } catch (error) {
            message.error('Failed to load endpoint: ' + (error.message || 'Unknown error'));
        }
    };

    const handleDelete = async (endpointId) => {
        try {
            await api.deleteApiEndpoint(endpointId);
            message.success('Endpoint deleted');
            loadEndpoints();
        } catch (error) {
            message.error('Failed to delete: ' + (error.message || 'Unknown error'));
            if (error.errorData) setErrorModal(error);
        }
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            const payload = {
                path: values.path?.trim(),
                method: values.method,
                type: values.type,
                related_model_id: values.related_model_id ?? null,
                reference_model_ids: values.reference_model_ids || [],
                permission_required: values.permission_required || null,
                is_builtin: values.is_builtin ?? false,
            };

            if (values.type === 'custom_query') {
                payload.custom_json = { query: customQuerySql };
                const relatedIds = values.reference_model_ids || [];
                if (values.related_model_id && !relatedIds.includes(values.related_model_id)) {
                    payload.reference_model_ids = [values.related_model_id, ...relatedIds];
                }
            }

            if (editingEndpoint) {
                await api.updateApiEndpoint(editingEndpoint.endpoint_id, payload);
                message.success('Endpoint updated');
            } else {
                await api.createApiEndpoint(payload);
                message.success('Endpoint created');
            }
            setDrawerVisible(false);
            loadEndpoints();
        } catch (error) {
            if (error.errorFields) return;
            message.error('Failed to save: ' + (error.message || 'Unknown error'));
            if (error.errorData) setErrorModal(error);
        }
    };

    const handleModelSelect = (modelId) => {
        if (!modelId) return;
        const model = dataModels.find((m) => m.model_id === modelId);
        if (!model) return;
        const basePath = `/data-models/auto/${model.model_name}/records`;
        form.setFieldsValue({
            path: basePath,
            related_model_id: modelId,
            reference_model_ids: [modelId],
        });
    };

    const handleTest = (record) => {
        setTesterEndpoint(record);
        setTesterResult(null);
        setTesterError(null);
        setTesterLimit(10);
        setTesterOffset(0);
        setTesterRecordId('');
        setTesterFields('');
        setTesterBody('{}');
        setTesterVisible(true);
    };

    const handleTesterExecute = async (overrides = {}) => {
        if (!testerEndpoint) return;
        const limit = overrides.limit ?? testerLimit;
        const offset = overrides.offset ?? testerOffset;
        setTesterLoading(true);
        setTesterError(null);
        setTesterResult(null);
        try {
            if (testerEndpoint.type === 'custom_query') {
                const data = await api.callCustomEndpoint(testerEndpoint.endpoint_id, {
                    limit,
                    offset,
                });
                setTesterResult(data);
            } else if (testerEndpoint.type === 'auto_crud') {
                const method = testerEndpoint.method || 'GET';
                let path = testerEndpoint.path || '';
                const params = {};
                let body = null;

                if (path.includes('{record_id}')) {
                    if (!testerRecordId) {
                        message.warning('Record ID is required for this endpoint');
                        setTesterLoading(false);
                        return;
                    }
                    path = path.replace('{record_id}', testerRecordId);
                }

                if (method === 'GET' && !path.includes('{record_id}')) {
                    params.limit = limit;
                    params.offset = offset;
                    if (testerFields) params.fields = testerFields;
                } else if (['POST', 'PUT', 'PATCH'].includes(method)) {
                    try {
                        body = JSON.parse(testerBody);
                        if (typeof body === 'object' && !Array.isArray(body) && !('data' in body)) {
                            body = { data: body };
                        }
                    } catch (e) {
                        message.error('Invalid JSON body');
                        setTesterLoading(false);
                        return;
                    }
                }

                const data = await api.testApiCall({ path, method, params, body });
                setTesterResult(data);
            } else {
                message.warning('API Tester supports auto_crud and custom_query types only');
            }
        } catch (error) {
            setTesterError(error);
            if (error.errorData) setErrorModal(error);
        } finally {
            setTesterLoading(false);
        }
    };

    const handleTesterPageChange = (page, pageSize) => {
        const newOffset = (page - 1) * (pageSize || testerLimit);
        const newLimit = pageSize || testerLimit;
        setTesterOffset(newOffset);
        setTesterLimit(newLimit);
        handleTesterExecute({ limit: newLimit, offset: newOffset });
    };

    const tableAliasHint = dataModels
        .filter((m) => m.table_alias)
        .map((m) => `${m.table_name} AS ${m.table_alias}`)
        .join(', ');

    const columns = [
        {
            title: 'Path',
            dataIndex: 'path',
            key: 'path',
            ellipsis: true,
            render: (text) => <Text code copyable>{text}</Text>,
        },
        {
            title: 'Method',
            dataIndex: 'method',
            key: 'method',
            width: 90,
            render: (m) => {
                const color = { GET: 'green', POST: 'blue', PUT: 'orange', DELETE: 'red', PATCH: 'purple' }[m] || 'default';
                return <Tag color={color}>{m}</Tag>;
            },
        },
        {
            title: 'Type',
            dataIndex: 'type',
            key: 'type',
            width: 120,
            render: (t) => <Tag>{t}</Tag>,
        },
        {
            title: 'Model',
            dataIndex: 'model_name',
            key: 'model_name',
            width: 120,
            render: (name, r) => name || (r.related_model_id ? `#${r.related_model_id}` : '-'),
        },
        {
            title: 'Built-in',
            dataIndex: 'is_builtin',
            key: 'is_builtin',
            width: 80,
            render: (v) => (v ? <Tag color="blue">Yes</Tag> : <Tag>No</Tag>),
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 180,
            fixed: 'right',
            render: (_, record) => (
                <Space>
                    <Button type="link" size="small" icon={<PlayCircleOutlined />} onClick={() => handleTest(record)}>
                        Test
                    </Button>
                    <Button type="link" size="small" icon={<EditOutlined />} onClick={() => handleEdit(record)}>
                        Edit
                    </Button>
                    {!record.is_builtin && (
                        <Popconfirm
                            title="Delete this endpoint?"
                            onConfirm={() => handleDelete(record.endpoint_id)}
                            okText="Delete"
                            okType="danger"
                        >
                            <Button type="link" danger size="small" icon={<DeleteOutlined />}>
                                Delete
                            </Button>
                        </Popconfirm>
                    )}
                </Space>
            ),
        },
    ];

    return (
        <div style={{ padding: '20px' }}>
            <Card>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                    <h2 style={{ margin: 0 }}>
                        <ApiOutlined /> API Endpoints
                    </h2>
                    <Button type="primary" icon={<PlusOutlined />} onClick={handleCreate}>
                        Add Endpoint
                    </Button>
                </div>

                <Space style={{ marginBottom: 16 }} wrap>
                    <Input
                        placeholder="Search path, method, type..."
                        prefix={<SearchOutlined />}
                        value={searchText}
                        onChange={(e) => setSearchText(e.target.value)}
                        style={{ width: 260 }}
                        allowClear
                    />
                    <Select
                        placeholder="Filter by type"
                        value={typeFilter}
                        onChange={setTypeFilter}
                        style={{ width: 160 }}
                        allowClear
                    >
                        {TYPE_OPTIONS.map((o) => (
                            <Option key={o.value} value={o.value}>{o.label}</Option>
                        ))}
                    </Select>
                    <Button onClick={loadEndpoints} icon={<DatabaseOutlined />}>
                        Refresh
                    </Button>
                    <Button
                        icon={<WarningOutlined />}
                        onClick={handleFindOrphanedAutoCrud}
                        loading={orphanedLoading}
                        title="Detect auto CRUD endpoints whose data model was deleted"
                    >
                        Find orphaned auto CRUD
                    </Button>
                </Space>

                <Table
                    columns={columns}
                    dataSource={endpoints}
                    rowKey="endpoint_id"
                    loading={loading}
                    pagination={{ pageSize: 50, showSizeChanger: true, showTotal: (t) => `Total ${t}` }}
                    scroll={{ x: 800 }}
                />
            </Card>

            <Modal
                title={
                    <Space>
                        <WarningOutlined />
                        Orphaned auto CRUD endpoints
                    </Space>
                }
                open={orphanedModalVisible}
                onCancel={() => setOrphanedModalVisible(false)}
                footer={
                    <Button type="primary" onClick={() => setOrphanedModalVisible(false)}>
                        Close
                    </Button>
                }
                width={640}
            >
                <Alert
                    type="info"
                    message="These are auto CRUD endpoints whose linked data model no longer exists. You can delete them to keep the list clean."
                    style={{ marginBottom: 16 }}
                />
                {orphanedList.length === 0 ? (
                    <Text type="secondary">No orphaned endpoints found.</Text>
                ) : (
                    <Table
                        size="small"
                        dataSource={orphanedList}
                        rowKey="endpoint_id"
                        pagination={false}
                        columns={[
                            { title: 'Path', dataIndex: 'path', key: 'path', ellipsis: true },
                            { title: 'Method', dataIndex: 'method', key: 'method', width: 72 },
                            {
                                title: 'Actions',
                                key: 'actions',
                                width: 90,
                                render: (_, record) => (
                                    <Popconfirm
                                        title="Delete this endpoint?"
                                        onConfirm={() => handleDeleteOrphaned(record.endpoint_id)}
                                        okText="Delete"
                                        cancelText="Cancel"
                                    >
                                        <Button type="link" danger size="small" icon={<DeleteOutlined />}>
                                            Delete
                                        </Button>
                                    </Popconfirm>
                                ),
                            },
                        ]}
                    />
                )}
            </Modal>

            <Drawer
                title={editingEndpoint ? 'Edit API Endpoint' : 'Add API Endpoint'}
                open={drawerVisible}
                onClose={() => setDrawerVisible(false)}
                width={720}
                extra={
                    <Space>
                        <Button onClick={() => setDrawerVisible(false)}>Cancel</Button>
                        <Button type="primary" onClick={handleSubmit}>Save</Button>
                    </Space>
                }
            >
                <Form form={form} layout="vertical">
                    <Form.Item name="type" label="Type" rules={[{ required: true }]}>
                        <Select
                            placeholder="Select type"
                            onChange={(t) => {
                                if (t === 'auto_crud') {
                                    form.setFieldsValue({ path: '', related_model_id: undefined, reference_model_ids: [] });
                                } else if (t === 'custom_query') {
                                    setCustomQuerySql('');
                                }
                            }}
                        >
                            {TYPE_OPTIONS.map((o) => (
                                <Option key={o.value} value={o.value}>
                                    {o.label} – {o.desc}
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item noStyle shouldUpdate={(p, c) => p.type !== c.type}>
                        {({ getFieldValue }) => {
                            const type = getFieldValue('type');
                            if (type === 'auto_crud') {
                                return (
                                    <Form.Item label="Model (auto-fills path)" name="related_model_id">
                                        <Select
                                            placeholder="Select model"
                                            allowClear
                                            showSearch
                                            optionFilterProp="children"
                                            onChange={handleModelSelect}
                                        >
                                            {dataModels.map((m) => (
                                                <Option key={m.model_id} value={m.model_id}>
                                                    {m.model_name} ({m.table_name})
                                                </Option>
                                            ))}
                                        </Select>
                                    </Form.Item>
                                );
                            }
                            return null;
                        }}
                    </Form.Item>

                    <Form.Item name="path" label="Path" rules={[{ required: true, message: 'Path is required' }]}>
                        <Input placeholder="/data-models/auto/users/records" />
                    </Form.Item>

                    <Form.Item name="method" label="Method" rules={[{ required: true }]}>
                        <Select>
                            {METHOD_OPTIONS.map((m) => (
                                <Option key={m} value={m}>{m}</Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item
                        name="reference_model_ids"
                        label="Reference Models (for permissions)"
                        tooltip="Models used in this endpoint; permissions from model_row_access_policies apply"
                    >
                        <Select mode="multiple" placeholder="Select models" allowClear showSearch optionFilterProp="children">
                            {dataModels.map((m) => (
                                <Option key={m.model_id} value={m.model_id}>
                                    {m.model_name} {m.table_alias ? `(${m.table_alias})` : ''}
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item noStyle shouldUpdate={(p, c) => p.type !== c.type}>
                        {({ getFieldValue }) => {
                            const type = getFieldValue('type');
                            if (type === 'custom_query') {
                                return (
                                    <>
                                        <Form.Item
                                            label={
                                                <span>
                                                    <CodeOutlined /> Custom Query (use table_alias from data_models)
                                                </span>
                                            }
                                        >
                                            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                                                <Input.TextArea
                                                    value={customQuerySql}
                                                    onChange={(e) => setCustomQuerySql(e.target.value)}
                                                    placeholder="SELECT ... FROM table alias JOIN table2 alias2 ON ..."
                                                    rows={6}
                                                    style={{ fontFamily: 'monospace', fontSize: 13 }}
                                                />
                                                <Button
                                                    icon={<CodeOutlined />}
                                                    onClick={() => setQueryBuilderModalVisible(true)}
                                                    style={{ alignSelf: 'flex-start' }}
                                                >
                                                    Query Builder
                                                </Button>
                                            </div>
                                        </Form.Item>
                                        {tableAliasHint && (
                                            <Alert
                                                type="info"
                                                showIcon
                                                message="Table aliases"
                                                description={tableAliasHint}
                                                style={{ marginBottom: 16 }}
                                            />
                                        )}
                                        <QueryBuilderModal
                                            visible={queryBuilderModalVisible}
                                            onClose={() => setQueryBuilderModalVisible(false)}
                                            onUseQuery={(sql) => setCustomQuerySql(sql)}
                                            dataSource="dataModels"
                                            dataModels={dataModels}
                                            showPreviewResults={false}
                                            initialValue={customQuerySql}
                                        />
                                    </>
                                );
                            }
                            return null;
                        }}
                    </Form.Item>

                    <Form.Item name="permission_required" label="Permission Required">
                        <Input placeholder="Optional role/permission key" />
                    </Form.Item>

                    <Form.Item name="is_builtin" label="Built-in" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                </Form>
            </Drawer>

            <Modal
                title={
                    <Space>
                        <PlayCircleOutlined />
                        API Tester
                        {testerEndpoint && (
                            <>
                                <Tag color="blue">{testerEndpoint.method}</Tag>
                                <Text code style={{ fontSize: 12 }}>{testerEndpoint.path}</Text>
                            </>
                        )}
                    </Space>
                }
                open={testerVisible}
                onCancel={() => setTesterVisible(false)}
                width={900}
                footer={null}
                destroyOnClose
            >
                {testerEndpoint && (
                    <>
                        <Space direction="vertical" style={{ width: '100%', marginBottom: 16 }} wrap>
                            {testerEndpoint.type === 'custom_query' && (
                                <Space wrap>
                                    <span>Limit:</span>
                                    <InputNumber
                                        min={1}
                                        max={1000}
                                        value={testerLimit}
                                        onChange={setTesterLimit}
                                        style={{ width: 80 }}
                                    />
                                    <span>Offset:</span>
                                    <InputNumber
                                        min={0}
                                        value={testerOffset}
                                        onChange={setTesterOffset}
                                        style={{ width: 80 }}
                                    />
                                </Space>
                            )}
                            {testerEndpoint.type === 'auto_crud' && (
                                <>
                                    {testerEndpoint.path?.includes('{record_id}') && (
                                        <Space wrap>
                                            <span>Record ID:</span>
                                            <Input
                                                placeholder="record_id"
                                                value={testerRecordId}
                                                onChange={(e) => setTesterRecordId(e.target.value)}
                                                style={{ width: 120 }}
                                            />
                                        </Space>
                                    )}
                                    {testerEndpoint.method === 'GET' && !testerEndpoint.path?.includes('{record_id}') && (
                                        <Space wrap>
                                            <span>Limit:</span>
                                            <InputNumber
                                                min={1}
                                                max={1000}
                                                value={testerLimit}
                                                onChange={setTesterLimit}
                                                style={{ width: 80 }}
                                            />
                                            <span>Offset:</span>
                                            <InputNumber
                                                min={0}
                                                value={testerOffset}
                                                onChange={setTesterOffset}
                                                style={{ width: 80 }}
                                            />
                                            <span>Fields (optional):</span>
                                            <Input
                                                placeholder="comma-separated"
                                                value={testerFields}
                                                onChange={(e) => setTesterFields(e.target.value)}
                                                style={{ width: 180 }}
                                            />
                                        </Space>
                                    )}
                                    {['POST', 'PUT', 'PATCH'].includes(testerEndpoint.method) && (
                                        <div style={{ width: '100%' }}>
                                            <div style={{ marginBottom: 4 }}>Request Body (JSON):</div>
                                            <Input.TextArea
                                                value={testerBody}
                                                onChange={(e) => setTesterBody(e.target.value)}
                                                rows={4}
                                                style={{ fontFamily: 'monospace', fontSize: 12 }}
                                                placeholder='{"field1": "value1", "field2": 123}'
                                            />
                                        </div>
                                    )}
                                </>
                            )}
                            <Button
                                type="primary"
                                icon={<PlayCircleOutlined />}
                                onClick={() => handleTesterExecute()}
                                loading={testerLoading}
                            >
                                Execute
                            </Button>
                        </Space>

                        {testerError && (
                            <Alert
                                type="error"
                                message={testerError.message || 'Request failed'}
                                style={{ marginBottom: 16 }}
                                closable
                                onClose={() => setTesterError(null)}
                            />
                        )}

                        {testerResult && (
                            <div>
                                <div style={{ marginBottom: 8, fontWeight: 500 }}>
                                    Results
                                    {testerResult.row_count != null && (
                                        <span style={{ marginLeft: 8, color: '#666' }}>
                                            ({testerResult.row_count} rows)
                                        </span>
                                    )}
                                    {(testerResult.records || testerResult.record) && (
                                        <span style={{ marginLeft: 8, color: '#666' }}>
                                            Page: offset {testerResult.offset ?? testerOffset}, limit {testerResult.limit ?? testerLimit}
                                        </span>
                                    )}
                                </div>
                                <Table
                                    dataSource={
                                        testerResult.records
                                            ? testerResult.records
                                            : testerResult.record
                                                ? [testerResult.record]
                                                : []
                                    }
                                    columns={(testerResult.columns || []).length > 0
                                        ? (testerResult.columns || []).map((c) => ({
                                            title: c,
                                            dataIndex: c,
                                            key: c,
                                            ellipsis: true,
                                        }))
                                        : (testerResult.records?.[0] || testerResult.record)
                                            ? Object.keys(testerResult.records?.[0] || testerResult.record).map((c) => ({
                                                title: c,
                                                dataIndex: c,
                                                key: c,
                                                ellipsis: true,
                                            }))
                                            : []}
                                    rowKey={(_, i) => i}
                                    size="small"
                                    pagination={{
                                        pageSize: testerLimit,
                                        current: Math.floor((testerOffset || 0) / testerLimit) + 1,
                                        total: testerResult.total ?? (() => {
                                            const len = testerResult.records?.length || (testerResult.record ? 1 : 0);
                                            return testerOffset + len + (len >= testerLimit ? testerLimit : 0);
                                        })(),
                                        showSizeChanger: true,
                                        showTotal: (t) => `Total ${t} items`,
                                        onChange: handleTesterPageChange,
                                    }}
                                    scroll={{ x: 600 }}
                                />
                            </div>
                        )}
                    </>
                )}
            </Modal>

            {errorModal && (
                <ErrorModal
                    visible={!!errorModal}
                    error={errorModal}
                    onClose={() => setErrorModal(null)}
                />
            )}
        </div>
    );
};

export default ApiEndpoints;
