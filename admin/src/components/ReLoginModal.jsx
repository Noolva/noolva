import React, { useState, useEffect } from 'react';
import { Modal, Form, Input, Button, Typography, App } from 'antd';
import { UserOutlined, LockOutlined } from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';
import { getSessionLocked, getSessionLockedRequire2FA, clearSessionLock } from '../utils/sessionLock';

const { Text } = Typography;

/**
 * Modal for:
 * 1) auth:tokenExpired - full login (identifier + password)
 * 2) auth:idleLock - re-auth (password + optional 2FA code). Lock is stored in localStorage
 *    so duplicate tabs cannot bypass; all API requests (except reauth) are blocked until unlock.
 */
const ReLoginModal = () => {
    const { message } = App.useApp();
    const { login, reauth } = useAuth();
    const [visible, setVisible] = useState(false);
    const [mode, setMode] = useState('tokenExpired'); // 'tokenExpired' | 'idleLock'
    const [require2FA, setRequire2FA] = useState(false);
    const [loading, setLoading] = useState(false);
    const [form] = Form.useForm();

    // Show modal when session is locked (e.g. on load or when another tab locked)
    const showIdleLockModal = () => {
        setMode('idleLock');
        setRequire2FA(getSessionLockedRequire2FA());
        form.resetFields();
        setVisible(true);
    };

    useEffect(() => {
        if (getSessionLocked()) showIdleLockModal();
    }, []);

    useEffect(() => {
        const handleTokenExpired = () => {
            setMode('tokenExpired');
            setRequire2FA(false);
            form.resetFields();
            setVisible(true);
        };
        const handleIdleLock = (e) => {
            setMode('idleLock');
            setRequire2FA(!!(e?.detail?.enable_2fa));
            form.resetFields();
            setVisible(true);
        };
        const handleStorage = (e) => {
            if (e.key === 'session_locked' && e.newValue === '1') showIdleLockModal();
        };
        window.addEventListener('auth:tokenExpired', handleTokenExpired);
        window.addEventListener('auth:idleLock', handleIdleLock);
        window.addEventListener('storage', handleStorage);
        return () => {
            window.removeEventListener('auth:tokenExpired', handleTokenExpired);
            window.removeEventListener('auth:idleLock', handleIdleLock);
            window.removeEventListener('storage', handleStorage);
        };
    }, [form]);

    const onFinish = async (values) => {
        setLoading(true);
        try {
            if (mode === 'idleLock') {
                const doReauth = typeof reauth === 'function' ? reauth : null;
                if (!doReauth) {
                    message.error('Re-authentication is not available. Please refresh the page and sign in again.');
                    return;
                }
                const result = await doReauth(values.password, values.totp_code?.trim() || null);
                if (result.success) {
                    clearSessionLock();
                    form.resetFields();
                    setVisible(false);
                } else {
                    message.error(result.error?.message || result.error?.errorData?.description || 'Re-authentication failed');
                }
            } else {
                const result = await login(values.identifier, values.password, values.company_id || null);
                if (result.success) {
                    form.resetFields();
                    setVisible(false);
                    message.success('Signed in again. You can continue.');
                } else {
                    const msg = result.error?.errorData?.description || result.error?.message || 'Login failed. Please try again.';
                    message.error(msg);
                }
            }
        } finally {
            setLoading(false);
        }
    };

    const onCancel = () => {
        if (mode === 'idleLock') return; // Session locked: do not allow closing without re-auth
        form.resetFields();
        setVisible(false);
    };

    const isIdleLock = mode === 'idleLock';

    return (
        <Modal
            title={isIdleLock ? 'Session locked' : 'Session expired'}
            open={visible}
            onCancel={onCancel}
            footer={null}
            closable={!isIdleLock}
            maskClosable={!isIdleLock}
            destroyOnHidden
            width={400}
        >
            <Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
                {isIdleLock
                    ? 'You were idle for a while. Enter your password to continue (and 2FA code if enabled).'
                    : 'Your session has expired. Please sign in again to continue.'}
            </Text>
            <Form
                form={form}
                layout="vertical"
                onFinish={onFinish}
                autoComplete="off"
            >
                {!isIdleLock && (
                    <Form.Item
                        label="Username, Email, or Phone"
                        name="identifier"
                        rules={[{ required: true, message: 'Please enter your username, email, or phone' }]}
                    >
                        <Input prefix={<UserOutlined />} placeholder="username, email, or phone" />
                    </Form.Item>
                )}
                <Form.Item
                    label="Password"
                    name="password"
                    rules={[{ required: true, message: 'Please enter your password' }]}
                >
                    <Input.Password prefix={<LockOutlined />} placeholder="••••••••" />
                </Form.Item>
                {isIdleLock && require2FA && (
                    <Form.Item
                        label="Two-factor code"
                        name="totp_code"
                        rules={[{ required: true, message: 'Please enter the 6-digit code from your authenticator app' }, { len: 6, message: 'Code must be 6 digits' }]}
                    >
                        <Input placeholder="000000" maxLength={6} />
                    </Form.Item>
                )}
                {!isIdleLock && (
                    <Form.Item name="company_id" hidden>
                        <Input type="hidden" />
                    </Form.Item>
                )}
                <Form.Item style={{ marginBottom: 0 }}>
                    <Button type="primary" htmlType="submit" block loading={loading}>
                        {isIdleLock ? 'Unlock' : 'Sign in again'}
                    </Button>
                </Form.Item>
            </Form>
        </Modal>
    );
};

export default ReLoginModal;
