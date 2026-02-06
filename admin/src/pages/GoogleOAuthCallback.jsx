import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Spin, message } from 'antd';
import * as apiUtils from '../utils/api';
import ErrorModal from '../components/ErrorModal';

const GoogleOAuthCallback = () => {
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();
    const [error, setError] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const handleCallback = async () => {
            try {
                // Extract parameters from URL
                const accessToken = searchParams.get('access_token');
                const userId = searchParams.get('user_id');
                const username = searchParams.get('username');
                const userType = searchParams.get('user_type');
                const isSuperAdmin = searchParams.get('is_super_admin') === 'true';
                const companyId = searchParams.get('company_id');
                const sessionId = searchParams.get('session_id');
                const sessionUuid = searchParams.get('session_uuid');

                // Check for error in URL
                const errorParam = searchParams.get('error');
                if (errorParam) {
                    setError({
                        message: decodeURIComponent(errorParam),
                        errorData: { description: decodeURIComponent(errorParam) }
                    });
                    setLoading(false);
                    return;
                }

                // Validate required parameters
                if (!accessToken || !userId || !username) {
                    throw new Error('Missing required authentication parameters');
                }

                // Store the access token
                apiUtils.setAccessToken(accessToken);

                // Create user object from URL params
                const userData = {
                    user_id: parseInt(userId),
                    username: username,
                    user_type: userType,
                    is_super_admin: isSuperAdmin,
                    company_id: companyId ? parseInt(companyId) : null,
                };

                // Get full user context from API
                let context;
                try {
                    context = await apiUtils.api.getUserContext();
                } catch (contextError) {
                    console.warn('Failed to get user context, using basic info:', contextError);
                    context = {
                        user: userData,
                        company: null,
                    };
                }

                // Create account object
                const accountData = {
                    id: Date.now(),
                    userId: userData.user_id,
                    username: userData.username,
                    companyId: userData.company_id || (companyId ? parseInt(companyId) : null),
                    companyName: context.company?.company_name || null,
                    accessToken: accessToken,
                    sessionId: sessionId ? parseInt(sessionId) : null,
                    lastLogin: new Date().toISOString(),
                };

                // Add or update account in stored accounts
                const storedAccounts = apiUtils.getStoredAccounts();
                const existingAccountIndex = storedAccounts.findIndex(
                    acc => acc.userId === accountData.userId && acc.companyId === accountData.companyId
                );

                let updatedAccounts;
                if (existingAccountIndex >= 0) {
                    updatedAccounts = [...storedAccounts];
                    updatedAccounts[existingAccountIndex] = accountData;
                } else {
                    updatedAccounts = [...storedAccounts, accountData];
                }

                apiUtils.setStoredAccounts(updatedAccounts);
                apiUtils.setCurrentAccountId(accountData.id);

                // Clear any session lock
                apiUtils.clearSessionLock();

                // Reload the page to trigger AuthContext re-initialization with new token
                // This ensures all auth state is properly set
                window.location.href = '/';
            } catch (err) {
                console.error('Google OAuth callback error:', err);
                setError({
                    message: err.message || 'Failed to complete Google login',
                    errorData: { description: err.message || 'Failed to complete Google login' }
                });
                setLoading(false);
            }
        };

        handleCallback();
    }, [searchParams, navigate]);

    if (loading) {
        return (
            <div style={{ 
                display: 'flex', 
                justifyContent: 'center', 
                alignItems: 'center', 
                height: '100vh',
                flexDirection: 'column',
                gap: '16px'
            }}>
                <Spin size="large" />
                <div>Completing Google login...</div>
            </div>
        );
    }

    if (error) {
        return (
            <>
                <div style={{ 
                    display: 'flex', 
                    justifyContent: 'center', 
                    alignItems: 'center', 
                    height: '100vh',
                    flexDirection: 'column',
                    gap: '16px'
                }}>
                    <div>Login failed. Redirecting to login page...</div>
                </div>
                <ErrorModal
                    visible={true}
                    onClose={() => {
                        setError(null);
                        navigate('/login', { replace: true });
                    }}
                    error={error}
                    title="Google Login Failed"
                    showDetails={false}
                />
            </>
        );
    }

    return null;
};

export default GoogleOAuthCallback;
