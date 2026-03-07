import React, { useState, useEffect } from 'react';
import { Modal, Form, Input, Button, Typography, App } from 'antd';
import { UserOutlined, LockOutlined } from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';
import { getSessionLocked, getSessionLockedRequire2FA, clearSessionLock } from '../utils/sessionLock';

const { Text } = Typography;

/** Coerce error payload to a string so message.error() never receives an object (avoids React "Objects are not valid as a React child"). */
const toErrorString = (err, fallback = 'Something went wrong') => {
    if (err == null) return fallback;
    if (typeof err === 'string') return err || fallback;
    const d = err?.errorData?.description ?? err?.message ?? err?.msg;
    if (typeof d === 'string') return d || fallback;
    if (Array.isArray(d) && d[0]?.msg) return d.map((e) => e?.msg).filter(Boolean).join('. ') || fallback;
    return fallback;
};

/**
 * Modal for:
 * 1) auth:tokenExpired - full login (identifier + password)
 * 2) auth:idleLock - re-auth (password + optional 2FA code). Lock is stored in localStorage
 *    so duplicate tabs cannot bypass; all API requests (except reauth) are blocked until unlock.
 */
const ReLoginModal = () => {
    const { message } = App.useApp();
    const { login, loginVerifyTotp, reauth } = useAuth();
    const [visible, setVisible] = useState(false);
    const [mode, setMode] = useState('tokenExpired'); // 'tokenExpired' | 'idleLock'
    const [require2FA, setRequire2FA] = useState(false);
    /** When session expired and backend requires TOTP, we show TOTP step in modal */
    const [totpStep, setTotpStep] = useState({ active: false, tempToken: null });
    const [loading, setLoading] = useState(false);
    const [form] = Form.useForm();

    // Show modal when session is locked (e.g. on load or when another tab locked)
    const showIdleLockModal = () => {
        setMode('idleLock');
        setRequire2FA(getSessionLockedRequire2FA());
        setTotpStep({ active: false, tempToken: null });
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
            setTotpStep({ active: false, tempToken: null });
            form.resetFields();
            setVisible(true);
        };
        const handleIdleLock = (e) => {
            setMode('idleLock');
            setRequire2FA(!!(e?.detail?.enable_2fa));
            setTotpStep({ active: false, tempToken: null });
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
                    message.error(toErrorString(result.error, 'Re-authentication failed'));
                }
            } else {
                // Session expired: handle TOTP step when backend required 2FA after password
                if (totpStep.active && totpStep.tempToken) {
                    const doVerifyTotp = typeof loginVerifyTotp === 'function' ? loginVerifyTotp : null;
                    if (!doVerifyTotp) {
                        message.error('2FA verification is not available. Please refresh and sign in on the login page.');
                        return;
                    }
                    const result = await doVerifyTotp(totpStep.tempToken, values.totp_code?.trim() || '');
                    if (result.success) {
                        setTotpStep({ active: false, tempToken: null });
                        form.resetFields();
                        setVisible(false);
                        message.success('Signed in again. You can continue.');
                    } else {
                        message.error(toErrorString(result.error, 'Invalid or expired code.'));
                    }
                    return;
                }
                const result = await login(values.identifier, values.password, values.company_id || null);
                if (result.success) {
                    form.resetFields();
                    setVisible(false);
                    message.success('Signed in again. You can continue.');
                } else if (result.requiresTotp && result.tempToken) {
                    setTotpStep({ active: true, tempToken: result.tempToken });
                    form.setFieldsValue({ password: '', totp_code: '' });
                } else {
                    message.error(toErrorString(result.error, 'Login failed. Please try again.'));
                }
            }
        } finally {
            setLoading(false);
        }
    };

    const onCancel = () => {
        if (mode === 'idleLock') return; // Session locked: do not allow closing without re-auth
        setTotpStep({ active: false, tempToken: null });
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
                {!isIdleLock && !totpStep.active && (
                    <Form.Item
                        label="Username, Email, or Phone"
                        name="identifier"
                        rules={[{ required: true, message: 'Please enter your username, email, or phone' }]}
                    >
                        <Input prefix={<UserOutlined />} placeholder="username, email, or phone" />
                    </Form.Item>
                )}
                {(isIdleLock || (!isIdleLock && !totpStep.active)) && (
                    <Form.Item
                        label="Password"
                        name="password"
                        rules={[{ required: true, message: 'Please enter your password' }]}
                    >
                        <Input.Password prefix={<LockOutlined />} placeholder="••••••••" />
                    </Form.Item>
                )}
                {isIdleLock && require2FA && (
                    <Form.Item
                        label="Two-factor code"
                        name="totp_code"
                        rules={[{ required: true, message: 'Please enter the 6-digit code from your authenticator app' }, { len: 6, message: 'Code must be 6 digits' }]}
                    >
                        <Input placeholder="000000" maxLength={6} />
                    </Form.Item>
                )}
                {!isIdleLock && totpStep.active && (
                    <>
                        <Form.Item
                            label="Two-factor code"
                            name="totp_code"
                            rules={[{ required: true, message: 'Please enter the 6-digit code from your authenticator app' }, { len: 6, message: 'Code must be 6 digits' }]}
                        >
                            <Input placeholder="000000" maxLength={6} />
                        </Form.Item>
                        <Text type="secondary" style={{ display: 'block', marginBottom: 12, fontSize: 12 }}>
                            <a onClick={() => { setTotpStep({ active: false, tempToken: null }); form.setFieldsValue({ totp_code: '' }); }}>← Back to password</a>
                        </Text>
                    </>
                )}
                {!isIdleLock && !totpStep.active && (
                    <Form.Item name="company_id" hidden>
                        <Input type="hidden" />
                    </Form.Item>
                )}
                <Form.Item style={{ marginBottom: 0 }}>
                    <Button type="primary" htmlType="submit" block loading={loading}>
                        {isIdleLock ? 'Unlock' : totpStep.active ? 'Verify' : 'Sign in again'}
                    </Button>
                </Form.Item>
            </Form>
        </Modal>
    );
};

export default ReLoginModal;
