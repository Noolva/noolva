import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, Space, Typography, message, App } from 'antd';
import { UserAddOutlined, LockOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const { Title, Text } = Typography;

const USER_TYPES = [
    { value: 'tenant_user', label: 'Tenant User' },
    { value: 'tenant_admin', label: 'Tenant Admin' },
    { value: 'saas_employee', label: 'SaaS Employee' },
    { value: 'saas_admin', label: 'SaaS Admin' },
    { value: 'saas_reseller', label: 'SaaS Reseller' },
    { value: 'saas_promoter', label: 'SaaS Promoter' },
];

const ACTIVE_STATUS_OPTIONS = [
    { value: 1, label: 'Active' },
    { value: 0, label: 'Inactive' },
    { value: 2, label: 'Suspended' },
];

const OrganizationUsers = () => {
    const { message: messageApi } = App.useApp();
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [createModalVisible, setCreateModalVisible] = useState(false);
    const [resetModalVisible, setResetModalVisible] = useState(false);
    const [resetUserId, setResetUserId] = useState(null);
    const [submitLoading, setSubmitLoading] = useState(false);
    const [errorModalVisible, setErrorModalVisible] = useState(false);
    const [errorDetails, setErrorDetails] = useState(null);
    const [form] = Form.useForm();
    const [resetForm] = Form.useForm();

    const loadUsers = async () => {
        setLoading(true);
        try {
            const data = await api.getOrganizationUsers();
            setUsers(data.users || []);
        } catch (err) {
            setErrorDetails(err);
            setErrorModalVisible(true);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadUsers();
    }, []);

    const handleCreateUser = async (values) => {
        setSubmitLoading(true);
        try {
            await api.createUser({
                username: values.username,
                password: values.password,
                email: values.email || null,
                phone: values.phone || null,
                first_name: values.first_name || null,
                last_name: values.last_name || null,
                user_type: values.user_type || 'tenant_user',
                active_status: values.active_status ?? 1,
                idle_timeout_minutes: values.idle_timeout_minutes !== undefined && values.idle_timeout_minutes !== '' ? Number(values.idle_timeout_minutes) : null,
            });
            messageApi.success('User created successfully');
            form.resetFields();
            setCreateModalVisible(false);
            loadUsers();
        } catch (err) {
            setErrorDetails(err);
            setErrorModalVisible(true);
        } finally {
            setSubmitLoading(false);
        }
    };

    const handleResetPassword = (record) => {
        setResetUserId(record.user_id);
        resetForm.resetFields();
        setResetModalVisible(true);
    };

    const handleResetPasswordSubmit = async (values) => {
        if (!resetUserId) return;
        setSubmitLoading(true);
        try {
            await api.resetUserPassword(resetUserId, values.new_password);
            messageApi.success('Password reset successfully');
            setResetModalVisible(false);
            setResetUserId(null);
            resetForm.resetFields();
        } catch (err) {
            setErrorDetails(err);
            setErrorModalVisible(true);
        } finally {
            setSubmitLoading(false);
        }
    };

    const columns = [
        { title: 'Username', dataIndex: 'username', key: 'username', ellipsis: true },
        { title: 'Email', dataIndex: 'email', key: 'email', ellipsis: true, render: (v) => v || '—' },
        { title: 'Phone', dataIndex: 'phone', key: 'phone', width: 120, render: (v) => v || '—' },
        {
            title: 'Name',
            key: 'name',
            width: 160,
            render: (_, record) => {
                const name = [record.first_name, record.last_name].filter(Boolean).join(' ');
                return name || '—';
            },
        },
        {
            title: 'Type',
            dataIndex: 'user_type',
            key: 'user_type',
            width: 120,
            render: (v) => (v || '').replace(/_/g, ' '),
        },
        {
            title: 'Status',
            dataIndex: 'active_status',
            key: 'active_status',
            width: 100,
            render: (v) => {
                const map = { 1: 'Active', 0: 'Inactive', 2: 'Suspended' };
                return map[v] ?? v;
            },
        },
        {
            title: '2FA',
            dataIndex: 'enable_2fa',
            key: 'enable_2fa',
            width: 70,
            render: (v) => (v ? 'Yes' : '—'),
        },
        {
            title: 'Idle lock (min)',
            dataIndex: 'idle_timeout_minutes',
            key: 'idle_timeout_minutes',
            width: 110,
            render: (v) => (v === -1 ? 'No lock' : v != null ? `${v}` : 'Default'),
        },
        {
            title: 'Last login',
            dataIndex: 'last_login',
            key: 'last_login',
            width: 160,
            render: (v) => (v ? new Date(v).toLocaleString() : '—'),
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 120,
            fixed: 'right',
            render: (_, record) => (
                <Space>
                    <Button
                        type="link"
                        size="small"
                        icon={<LockOutlined />}
                        onClick={() => handleResetPassword(record)}
                    >
                        Reset password
                    </Button>
                </Space>
            ),
        },
    ];

    return (
        <div style={{ padding: '16px 0' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <Title level={5} style={{ margin: 0 }}>Users</Title>
                <Button
                    type="primary"
                    icon={<UserAddOutlined />}
                    onClick={() => {
                        form.resetFields();
                        setCreateModalVisible(true);
                    }}
                >
                    Create user
                </Button>
            </div>

            <Table
                dataSource={users}
                columns={columns}
                rowKey="user_id"
                loading={loading}
                size="small"
                scroll={{ x: 900 }}
                pagination={{ pageSize: 20, showSizeChanger: true, showTotal: (t) => `Total ${t} users` }}
            />

            <Modal
                title="Create user"
                open={createModalVisible}
                onCancel={() => setCreateModalVisible(false)}
                footer={null}
                destroyOnClose
                width={480}
            >
                <Form
                    form={form}
                    layout="vertical"
                    onFinish={handleCreateUser}
                    initialValues={{ user_type: 'tenant_user', active_status: 1 }}
                >
                    <Form.Item
                        label="Username"
                        name="username"
                        rules={[{ required: true, message: 'Required' }]}
                    >
                        <Input placeholder="Login ID / email" />
                    </Form.Item>
                    <Form.Item
                        label="Password"
                        name="password"
                        rules={[{ required: true, message: 'Required' }, { min: 6, message: 'At least 6 characters' }]}
                    >
                        <Input.Password placeholder="••••••••" />
                    </Form.Item>
                    <Form.Item label="Email" name="email">
                        <Input type="email" placeholder="email@example.com" />
                    </Form.Item>
                    <Form.Item label="Phone" name="phone">
                        <Input placeholder="Phone" />
                    </Form.Item>
                    <Form.Item label="First name" name="first_name">
                        <Input placeholder="First name" />
                    </Form.Item>
                    <Form.Item label="Last name" name="last_name">
                        <Input placeholder="Last name" />
                    </Form.Item>
                    <Form.Item label="User type" name="user_type">
                        <Select options={USER_TYPES} placeholder="Select type" />
                    </Form.Item>
                    <Form.Item label="Status" name="active_status">
                        <Select options={ACTIVE_STATUS_OPTIONS} />
                    </Form.Item>
                    <Form.Item
                        label="Idle lock (minutes)"
                        name="idle_timeout_minutes"
                        extra="-1 = no lock, leave empty = use global setting"
                    >
                        <Input type="number" placeholder="Use global" min={-1} max={1440} />
                    </Form.Item>
                    <Form.Item style={{ marginBottom: 0 }}>
                        <Space>
                            <Button type="primary" htmlType="submit" loading={submitLoading}>
                                Create
                            </Button>
                            <Button onClick={() => setCreateModalVisible(false)}>Cancel</Button>
                        </Space>
                    </Form.Item>
                </Form>
            </Modal>

            <Modal
                title="Reset password"
                open={resetModalVisible}
                onCancel={() => {
                    setResetModalVisible(false);
                    setResetUserId(null);
                }}
                footer={null}
                destroyOnClose
                width={400}
            >
                <Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
                    Enter a new password for this user. They will need to use it on next login.
                </Text>
                <Form form={resetForm} layout="vertical" onFinish={handleResetPasswordSubmit}>
                    <Form.Item
                        label="New password"
                        name="new_password"
                        rules={[
                            { required: true, message: 'Required' },
                            { min: 6, message: 'At least 6 characters' },
                        ]}
                    >
                        <Input.Password placeholder="••••••••" />
                    </Form.Item>
                    <Form.Item
                        label="Confirm password"
                        name="confirm_password"
                        dependencies={['new_password']}
                        rules={[
                            { required: true, message: 'Required' },
                            ({ getFieldValue }) => ({
                                validator(_, value) {
                                    if (!value || getFieldValue('new_password') === value) return Promise.resolve();
                                    return Promise.reject(new Error('Passwords do not match'));
                                },
                            }),
                        ]}
                    >
                        <Input.Password placeholder="••••••••" />
                    </Form.Item>
                    <Form.Item style={{ marginBottom: 0 }}>
                        <Space>
                            <Button type="primary" htmlType="submit" loading={submitLoading}>
                                Reset password
                            </Button>
                            <Button
                                onClick={() => {
                                    setResetModalVisible(false);
                                    setResetUserId(null);
                                }}
                            >
                                Cancel
                            </Button>
                        </Space>
                    </Form.Item>
                </Form>
            </Modal>

            <ErrorModal
                visible={errorModalVisible}
                onClose={() => {
                    setErrorModalVisible(false);
                    setErrorDetails(null);
                }}
                error={errorDetails}
                title="Error"
            />
        </div>
    );
};

export default OrganizationUsers;
