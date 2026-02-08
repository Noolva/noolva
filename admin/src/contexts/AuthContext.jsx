import React, { createContext, useState, useContext, useEffect, useCallback } from 'react';
import { App } from 'antd';
import { api, setAccessToken, getAccessToken, getStoredAccounts, setStoredAccounts, getCurrentAccountId, setCurrentAccountId, clearSessionLock, getSessionLockedRequire2FA, getAccountIdFromUrl, updateUrlWithAccount } from '../utils/api';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
    const { message } = App.useApp();
    const [user, setUser] = useState(null);
    const [accounts, setAccounts] = useState([]);
    const [currentAccount, setCurrentAccount] = useState(null);
    const [loading, setLoading] = useState(true);
    const [initialized, setInitialized] = useState(false);

    // Initialize auth state from URL/sessionStorage/localStorage
    useEffect(() => {
        const initAuth = async () => {
            try {
                const storedAccounts = getStoredAccounts();
                const token = getAccessToken();

                if (token && storedAccounts.length > 0) {
                    // Try to validate token by fetching user context
                    try {
                        const context = await api.getUserContext();
                        setUser(context.user);
                        setAccounts(storedAccounts);

                        // Get account ID from URL (highest priority), then sessionStorage/localStorage
                        let currentAccountId = getCurrentAccountId();

                        // If URL has account param, use it; otherwise use stored value
                        const accountFromUrl = getAccountIdFromUrl();
                        if (accountFromUrl) {
                            currentAccountId = accountFromUrl;
                            // Sync to sessionStorage
                            if (typeof sessionStorage !== 'undefined') {
                                sessionStorage.setItem('current_account_id', currentAccountId);
                            }
                        }

                        // Find account by ID, or default to first account
                        let account = null;
                        if (currentAccountId) {
                            account = storedAccounts.find(acc => acc.id === parseInt(currentAccountId));
                        }

                        // If account not found or no account ID, use first account
                        if (!account && storedAccounts.length > 0) {
                            account = storedAccounts[0];
                            currentAccountId = account.id.toString();
                            // Update URL and storage with default account
                            setCurrentAccountId(account.id);
                        }

                        setCurrentAccount(account || null);
                    } catch (error) {
                        // Session locked: keep token so reauth can use it; show app with unlock modal
                        if (error.isSessionLocked) {
                            setUser({
                                user_id: 0,
                                username: 'User',
                                enable_2fa: getSessionLockedRequire2FA(),
                            });
                            setAccounts(storedAccounts);

                            // Try to get account from URL/storage
                            let currentAccountId = getCurrentAccountId();
                            const accountFromUrl = getAccountIdFromUrl();
                            if (accountFromUrl) {
                                currentAccountId = accountFromUrl;
                            }

                            const account = currentAccountId
                                ? storedAccounts.find(acc => acc.id === parseInt(currentAccountId))
                                : (storedAccounts[0] || null);

                            setCurrentAccount(account);
                            return;
                        }
                        // Token invalid or other error, clear storage
                        setAccessToken(null);
                        setStoredAccounts([]);
                        setCurrentAccountId(null);
                    }
                }
            } catch (error) {
                console.error('Auth initialization error:', error);
            } finally {
                setLoading(false);
                setInitialized(true);
            }
        };

        initAuth();
    }, []);

    /**
     * Login with username/email/phone and password
     */
    const login = async (identifier, password, companyId = null) => {
        try {
            const response = await api.login(identifier, password, companyId);

            // New login clears any previous session lock
            clearSessionLock();

            // If 2FA required, return so the Login page can show TOTP step
            if (response.requires_totp && response.temp_token) {
                return {
                    success: false,
                    requiresTotp: true,
                    tempToken: response.temp_token,
                    user: response.user,
                };
            }

            // Store token first
            setAccessToken(response.access_token);

            // Update user state with basic info
            setUser(response.user);

            // Get user context to get full account info (with token now set)
            let context;
            try {
                context = await api.getUserContext();
            } catch (contextError) {
                console.warn('Failed to get user context, using basic info:', contextError);
                // If context fetch fails, use basic response data
                context = {
                    user: response.user,
                    company: null,
                };
            }

            // Create account object
            const accountData = {
                id: Date.now(),
                userId: response.user.user_id,
                username: response.user.username,
                companyId: response.user.company_id || companyId,
                companyName: context.company?.company_name || null,
                accessToken: response.access_token,
                sessionId: response.session_id,
                lastLogin: new Date().toISOString(),
            };

            // Add or update account in stored accounts
            const storedAccounts = getStoredAccounts();
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

            setStoredAccounts(updatedAccounts);
            setCurrentAccountId(accountData.id);
            setAccounts(updatedAccounts);
            setCurrentAccount(accountData);

            message.success('Login successful');
            return { success: true };
        } catch (error) {
            // Log error for debugging
            console.error('Login error in AuthContext:', {
                hasResponse: !!error.response,
                status: error.response?.status,
                data: error.response?.data,
                message: error.message,
                errorData: error.errorData,
                isApiError: error.isApiError,
                isNetworkError: error.isNetworkError
            });

            // Return the full error object so the UI can extract proper error messages
            // Ensure error structure is preserved - especially errorData from axios interceptor
            const errorToReturn = {
                ...error,
                response: error.response,
                // Prioritize errorData from axios interceptor, fallback to response.data
                errorData: error.errorData || error.response?.data,
                message: error.message,
                isApiError: error.isApiError,
                isNetworkError: error.isNetworkError
            };

            console.log('Returning error to UI:', errorToReturn);

            return {
                success: false,
                error: errorToReturn
            };
        }
    };

    /**
     * Complete login with 2FA code (after login returned requiresTotp).
     */
    const loginVerifyTotp = async (tempToken, totpCode) => {
        try {
            const response = await api.loginVerifyTotp(tempToken, totpCode);
            setAccessToken(response.access_token);
            setUser(response.user);

            let context;
            try {
                context = await api.getUserContext();
            } catch (e) {
                context = { user: response.user, company: null };
            }

            const accountData = {
                id: Date.now(),
                userId: response.user.user_id,
                username: response.user.username,
                companyId: response.user.company_id,
                companyName: context.company?.company_name || null,
                accessToken: response.access_token,
                sessionId: response.session_id,
                lastLogin: new Date().toISOString(),
            };

            const storedAccounts = getStoredAccounts();
            const existingAccountIndex = storedAccounts.findIndex(
                acc => acc.userId === accountData.userId && acc.companyId === accountData.companyId
            );
            const updatedAccounts = existingAccountIndex >= 0
                ? storedAccounts.map((acc, i) => (i === existingAccountIndex ? accountData : acc))
                : [...storedAccounts, accountData];

            setStoredAccounts(updatedAccounts);
            setCurrentAccountId(accountData.id);
            setAccounts(updatedAccounts);
            setCurrentAccount(accountData);

            message.success('Login successful');
            return { success: true };
        } catch (error) {
            const msg = error?.response?.data?.description ?? error?.response?.data?.detail ?? error?.message ?? 'Verification failed';
            return { success: false, error: { ...error, message: msg, errorData: { description: msg } } };
        }
    };

    /**
     * Login with Google OAuth
     */
    const loginWithGoogle = () => {
        api.googleLogin();
    };

    /**
     * Switch to a different account
     */
    const switchAccount = async (account) => {
        try {
            // If account has a valid token, try to use it first
            if (account.accessToken) {
                setAccessToken(account.accessToken);
                try {
                    const context = await api.getUserContext();
                    // Token is valid, just switch the account
                    const updatedAccount = {
                        ...account,
                        companyName: context.company?.company_name || account.companyName,
                        lastLogin: new Date().toISOString(),
                    };

                    const storedAccounts = getStoredAccounts();
                    const updatedAccounts = storedAccounts.map(acc =>
                        acc.id === account.id ? updatedAccount : acc
                    );
                    setStoredAccounts(updatedAccounts);
                    setCurrentAccountId(account.id); // This now updates URL and sessionStorage

                    setUser(context.user);
                    setAccounts(updatedAccounts);
                    setCurrentAccount(updatedAccount);

                    message.success('Account switched successfully');
                    return { success: true };
                } catch (tokenError) {
                    // Token invalid, need to switch via API
                    console.log('Token invalid, switching via API');
                }
            }

            // Switch via API (creates new token)
            const response = await api.switchAccount(account.companyId);

            // Update token
            setAccessToken(response.access_token);

            // Update account info
            const updatedAccount = {
                ...account,
                accessToken: response.access_token,
                companyName: response.company?.company_name || account.companyName,
                lastLogin: new Date().toISOString(),
            };

            // Update stored accounts
            const storedAccounts = getStoredAccounts();
            const updatedAccounts = storedAccounts.map(acc =>
                acc.id === account.id ? updatedAccount : acc
            );
            setStoredAccounts(updatedAccounts);
            setCurrentAccountId(account.id); // This now updates URL and sessionStorage

            setUser(response.user);
            setAccounts(updatedAccounts);
            setCurrentAccount(updatedAccount);

            message.success('Account switched successfully');
            return { success: true };
        } catch (error) {
            message.error(error.message || 'Failed to switch account');
            return { success: false, error: error.message };
        }
    };

    /**
     * Remove an account from stored accounts
     */
    const removeAccount = async (accountId) => {
        try {
            const account = accounts.find(acc => acc.id === accountId);
            if (account?.profileId) {
                await api.deleteAccountProfile(account.profileId);
            }

            const updatedAccounts = accounts.filter(acc => acc.id !== accountId);
            setStoredAccounts(updatedAccounts);
            setAccounts(updatedAccounts);

            // If removed account was current, switch to first available
            if (currentAccount?.id === accountId) {
                if (updatedAccounts.length > 0) {
                    await switchAccount(updatedAccounts[0]);
                } else {
                    await logout();
                }
            }

            message.success('Account removed');
        } catch (error) {
            message.error(error.message || 'Failed to remove account');
        }
    };

    /**
     * Refresh current user from server (e.g. after updating profile/settings like idle timeout).
     */
    const refreshUser = async () => {
        try {
            const context = await api.getUserContext();
            setUser(context.user);
        } catch (e) {
            console.warn('refreshUser failed', e);
        }
    };

    /**
     * Re-authenticate after idle lock (password + optional 2FA code). Updates token and user.
     */
    const reauth = useCallback(async (password, totpCode = null) => {
        try {
            const result = await api.reauth(password, totpCode);
            setAccessToken(result.access_token);
            setUser(result.user);
            try {
                const context = await api.getUserContext();
                setUser(context.user);
            } catch (e) {
                // Keep result.user if context fails
            }
            message.success('Welcome back. You can continue.');
            return { success: true };
        } catch (error) {
            const msg = error?.response?.data?.description ?? error?.response?.data?.detail ?? error?.message ?? 'Re-authentication failed';
            return { success: false, error: { ...error, message: msg, errorData: { description: msg } } };
        }
    }, [message]);

    /**
     * Logout
     */
    const logout = async () => {
        try {
            await api.logout();
        } catch (error) {
            console.error('Logout error:', error);
        }
        clearSessionLock();
        setUser(null);
        setAccounts([]);
        setCurrentAccount(null);
        message.success('Logged out successfully');
    };

    const value = {
        user,
        accounts,
        currentAccount,
        loading,
        initialized,
        login,
        loginVerifyTotp,
        loginWithGoogle,
        switchAccount,
        removeAccount,
        reauth,
        refreshUser,
        logout,
    };

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
