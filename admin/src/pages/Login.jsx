import React, { useState, useEffect } from 'react';
import {
    Card,
    Form,
    Input,
    Button,
    Avatar,
    Typography,
    Divider,
    Spin,
    App,
    message,
} from 'antd';
import {
    GoogleOutlined,
    DeleteOutlined,
    UserOutlined,
} from '@ant-design/icons';
import '@fortawesome/fontawesome-free/css/all.min.css';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import * as apiUtils from '../utils/api';
import ErrorModal from '../components/ErrorModal';
import '../index.css';

const { Text, Title } = Typography;

const Login = () => {
    const { message } = App.useApp();
    const navigate = useNavigate();
    const { login, loginWithGoogle, accounts, removeAccount, switchAccount, loading: authLoading, initialized } = useAuth();

    // Toggle between account list & add-account form
    const [showForm, setShowForm] = useState(false);

    // Form loading state
    const [loading, setLoading] = useState(false);
    const [form] = Form.useForm();

    // Error modal state
    const [errorModalVisible, setErrorModalVisible] = useState(false);
    const [errorDetails, setErrorDetails] = useState(null);

    // Show form if no accounts, otherwise show account list
    useEffect(() => {
        if (initialized && accounts.length === 0) {
            setShowForm(true);
        }
    }, [initialized, accounts.length]);

    // Handle selecting an existing account
    const handleAccountLogin = async (account) => {
        setLoading(true);
        try {
            // If account has a stored token, try to use it first
            if (account.accessToken) {
                // Set the token and try to get user context
                apiUtils.setAccessToken(account.accessToken);
                
                try {
                    const context = await apiUtils.api.getUserContext();
                    
                    // Token is valid, switch to this account
                    const result = await switchAccount(account);
                    
                    if (result.success) {
                        navigate('/');
                        return;
                    }
                } catch (tokenError) {
                    // Token is invalid or expired, clear it and prompt for password
                    console.log('Token validation failed, prompting for password');
                    // Clear invalid token
                    const storedAccounts = apiUtils.getStoredAccounts();
                    const updatedAccounts = storedAccounts.map(acc => 
                        acc.id === account.id ? { ...acc, accessToken: null } : acc
                    );
                    apiUtils.setStoredAccounts(updatedAccounts);
                }
            }
            
            // If no token or token invalid, prompt for password
            message.info('Please enter your password to continue');
            setShowForm(true);
            form.setFieldsValue({ 
                identifier: account.username,
                company_id: account.companyId || null
            });
        } catch (error) {
            // Show error modal instead of simple message
            setErrorDetails(error);
            setErrorModalVisible(true);
            setShowForm(true);
            form.setFieldsValue({ 
                identifier: account.username,
                company_id: account.companyId || null
            });
        } finally {
            setLoading(false);
        }
    };

    // Handle new account submission
    const onFinish = async (values) => {
        setLoading(true);
        try {
            const result = await login(values.identifier, values.password, values.company_id || null);

            if (result.success) {
                navigate('/');
            } else {
                // Show error modal for failed login
                console.log('Login failed, error details:', {
                    error: result.error,
                    hasErrorData: !!result.error?.errorData,
                    errorData: result.error?.errorData,
                    hasResponse: !!result.error?.response,
                    responseData: result.error?.response?.data,
                    message: result.error?.message,
                    isApiError: result.error?.isApiError,
                    isNetworkError: result.error?.isNetworkError
                });
                
                // Ensure we have a valid error object
                const errorToShow = result.error || { 
                    message: 'Login failed. Please check your credentials.',
                    errorData: { description: 'Login failed. Please check your credentials.' }
                };
                
                setErrorDetails(errorToShow);
                setErrorModalVisible(true);
            }
        } catch (error) {
            console.error('Login error in onFinish:', error);
            // Show error modal with error details
            setErrorDetails(error);
            setErrorModalVisible(true);
        } finally {
            setLoading(false);
        }
    };

    // Handle Google login
    const handleGoogleLogin = () => {
        loginWithGoogle();
    };

    // Remove an account
    const handleRemoveAccount = async (account, e) => {
        e.stopPropagation();
        await removeAccount(account.id);
    };

    // Show loading spinner while initializing
    if (!initialized) {
        return (
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
                <Spin size="large" />
            </div>
        );
    }

    return (
        <div className="login-container">
            {/* Left Panel */}
            <div className="login-left">
                <div className="login-left-overlay" />
                <div className="login-left-content">
                    {/* Brand Logo */}
                    <div
                        style={{
                            width: '200px',
                            height: '50px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            backgroundColor: 'rgba(255, 255, 255, 0.1)',
                            borderRadius: '4px',
                            fontSize: '24px',
                            fontWeight: 'bold',
                            color: 'white',
                            marginBottom: '20px'
                        }}
                        className="login-brand"
                    >
                        Noolva
                    </div>

                    <Title level={2} style={{ color: 'white', marginBottom: '16px' }}>
                        Welcome Back
                    </Title>
                    <ul className="login-features">
                        <li>Secure Multi-Account Support</li>
                        <li>Real-time Analytics</li>
                        <li>Easy User Management</li>
                        <li>24/7 Customer Support</li>
                    </ul>
                </div>
            </div>

            {/* Right Panel */}
            <div className="login-right">
                <Card className="login-card">
                    {showForm ? (
                        <>
                            <Title className="login-card-title">Sign In</Title>
                            <Form
                                form={form}
                                name="login_form"
                                onFinish={onFinish}
                                layout="vertical"
                                className="login-form"
                                autoComplete="off"
                            >
                                <Form.Item
                                    label="Username, Email, or Phone"
                                    name="identifier"
                                    rules={[
                                        {
                                            required: true,
                                            message: 'Please enter your username, email, or phone number',
                                        },
                                    ]}
                                >
                                    <Input
                                        placeholder="username, email@example.com, or phone"
                                        prefix={<UserOutlined />}
                                    />
                                </Form.Item>

                                <Form.Item
                                    label="Password"
                                    name="password"
                                    rules={[
                                        { required: true, message: 'Please enter your password' },
                                    ]}
                                >
                                    <Input.Password placeholder="••••••••" />
                                </Form.Item>

                                <Form.Item name="company_id" style={{ display: 'none' }}>
                                    <Input type="hidden" />
                                </Form.Item>

                                <Form.Item>
                                    <Button
                                        type="primary"
                                        htmlType="submit"
                                        block
                                        loading={loading}
                                    >
                                        Sign In
                                    </Button>
                                </Form.Item>

                                <Divider>Or continue with</Divider>

                                <Button
                                    icon={<GoogleOutlined />}
                                    className="social-btn"
                                    onClick={handleGoogleLogin}
                                    block
                                    loading={loading}
                                >
                                    Sign in with Google
                                </Button>

                                {accounts.length > 0 && (
                                    <>
                                        <Divider />
                                        <Text
                                            className="login-back-link"
                                            onClick={() => setShowForm(false)}
                                            style={{ cursor: 'pointer', display: 'block', textAlign: 'center' }}
                                        >
                                            ← Back to my accounts
                                        </Text>
                                    </>
                                )}
                            </Form>
                        </>
                    ) : (
                        <>
                            <Title className="login-card-title">Select an Account</Title>
                            <div className="account-list">
                                {accounts.length > 0 ? (
                                    accounts.map((acct) => (
                                        <div
                                            key={acct.id}
                                            className="account-item"
                                            onClick={() => handleAccountLogin(acct)}
                                            style={{ cursor: 'pointer' }}
                                        >
                                            <div className="account-info">
                                                <Avatar className="account-avatar">
                                                    {acct.username.charAt(0).toUpperCase()}
                                                </Avatar>
                                                <div style={{ display: 'flex', flexDirection: 'column', marginLeft: '12px' }}>
                                                    <Text strong>{acct.username}</Text>
                                                    {acct.companyName && (
                                                        <Text type="secondary" style={{ fontSize: '12px' }}>
                                                            {acct.companyName}
                                                        </Text>
                                                    )}
                                                </div>
                                            </div>
                                            <Button
                                                type="text"
                                                icon={<DeleteOutlined />}
                                                onClick={(e) => handleRemoveAccount(acct, e)}
                                                danger
                                            />
                                        </div>
                                    ))
                                ) : (
                                    <Text>No saved accounts</Text>
                                )}
                            </div>

                            <Divider />
                            <Button
                                type="dashed"
                                block
                                onClick={() => setShowForm(true)}
                                loading={loading}
                            >
                                + Add Account
                            </Button>
                        </>
                    )}
                </Card>
            </div>

            {/* Error Modal */}
            <ErrorModal
                visible={errorModalVisible}
                onClose={() => {
                    setErrorModalVisible(false);
                    setErrorDetails(null);
                }}
                error={errorDetails}
                title="Something went wrong"
                showDetails={false}
            />
        </div>
    );
};

export default Login;
