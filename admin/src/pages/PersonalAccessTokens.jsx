import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, InputNumber, Typography, Space, App, Alert } from 'antd';
import { PlusOutlined, DeleteOutlined, KeyOutlined } from '@ant-design/icons';
import { api } from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const { Title, Text } = Typography;

const PersonalAccessTokens = () => {
    const { message: messageApi } = App.useApp();
    const [tokens, setTokens] = useState([]);
    const [loading, setLoading] = useState(true);
    const [createModalVisible, setCreateModalVisible] = useState(false);
    const [tokenResultModalVisible, setTokenResultModalVisible] = useState(false);
    const [newTokenPlaintext, setNewTokenPlaintext] = useState(null);
    const [submitLoading, setSubmitLoading] = useState(false);
    const [errorModalVisible, setErrorModalVisible] = useState(false);
    const [errorDetails, setErrorDetails] = useState(null);
    const [form] = Form.useForm();

    const loadTokens = async () => {
        setLoading(true);
        try {
            const data = await api.listPersonalAccessTokens();
            setTokens(data.tokens || []);
        } catch (err) {
            setErrorDetails(err);
            setErrorModalVisible(true);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadTokens();
    }, []);

    const handleCreate = async (values) => {
        setSubmitLoading(true);
        try {
            const result = await api.createPersonalAccessToken({
                name: values.name?.trim() || 'Unnamed token',
                expires_days: values.expires_days ?? 90,
                company_id: values.company_id || null,
                scopes: values.scopes ? values.scopes.split(',').map(s => s.trim()).filter(Boolean) : null,
            });
            setNewTokenPlaintext(result.token);
            setTokenResultModalVisible(true);
            form.resetFields();
            setCreateModalVisible(false);
            loadTokens();
            messageApi.success('Token created. Copy it now; it will not be shown again.');
        } catch (err) {
            setErrorDetails(err);
            setErrorModalVisible(true);
        } finally {
            setSubmitLoading(false);
        }
    };

    const handleRevoke = (record) => {
        Modal.confirm({
            title: 'Revoke token',
            content: `Revoke "${record.name}"? This cannot be undone.`,
            okText: 'Revoke',
            okType: 'danger',
            cancelText: 'Cancel',
            onOk: async () => {
                try {
                    await api.revokePersonalAccessToken(record.pat_id);
                    messageApi.success('Token revoked');
                    loadTokens();
                } catch (err) {
                    setErrorDetails(err);
                    setErrorModalVisible(true);
                }
            },
        });
    };

    const copyToken = () => {
        if (newTokenPlaintext && navigator.clipboard) {
            navigator.clipboard.writeText(newTokenPlaintext);
            messageApi.success('Token copied to clipboard');
        }
    };

    const closeTokenResult = () => {
        setTokenResultModalVisible(false);
        setNewTokenPlaintext(null);
    };

    const columns = [
        { title: 'Name', dataIndex: 'name', key: 'name', ellipsis: true },
        {
            title: 'Expires',
            dataIndex: 'expires_at',
            key: 'expires_at',
            width: 180,
            render: (v) => (v ? new Date(v).toLocaleString() : '—'),
        },
        {
            title: 'Last used',
            dataIndex: 'last_used_at',
            key: 'last_used_at',
            width: 180,
            render: (v) => (v ? new Date(v).toLocaleString() : '—'),
        },
        {
            title: 'Created',
            dataIndex: 'created_at',
            key: 'created_at',
            width: 180,
            render: (v) => (v ? new Date(v).toLocaleString() : '—'),
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 100,
            render: (_, record) => (
                <Button
                    type="link"
                    danger
                    size="small"
                    icon={<DeleteOutlined />}
                    onClick={() => handleRevoke(record)}
                >
                    Revoke
                </Button>
            ),
        },
    ];

    return (
        <div style={{ padding: '16px 0' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <Title level={5} style={{ margin: 0 }}>Personal Access Tokens</Title>
                <Button
                    type="primary"
                    icon={<PlusOutlined />}
                    onClick={() => {
                        form.resetFields();
                        setCreateModalVisible(true);
                    }}
                >
                    Create token
                </Button>
            </div>

            <Table
                dataSource={tokens}
                columns={columns}
                rowKey="pat_id"
                loading={loading}
                size="small"
                pagination={{ pageSize: 20, showSizeChanger: true, showTotal: (t) => `Total ${t} tokens` }}
            />

            <Modal
                title="Create Personal Access Token"
                open={createModalVisible}
                onCancel={() => setCreateModalVisible(false)}
                footer={null}
                destroyOnClose
                width={420}
            >
                <Form
                    form={form}
                    layout="vertical"
                    onFinish={handleCreate}
                    initialValues={{ name: '', expires_days: 90 }}
                >
                    <Form.Item
                        label="Name"
                        name="name"
                        rules={[{ required: true, message: 'Required' }]}
                    >
                        <Input placeholder="e.g. Helix integration" />
                    </Form.Item>
                    <Form.Item
                        label="Expires (days)"
                        name="expires_days"
                        rules={[{ required: true }, { type: 'number', min: 1, max: 3650 }]}
                    >
                        <InputNumber min={1} max={3650} style={{ width: '100%' }} />
                    </Form.Item>
                    <Form.Item>
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
                title="Token created — copy it now"
                open={tokenResultModalVisible}
                onCancel={closeTokenResult}
                footer={
                    <Space>
                        <Button type="primary" onClick={copyToken}>Copy token</Button>
                        <Button onClick={closeTokenResult}>Done</Button>
                    </Space>
                }
                width={560}
                closable
            >
                <Alert
                    type="warning"
                    showIcon
                    icon={<KeyOutlined />}
                    message="This token is shown only once. Store it securely; you will not be able to see it again."
                    style={{ marginBottom: 16 }}
                />
                <div style={{ wordBreak: 'break-all', fontFamily: 'monospace', background: '#f5f5f5', padding: 12, borderRadius: 6 }}>
                    {newTokenPlaintext}
                </div>
            </Modal>

            <ErrorModal
                visible={errorModalVisible}
                onClose={() => setErrorModalVisible(false)}
                error={errorDetails}
            />
        </div>
    );
};

export default PersonalAccessTokens;
