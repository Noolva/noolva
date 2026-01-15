import React, { createContext, useState, useContext, useEffect } from 'react';
import { App } from 'antd';
import { api, setAccessToken, getAccessToken, getStoredAccounts, setStoredAccounts, getCurrentAccountId, setCurrentAccountId } from '../utils/api';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
    const { message } = App.useApp();
    const [user, setUser] = useState(null);
    const [accounts, setAccounts] = useState([]);
    const [currentAccount, setCurrentAccount] = useState(null);
    const [loading, setLoading] = useState(true);
    const [initialized, setInitialized] = useState(false);

    // Initialize auth state from localStorage
    useEffect(() => {
        const initAuth = async () => {
            try {
                const storedAccounts = getStoredAccounts();
                const currentAccountId = getCurrentAccountId();
                const token = getAccessToken();

                if (token && storedAccounts.length > 0) {
                    // Try to validate token by fetching user context
                    try {
                        const context = await api.getUserContext();
                        setUser(context.user);
                        setAccounts(storedAccounts);

                        const account = storedAccounts.find(acc =>
                            acc.userId === context.user.user_id &&
                            (currentAccountId ? acc.id === parseInt(currentAccountId) : true)
                        );
                        setCurrentAccount(account || storedAccounts[0]);
                    } catch (error) {
                        // Token is invalid, clear storage
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
                    setCurrentAccountId(account.id);

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
            setCurrentAccountId(account.id);

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
     * Logout
     */
    const logout = async () => {
        try {
            await api.logout();
        } catch (error) {
            console.error('Logout error:', error);
        }
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
        loginWithGoogle,
        switchAccount,
        removeAccount,
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
