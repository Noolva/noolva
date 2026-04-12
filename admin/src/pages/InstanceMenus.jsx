import React, { useCallback, useEffect, useMemo, useState } from 'react';
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
    Select,
    Typography,
    message,
    Popconfirm,
    Tag,
    Drawer,
    Row,
    Col,
} from 'antd';
import { PlusOutlined, ReloadOutlined, EditOutlined, DeleteOutlined, ApartmentOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const { Text, Title } = Typography;

const CLIENT_TYPES = [
    { value: 'web', label: 'Web' },
    { value: 'android', label: 'Android' },
    { value: 'ios', label: 'iOS' },
    { value: 'macos', label: 'macOS' },
    { value: 'linux', label: 'Linux' },
];

const RENDER_MODES = [
    { value: 'web', label: 'web' },
    { value: 'native', label: 'native' },
    { value: 'webview', label: 'webview' },
];

function defaultConfigsForForm(existing = []) {
    const byType = Object.fromEntries((existing || []).map((c) => [c.client_type, c]));
    return CLIENT_TYPES.map((ct) => {
        const cur = byType[ct.value];
        return {
            client_type: ct.value,
            render_mode: cur?.render_mode || (ct.value === 'web' ? 'web' : 'native'),
            is_enabled: cur ? !!cur.is_enabled : true,
        };
    });
}

export default function InstanceMenus() {
    const [instances, setInstances] = useState([]);
    const [instanceId, setInstanceId] = useState(null);
    const [menus, setMenus] = useState([]);
    const [loading, setLoading] = useState(false);
    const [instancesLoading, setInstancesLoading] = useState(true);
    const [errorModal, setErrorModal] = useState(null);
    const [menuModalOpen, setMenuModalOpen] = useState(false);
    const [editingMenu, setEditingMenu] = useState(null);
    const [configDrawerOpen, setConfigDrawerOpen] = useState(false);
    const [configMenu, setConfigMenu] = useState(null);
    const [configRows, setConfigRows] = useState([]);
    const [savingConfigs, setSavingConfigs] = useState(false);
    const [menuForm] = Form.useForm();

    const handleApiError = useCallback((err) => {
        if (err?.errorData) setErrorModal(err);
        else message.error(err?.message || 'Request failed');
    }, []);

    const loadInstances = useCallback(async () => {
        try {
            setInstancesLoading(true);
            const rows = await api.listClientInstances();
            const list = Array.isArray(rows) ? rows : [];
            setInstances(list);
            setInstanceId((cur) => (cur != null ? cur : list[0]?.instance_id ?? null));
        } catch (e) {
            handleApiError(e);
            setInstances([]);
        } finally {
            setInstancesLoading(false);
        }
    }, [handleApiError]);

    const loadMenus = useCallback(async () => {
        if (!instanceId) {
            setMenus([]);
            return;
        }
        try {
            setLoading(true);
            const data = await api.listInstanceMenus(instanceId);
            setMenus(data.menus || []);
        } catch (e) {
            handleApiError(e);
            setMenus([]);
        } finally {
            setLoading(false);
        }
    }, [instanceId, handleApiError]);

    useEffect(() => {
        loadInstances();
    }, []);

    useEffect(() => {
        loadMenus();
    }, [loadMenus]);

    const idToTitle = useMemo(() => {
        const m = {};
        menus.forEach((r) => {
            m[r.id] = r.menu_title;
        });
        return m;
    }, [menus]);

    const parentOptions = useMemo(() => {
        return menus
            .filter((m) => !editingMenu || m.id !== editingMenu.id)
            .map((m) => ({ value: m.id, label: m.menu_title }));
    }, [menus, editingMenu]);

    const openCreateMenu = () => {
        setEditingMenu(null);
        menuForm.resetFields();
        menuForm.setFieldsValue({
            menu_title: '',
            route_path: '',
            icon_key: '',
            parent_id: null,
            sort_order: 0,
            is_builtin: false,
        });
        setMenuModalOpen(true);
    };

    const openEditMenu = (row) => {
        setEditingMenu(row);
        menuForm.setFieldsValue({
            menu_title: row.menu_title,
            route_path: row.route_path || '',
            icon_key: row.icon_key || '',
            parent_id: row.parent_id ?? null,
            sort_order: row.sort_order ?? 0,
            is_builtin: !!row.is_builtin,
        });
        setMenuModalOpen(true);
    };

    const submitMenu = async () => {
        try {
            const v = await menuForm.validateFields();
            const payload = {
                menu_title: v.menu_title?.trim(),
                route_path: (v.route_path || '').trim() || null,
                icon_key: (v.icon_key || '').trim() || null,
                parent_id: v.parent_id ?? null,
                sort_order: v.sort_order ?? 0,
                is_builtin: !!v.is_builtin,
            };
            if (editingMenu) {
                await api.updateInstanceMenu(instanceId, editingMenu.id, payload);
                message.success('Menu updated');
            } else {
                await api.createInstanceMenu(instanceId, payload);
                message.success('Menu created');
            }
            setMenuModalOpen(false);
            await loadMenus();
        } catch (e) {
            if (e?.errorFields) return;
            handleApiError(e);
        }
    };

    const removeMenu = async (row) => {
        try {
            await api.deleteInstanceMenu(instanceId, row.id);
            message.success('Menu deleted');
            await loadMenus();
        } catch (e) {
            handleApiError(e);
        }
    };

    const openClientConfig = (row) => {
        setConfigMenu(row);
        setConfigRows(defaultConfigsForForm(row.client_configs));
        setConfigDrawerOpen(true);
    };

    const saveClientConfigs = async () => {
        if (!configMenu) return;
        try {
            setSavingConfigs(true);
            await api.updateInstanceMenuClientConfigs(instanceId, configMenu.id, { configs: configRows });
            message.success('Client configuration saved');
            setConfigDrawerOpen(false);
            await loadMenus();
        } catch (e) {
            handleApiError(e);
        } finally {
            setSavingConfigs(false);
        }
    };

    const columns = [
        { title: 'Order', dataIndex: 'sort_order', key: 'sort_order', width: 72 },
        { title: 'Title', dataIndex: 'menu_title', key: 'menu_title', ellipsis: true },
        {
            title: 'Parent',
            key: 'parent',
            width: 140,
            ellipsis: true,
            render: (_, row) =>
                row.parent_id == null ? (
                    <Text type="secondary">—</Text>
                ) : (
                    idToTitle[row.parent_id] || row.parent_id
                ),
        },
        { title: 'Route', dataIndex: 'route_path', key: 'route_path', ellipsis: true },
        { title: 'Icon key', dataIndex: 'icon_key', key: 'icon_key', width: 110, ellipsis: true },
        {
            title: 'Flags',
            key: 'flags',
            width: 100,
            render: (_, row) =>
                row.is_builtin ? (
                    <Tag color="blue">builtin</Tag>
                ) : (
                    <Text type="secondary">—</Text>
                ),
        },
        {
            title: 'Clients',
            key: 'cc',
            width: 88,
            render: (_, row) => {
                const n = Array.isArray(row.client_configs) ? row.client_configs.length : 0;
                return <Tag>{n}</Tag>;
            },
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 220,
            fixed: 'right',
            render: (_, row) => (
                <Space size="small" wrap>
                    <Button type="link" size="small" icon={<ApartmentOutlined />} onClick={() => openClientConfig(row)}>
                        Clients
                    </Button>
                    <Button type="link" size="small" icon={<EditOutlined />} onClick={() => openEditMenu(row)}>
                        Edit
                    </Button>
                    <Popconfirm title="Delete this menu and its client rows?" onConfirm={() => removeMenu(row)}>
                        <Button type="link" size="small" danger icon={<DeleteOutlined />}>
                            Delete
                        </Button>
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    const selectedInstanceName = instances.find((x) => x.instance_id === instanceId)?.name;

    return (
        <div style={{ padding: 24 }}>
            <Space direction="vertical" size="large" style={{ width: '100%' }}>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, alignItems: 'center', justifyContent: 'space-between' }}>
                    <div>
                        <Title level={3} style={{ margin: 0 }}>
                            Instance menus
                        </Title>
                        <Text type="secondary">
                            Navigation for <Text strong>client instance</Text> apps (web / native shells). This is separate from Noolva console
                            sidebar menus stored in <Text code>public.menus</Text>.
                        </Text>
                    </div>
                    <Space wrap>
                        <Select
                            showSearch
                            optionFilterProp="label"
                            loading={instancesLoading}
                            style={{ minWidth: 260 }}
                            placeholder="Select client instance"
                            value={instanceId ?? undefined}
                            onChange={(v) => setInstanceId(v)}
                            options={instances.map((i) => ({
                                value: i.instance_id,
                                label: `${i.name} (#${i.instance_id})`,
                            }))}
                        />
                        <Button icon={<ReloadOutlined />} onClick={() => loadMenus()} disabled={!instanceId || loading}>
                            Refresh
                        </Button>
                        <Button type="primary" icon={<PlusOutlined />} onClick={openCreateMenu} disabled={!instanceId}>
                            Add menu
                        </Button>
                    </Space>
                </div>

                <Card size="small" title={selectedInstanceName ? `Menus — ${selectedInstanceName}` : 'Menus'}>
                    <Table
                        size="small"
                        rowKey="id"
                        loading={loading}
                        columns={columns}
                        dataSource={menus}
                        scroll={{ x: 960 }}
                        pagination={{ pageSize: 20, showSizeChanger: true }}
                    />
                </Card>
            </Space>

            <Modal
                title={editingMenu ? 'Edit instance menu' : 'New instance menu'}
                open={menuModalOpen}
                onOk={submitMenu}
                onCancel={() => setMenuModalOpen(false)}
                destroyOnClose
                width={560}
            >
                <Form form={menuForm} layout="vertical">
                    <Form.Item name="menu_title" label="Menu title" rules={[{ required: true, message: 'Required' }]}>
                        <Input placeholder="e.g. Dashboard" />
                    </Form.Item>
                    <Form.Item name="route_path" label="Route path">
                        <Input placeholder="Client app route / deep link" />
                    </Form.Item>
                    <Form.Item name="icon_key" label="Icon key">
                        <Input placeholder="global_icons key (optional)" />
                    </Form.Item>
                    <Form.Item name="parent_id" label="Parent menu">
                        <Select allowClear placeholder="Top level" options={parentOptions} />
                    </Form.Item>
                    <Form.Item name="sort_order" label="Sort order">
                        <InputNumber style={{ width: '100%' }} />
                    </Form.Item>
                    <Form.Item name="is_builtin" label="Built-in" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                </Form>
            </Modal>

            <Drawer
                title={configMenu ? `Client stacks — ${configMenu.menu_title}` : 'Client stacks'}
                open={configDrawerOpen}
                onClose={() => setConfigDrawerOpen(false)}
                width="min(1120px, calc(100vw - 32px))"
                styles={{ body: { paddingBottom: 24 } }}
                extra={
                    <Button type="primary" loading={savingConfigs} onClick={saveClientConfigs}>
                        Save
                    </Button>
                }
            >
                <Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
                    One column per client stack. Set <Text code>render_mode</Text> and whether the item is enabled for that platform.
                </Text>
                <Row gutter={[16, 16]} wrap style={{ width: '100%' }}>
                    {configRows.map((row, idx) => (
                        <Col key={row.client_type} xs={24} sm={12} md={8} lg={8} xl={{ flex: '1 1 0', minWidth: 190 }}>
                            <Card
                                size="small"
                                title={CLIENT_TYPES.find((c) => c.value === row.client_type)?.label}
                                styles={{ body: { paddingBottom: 12 } }}
                            >
                                <Space direction="vertical" style={{ width: '100%' }} size="small">
                                    <div>
                                        <Text type="secondary">Render mode</Text>
                                        <Select
                                            style={{ width: '100%', marginTop: 4 }}
                                            value={row.render_mode}
                                            options={RENDER_MODES}
                                            onChange={(v) => {
                                                const next = [...configRows];
                                                next[idx] = { ...next[idx], render_mode: v };
                                                setConfigRows(next);
                                            }}
                                        />
                                    </div>
                                    <div>
                                        <Text type="secondary">Enabled</Text>
                                        <div style={{ marginTop: 8 }}>
                                            <Switch
                                                checked={row.is_enabled}
                                                onChange={(v) => {
                                                    const next = [...configRows];
                                                    next[idx] = { ...next[idx], is_enabled: v };
                                                    setConfigRows(next);
                                                }}
                                            />
                                        </div>
                                    </div>
                                </Space>
                            </Card>
                        </Col>
                    ))}
                </Row>
            </Drawer>

            <ErrorModal visible={!!errorModal} error={errorModal} onClose={() => setErrorModal(null)} />
        </div>
    );
}
