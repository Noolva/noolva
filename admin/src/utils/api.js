/**
 * API Service
 * Handles all API calls to the backend using Axios
 */

import axios from 'axios';

// API Base URL - Set VITE_API_URL in .env file or use default localhost:9001
// For proxy (recommended in dev): Set VITE_API_URL='' in .env
// For direct connection: Set VITE_API_URL='http://localhost:9001' in .env or leave unset
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:9001';

/**
 * Simple encryption/decryption for tokens in localStorage
 * Note: This is basic obfuscation, not true encryption. In production, consider using a proper library.
 */
const encrypt = (text) => {
    // Simple base64 encoding (not secure, but obfuscates)
    return btoa(unescape(encodeURIComponent(text)));
};

const decrypt = (encodedText) => {
    try {
        return decodeURIComponent(escape(atob(encodedText)));
    } catch (e) {
        return null;
    }
};

/**
 * Get stored access token
 */
export const getAccessToken = () => {
    const encryptedToken = localStorage.getItem('access_token_encrypted');
    if (encryptedToken) {
        return decrypt(encryptedToken);
    }
    return null;
};

/**
 * Store access token
 */
export const setAccessToken = (token) => {
    if (token) {
        localStorage.setItem('access_token_encrypted', encrypt(token));
    } else {
        localStorage.removeItem('access_token_encrypted');
    }
};

/**
 * Get stored accounts
 */
export const getStoredAccounts = () => {
    const accountsJson = localStorage.getItem('accounts');
    if (accountsJson) {
        try {
            return JSON.parse(accountsJson);
        } catch (e) {
            return [];
        }
    }
    return [];
};

/**
 * Store accounts
 */
export const setStoredAccounts = (accounts) => {
    localStorage.setItem('accounts', JSON.stringify(accounts));
};

/**
 * Get current account ID
 */
export const getCurrentAccountId = () => {
    return localStorage.getItem('current_account_id');
};

/**
 * Set current account ID
 */
export const setCurrentAccountId = (accountId) => {
    if (accountId) {
        localStorage.setItem('current_account_id', accountId.toString());
    } else {
        localStorage.removeItem('current_account_id');
    }
};

/**
 * Create axios instance with default config
 * Note: When API_BASE_URL is empty, axios uses relative URLs which work with Vite proxy
 * When API_BASE_URL is set, axios connects directly to that URL
 */
const axiosInstance = axios.create({
    baseURL: API_BASE_URL || undefined, // undefined means relative URLs (uses proxy)
    headers: {
        'Content-Type': 'application/json',
    },
    timeout: 30000, // 30 seconds timeout
});

// Request interceptor to add auth token
axiosInstance.interceptors.request.use(
    (config) => {
        const token = getAccessToken();
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        console.log(`API Request: ${config.method?.toUpperCase()} ${config.baseURL || ''}${config.url}`, config);
        return config;
    },
    (error) => {
        console.error('API Request Error:', error);
        return Promise.reject(error);
    }
);

// Response interceptor for error handling
axiosInstance.interceptors.response.use(
    (response) => {
        console.log('API Response:', response.config.url, response.data);
        return response;
    },
    (error) => {
        // Log the full error for debugging
        console.error('API Error Full:', {
            hasResponse: !!error.response,
            status: error.response?.status,
            data: error.response?.data,
            message: error.message,
            request: error.request ? 'Present' : 'Missing'
        });

        if (error.response) {
            // Server responded with error status (4xx, 5xx) - THIS IS NOT A NETWORK ERROR
            const errorData = error.response.data;

            // Debug: Log the raw response data to see what we're getting
            console.log('Raw error.response.data:', errorData);
            console.log('Error data type:', typeof errorData);
            console.log('Error data keys:', errorData ? Object.keys(errorData) : 'null');

            // Extract error message from structured error response
            if (errorData?.description) {
                // Our structured ERPError format - this is the main case
                error.message = errorData.description;
                // Attach full error data for ErrorModal
                error.errorData = errorData;
                error.isApiError = true; // Mark as API error, not network error
            } else if (errorData?.message) {
                error.message = errorData.message;
                error.errorData = errorData;
                error.isApiError = true;
            } else if (errorData?.detail) {
                error.message = errorData.detail;
                error.errorData = errorData;
                error.isApiError = true;
            } else if (typeof errorData === 'string') {
                error.message = errorData;
                error.errorData = { description: errorData };
                error.isApiError = true;
            } else {
                error.message = `HTTP error! status: ${error.response.status}`;
                error.errorData = errorData || {};
                error.isApiError = true;
            }

            // Ensure response.data is preserved
            error.response.data = errorData;

            // Log the extracted error for debugging
            console.log('Extracted API Error:', {
                message: error.message,
                errorData: error.errorData,
                status: error.response.status
            });
        } else if (error.request) {
            // Request was made but no response received (ACTUAL network error)
            error.message = `Network error: Unable to connect to ${API_BASE_URL || 'the API server'}. Please check if the API server is running.`;
            error.errorData = {
                description: error.message,
                solution: "Verify your network connection and try again."
            };
            error.isNetworkError = true;
        } else {
            // Something else happened
            error.message = error.message || 'An unexpected error occurred';
            error.errorData = {
                description: error.message,
                solution: "Please try again or contact support."
            };
        }

        return Promise.reject(error);
    }
);

/**
 * API Methods
 */
export const api = {
    // Authentication
    login: async (identifier, password, companyId = null) => {
        const response = await axiosInstance.post('/auth/login', {
            identifier,
            password,
            company_id: companyId,
        });
        return response.data;
    },

    googleLogin: () => {
        // Redirect to Google OAuth
        // For proxy mode (empty API_BASE_URL), use full URL for redirects
        const baseUrl = API_BASE_URL || 'http://localhost:9001';
        window.location.href = `${baseUrl}/auth/google`;
    },

    getUserContext: async () => {
        const response = await axiosInstance.get('/auth/me');
        return response.data;
    },

    getAccounts: async () => {
        const response = await axiosInstance.get('/auth/accounts');
        return response.data;
    },

    switchAccount: async (companyId, profileName = null) => {
        const response = await axiosInstance.post('/auth/switch-account', {
            company_id: companyId,
            profile_name: profileName,
        });
        return response.data;
    },

    getSessions: async () => {
        const response = await axiosInstance.get('/auth/sessions');
        return response.data;
    },

    deleteSession: async (sessionId) => {
        const response = await axiosInstance.delete(`/auth/sessions/${sessionId}`);
        return response.data;
    },

    deleteAccountProfile: async (profileId) => {
        const response = await axiosInstance.delete(`/auth/accounts/${profileId}`);
        return response.data;
    },

    logout: async () => {
        try {
            await axiosInstance.post('/auth/logout');
        } catch (e) {
            // Ignore errors on logout
        }
        setAccessToken(null);
        setStoredAccounts([]);
        setCurrentAccountId(null);
    },

    // Menus
    getMenus: async () => {
        const response = await axiosInstance.get('/auth/menus');
        return response.data;
    },

    // Apps
    getApps: async () => {
        const response = await axiosInstance.get('/auth/apps');
        return response.data;
    },

    // App Menus
    getAppMenus: async (appId) => {
        const response = await axiosInstance.get(`/auth/apps/${appId}/menus`);
        return response.data;
    },
};
