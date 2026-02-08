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
 * Get current account ID - checks URL first, then sessionStorage, then localStorage
 * This ensures each browser tab maintains its own account context
 */
export const getCurrentAccountId = () => {
    // 1. Check URL parameter (highest priority - for tab-specific context)
    if (typeof window !== 'undefined') {
        const urlParams = new URLSearchParams(window.location.search);
        const accountFromUrl = urlParams.get('account');
        if (accountFromUrl) {
            // Store in sessionStorage for this tab
            sessionStorage.setItem('current_account_id', accountFromUrl);
            return accountFromUrl;
        }

        // 2. Check sessionStorage (tab-specific)
        const accountFromSession = sessionStorage.getItem('current_account_id');
        if (accountFromSession) {
            return accountFromSession;
        }
    }

    // 3. Fall back to localStorage (backward compatibility)
    return localStorage.getItem('current_account_id');
};

/**
 * Set current account ID - updates URL, sessionStorage, and localStorage
 */
export const setCurrentAccountId = (accountId) => {
    if (typeof window === 'undefined') return;

    if (accountId) {
        const accountIdStr = accountId.toString();
        // Update sessionStorage (tab-specific)
        sessionStorage.setItem('current_account_id', accountIdStr);
        // Update localStorage (for backward compatibility)
        localStorage.setItem('current_account_id', accountIdStr);

        // Update URL parameter without page reload
        const url = new URL(window.location.href);
        url.searchParams.set('account', accountIdStr);
        window.history.replaceState({}, '', url.toString());
    } else {
        sessionStorage.removeItem('current_account_id');
        localStorage.removeItem('current_account_id');

        // Remove account from URL
        const url = new URL(window.location.href);
        url.searchParams.delete('account');
        window.history.replaceState({}, '', url.toString());
    }
};

/**
 * Get account ID from URL without side effects
 */
export const getAccountIdFromUrl = () => {
    if (typeof window === 'undefined') return null;
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('account');
};

/**
 * Update URL with account parameter while preserving other params
 */
export const updateUrlWithAccount = (accountId, replace = true) => {
    if (typeof window === 'undefined') return;

    const url = new URL(window.location.href);
    if (accountId) {
        url.searchParams.set('account', accountId.toString());
    } else {
        url.searchParams.delete('account');
    }

    if (replace) {
        window.history.replaceState({}, '', url.toString());
    } else {
        window.history.pushState({}, '', url.toString());
    }
};

// Session idle lock: re-export from dedicated module (single source of truth)
import { getSessionLocked, getSessionLockedRequire2FA } from './sessionLock.js';
export { getSessionLocked, getSessionLockedRequire2FA, setSessionLocked, clearSessionLock } from './sessionLock.js';

// Requests that are allowed even when session is locked (so user can log back in / reauth)
const isAuthAllowedWhenLocked = (config) => {
    const method = (config.method || 'get').toLowerCase();
    const url = (config.url || '').replace(/^\//, '');
    if (method !== 'post') return false;
    if (url === 'auth/reauth' || url.endsWith('/auth/reauth')) return true;
    if (url === 'auth/login' || url.endsWith('/auth/login')) return true;
    if (url === 'auth/login/verify-totp' || url.includes('auth/login/verify-totp')) return true;
    return false;
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

// Request interceptor: block all requests when session is locked (except auth flows like reauth/login)
axiosInstance.interceptors.request.use(
    (config) => {
        if (getSessionLocked() && !isAuthAllowedWhenLocked(config)) {
            try {
                window.dispatchEvent(new CustomEvent('auth:idleLock', { detail: { enable_2fa: getSessionLockedRequire2FA() } }));
            } catch (e) { /* ignore */ }
            return Promise.reject(Object.assign(new Error('Session locked'), { isSessionLocked: true }));
        }
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

            // 401 Token expired: show re-login modal without losing current UI
            const detail = errorData?.detail ?? errorData?.message ?? '';
            const isTokenExpired = error.response.status === 401 &&
                (detail === 'Token expired' || (typeof detail === 'string' && detail.toLowerCase().includes('token expired')));
            if (isTokenExpired) {
                try {
                    window.dispatchEvent(new CustomEvent('auth:tokenExpired', { detail: { error, errorData } }));
                } catch (e) {
                    console.warn('auth:tokenExpired dispatch failed', e);
                }
            }

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

    loginVerifyTotp: async (tempToken, totpCode) => {
        const response = await axiosInstance.post('/auth/login/verify-totp', {
            temp_token: tempToken,
            totp_code: totpCode,
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

    // Organization Users (list excludes system user)
    getOrganizationUsers: async () => {
        const response = await axiosInstance.get('/auth/users');
        return response.data;
    },

    createUser: async (data) => {
        const response = await axiosInstance.post('/auth/create-user', data);
        return response.data;
    },

    resetUserPassword: async (userId, newPassword) => {
        const response = await axiosInstance.post(`/auth/users/${userId}/reset-password`, {
            new_password: newPassword,
        });
        return response.data;
    },

    // Two-Factor Authentication (Authenticator app)
    get2FASetup: async () => {
        const response = await axiosInstance.get('/auth/2fa/setup');
        return response.data;
    },
    verify2FA: async (code) => {
        const response = await axiosInstance.post('/auth/2fa/verify', { code });
        return response.data;
    },
    disable2FA: async () => {
        const response = await axiosInstance.post('/auth/2fa/disable');
        return response.data;
    },

    // Current user: update own idle timeout (null = use global, -1 = no lock, number = minutes)
    updateMyIdleTimeout: async (idleTimeoutMinutes) => {
        const response = await axiosInstance.put('/auth/me/idle-timeout', {
            idle_timeout_minutes: idleTimeoutMinutes,
        });
        return response.data;
    },

    // Re-auth after idle lock (password + optional TOTP code)
    reauth: async (password, totpCode = null) => {
        const response = await axiosInstance.post('/auth/reauth', {
            password,
            totp_code: totpCode || null,
        });
        return response.data;
    },

    // Personal Access Tokens
    listPersonalAccessTokens: async () => {
        const response = await axiosInstance.get('/personal-access-tokens/list');
        return response.data;
    },
    createPersonalAccessToken: async (data) => {
        const response = await axiosInstance.post('/personal-access-tokens/create', data);
        return response.data;
    },
    revokePersonalAccessToken: async (patId) => {
        const response = await axiosInstance.delete(`/personal-access-tokens/${patId}`);
        return response.data;
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

    // Get menus for an app (for sidebar display)
    getMenusForApp: async (appId) => {
        const response = await axiosInstance.get(`/auth/apps/${appId}/menus`);
        return response.data;
    },

    // Settings
    getSettings: async ({ keys, scope = "global", tenant_id = null } = {}) => {
        const params = {};
        if (keys) params.keys = Array.isArray(keys) ? keys.join(",") : keys;
        if (scope) params.scope = scope;
        if (tenant_id != null) params.tenant_id = tenant_id;
        const response = await axiosInstance.get("/settings", { params });
        return response.data;
    },

    updateSettings: async ({ settings, scope = "global", tenant_id = null }) => {
        const response = await axiosInstance.put("/settings", {
            settings,
            scope,
            tenant_id,
        });
        return response.data;
    },

    getSettingsDefinitions: async ({ scope = "global", tenant_id = null } = {}) => {
        const params = { scope };
        if (tenant_id != null) params.tenant_id = tenant_id;
        const response = await axiosInstance.get("/settings/definitions", { params });
        return response.data;
    },

    // Themes
    getThemes: async ({ scope = "saas", user_id = null, tenant_id = null } = {}) => {
        const params = { scope };
        if (user_id != null) params.user_id = user_id;
        if (tenant_id != null) params.tenant_id = tenant_id;
        const response = await axiosInstance.get("/themes", { params });
        return response.data;
    },
    getActiveTheme: async ({ scope = "saas", user_id = null, tenant_id = null } = {}) => {
        const params = { scope };
        if (user_id != null) params.user_id = user_id;
        if (tenant_id != null) params.tenant_id = tenant_id;
        const response = await axiosInstance.get("/themes/active", { params });
        return response.data;
    },
    getTheme: async (themeId) => {
        const response = await axiosInstance.get(`/themes/${themeId}`);
        return response.data;
    },
    createTheme: async (data) => {
        const response = await axiosInstance.post("/themes", data);
        return response.data;
    },
    updateTheme: async (themeId, data) => {
        const response = await axiosInstance.put(`/themes/${themeId}`, data);
        return response.data;
    },
    upsertMyTheme: async ({ theme_json, scope = "saas" }) => {
        const response = await axiosInstance.put("/themes/mine", { theme_json }, { params: { scope } });
        return response.data;
    },
    deleteTheme: async (themeId) => {
        const response = await axiosInstance.delete(`/themes/${themeId}`);
        return response.data;
    },

    // Developer Console - Database
    getDatabaseTables: async (search = null) => {
        const params = search ? { search } : {};
        const response = await axiosInstance.get("/dev-console/database/tables", { params });
        return response.data;
    },

    getTableStructure: async (tableName) => {
        const response = await axiosInstance.get(`/dev-console/database/tables/${tableName}/structure`);
        return response.data;
    },

    getTableRecords: async (tableName, limit = 100, offset = 0) => {
        const response = await axiosInstance.get(`/dev-console/database/tables/${tableName}/records`, {
            params: { limit, offset }
        });
        return response.data;
    },

    updateTableSchema: async (tableName, changes) => {
        const response = await axiosInstance.put(`/dev-console/database/tables/${tableName}/schema`, {
            changes
        });
        return response.data;
    },

    // Developer Console - Database Query
    executeQuery: async (query, limit = 1000) => {
        const response = await axiosInstance.post("/dev-console/database/execute-query", {
            query,
            limit
        });
        return response.data;
    },

    getQuerySuggestions: async (prefix = null) => {
        const params = prefix ? { prefix } : {};
        const response = await axiosInstance.get("/dev-console/database/suggestions", { params });
        return response.data;
    },

    // Record operations
    insertRecord: async (tableName, data) => {
        const response = await axiosInstance.post("/dev-console/database/records", {
            table_name: tableName,
            data
        });
        return response.data;
    },

    updateRecord: async (tableName, recordId, updates) => {
        const response = await axiosInstance.put("/dev-console/database/records", {
            table_name: tableName,
            record_id: recordId,
            updates
        });
        return response.data;
    },

    deleteRecord: async (tableName, recordId) => {
        const response = await axiosInstance.delete("/dev-console/database/records", {
            params: {
                table_name: tableName,
                record_id: recordId
            }
        });
        return response.data;
    },

    // Companies
    getCompanies: async () => {
        const response = await axiosInstance.get("/companies");
        return response.data;
    },

    getCompany: async (companyId) => {
        const response = await axiosInstance.get(`/companies/${companyId}`);
        return response.data;
    },

    createCompany: async (data) => {
        const response = await axiosInstance.post("/companies", data);
        return response.data;
    },

    updateCompany: async (companyId, data) => {
        const response = await axiosInstance.put(`/companies/${companyId}`, data);
        return response.data;
    },

    deleteCompany: async (companyId) => {
        const response = await axiosInstance.delete(`/companies/${companyId}`);
        return response.data;
    },

    // App Menus
    getAppMenus: async (appId = null) => {
        const url = appId ? `/app-menus?app_id=${appId}` : "/app-menus";
        const response = await axiosInstance.get(url);
        return response.data;
    },

    getAppMenu: async (menuId) => {
        const response = await axiosInstance.get(`/app-menus/${menuId}`);
        return response.data;
    },

    createAppMenu: async (data) => {
        const response = await axiosInstance.post("/app-menus", data);
        return response.data;
    },

    updateAppMenu: async (menuId, data) => {
        const response = await axiosInstance.put(`/app-menus/${menuId}`, data);
        return response.data;
    },

    deleteAppMenu: async (menuId) => {
        const response = await axiosInstance.delete(`/app-menus/${menuId}`);
        return response.data;
    },

    // User Groups
    getUserGroups: async () => {
        const response = await axiosInstance.get("/user-groups");
        return response.data;
    },

    getUserGroup: async (groupId) => {
        const response = await axiosInstance.get(`/user-groups/${groupId}`);
        return response.data;
    },

    createUserGroup: async (data) => {
        const response = await axiosInstance.post("/user-groups", data);
        return response.data;
    },

    updateUserGroup: async (groupId, data) => {
        const response = await axiosInstance.put(`/user-groups/${groupId}`, data);
        return response.data;
    },

    deleteUserGroup: async (groupId) => {
        const response = await axiosInstance.delete(`/user-groups/${groupId}`);
        return response.data;
    },

    // Teams
    getTeams: async () => {
        const response = await axiosInstance.get("/teams");
        return response.data;
    },

    getTeam: async (teamId) => {
        const response = await axiosInstance.get(`/teams/${teamId}`);
        return response.data;
    },

    createTeam: async (data) => {
        const response = await axiosInstance.post("/teams", data);
        return response.data;
    },

    updateTeam: async (teamId, data) => {
        const response = await axiosInstance.put(`/teams/${teamId}`, data);
        return response.data;
    },

    deleteTeam: async (teamId) => {
        const response = await axiosInstance.delete(`/teams/${teamId}`);
        return response.data;
    },

    // Roles
    getRoles: async () => {
        const response = await axiosInstance.get("/roles");
        return response.data;
    },

    getRole: async (roleId) => {
        const response = await axiosInstance.get(`/roles/${roleId}`);
        return response.data;
    },

    createRole: async (data) => {
        const response = await axiosInstance.post("/roles", data);
        return response.data;
    },

    updateRole: async (roleId, data) => {
        const response = await axiosInstance.put(`/roles/${roleId}`, data);
        return response.data;
    },

    deleteRole: async (roleId) => {
        const response = await axiosInstance.delete(`/roles/${roleId}`);
        return response.data;
    },

    // Permissions
    getPermissions: async () => {
        const response = await axiosInstance.get("/permissions");
        return response.data;
    },

    getPermission: async (permissionId) => {
        const response = await axiosInstance.get(`/permissions/${permissionId}`);
        return response.data;
    },

    createPermission: async (data) => {
        const response = await axiosInstance.post("/permissions", data);
        return response.data;
    },

    updatePermission: async (permissionId, data) => {
        const response = await axiosInstance.put(`/permissions/${permissionId}`, data);
        return response.data;
    },

    deletePermission: async (permissionId) => {
        const response = await axiosInstance.delete(`/permissions/${permissionId}`);
        return response.data;
    },

    // Data Models
    getDataModels: async ({ appId = null, limit = 500, offset = 0, search = null } = {}) => {
        const params = { limit, offset };
        if (appId != null) params.app_id = appId;
        if (search) params.search = search;
        const response = await axiosInstance.get("/data-models/list", { params });
        return response.data;
    },

    getDataModel: async (modelId, includeFields = true) => {
        const response = await axiosInstance.get(`/data-models/model/${modelId}`, {
            params: { include_fields: includeFields }
        });
        return response.data;
    },

    createDataModel: async (data) => {
        const response = await axiosInstance.post("/data-models/create", data);
        return response.data;
    },

    updateDataModel: async (modelId, data) => {
        const response = await axiosInstance.put(`/data-models/model/${modelId}`, data);
        return response.data;
    },

    checkModelDeletion: async (modelId) => {
        const response = await axiosInstance.get(`/data-models/model/${modelId}/delete-check`);
        return response.data;
    },

    deleteDataModel: async (modelId, deleteTable = false, confirmDeleteData = false) => {
        const response = await axiosInstance.delete(`/data-models/model/${modelId}`, {
            params: {
                delete_table: deleteTable,
                confirm_delete_data: confirmDeleteData
            }
        });
        return response.data;
    },

    addDataModelField: async (modelId, fieldData) => {
        const response = await axiosInstance.post(`/data-models/model/${modelId}/fields`, fieldData);
        return response.data;
    },

    updateDataModelField: async (modelId, fieldId, fieldData) => {
        const response = await axiosInstance.put(`/data-models/model/${modelId}/fields/${fieldId}`, fieldData);
        return response.data;
    },

    deleteDataModelField: async (modelId, fieldId, deleteColumn = false) => {
        const response = await axiosInstance.delete(`/data-models/model/${modelId}/fields/${fieldId}`, {
            params: { delete_column: deleteColumn }
        });
        return response.data;
    },

    reorderDataModelFields: async (modelId, fieldIds) => {
        const response = await axiosInstance.put(`/data-models/model/${modelId}/fields/reorder`, {
            field_ids: fieldIds
        });
        return response.data;
    },

    getFieldTypes: async () => {
        const response = await axiosInstance.get("/data-models/field-types/list");
        return response.data;
    },

    // Icons
    getIcons: async ({ search, category, icon_type, tag, is_popular, limit = 10000, offset = 0 } = {}) => {
        const params = { limit, offset };
        if (search) params.search = search;
        if (category) params.category = category;
        if (icon_type) params.icon_type = icon_type;
        if (tag) params.tag = tag;
        if (is_popular !== undefined) params.is_popular = is_popular;
        const response = await axiosInstance.get("/icons/list", { params });
        return response.data;
    },

    getIcon: async (iconId) => {
        const response = await axiosInstance.get(`/icons/${iconId}`);
        return response.data;
    },

    getIconCategories: async () => {
        const response = await axiosInstance.get("/icons/categories/list");
        return response.data;
    },

    getIconTags: async () => {
        const response = await axiosInstance.get("/icons/tags/list");
        return response.data;
    },

    getIconTypes: async () => {
        const response = await axiosInstance.get("/icons/types/list");
        return response.data;
    },

    // Collections
    getCollections: async ({ tenantId = null, limit = 500, offset = 0, search = null } = {}) => {
        const params = { limit, offset };
        if (tenantId != null) params.tenant_id = tenantId;
        if (search) params.search = search;
        const response = await axiosInstance.get("/collections/list", { params });
        return response.data;
    },

    getCollection: async (collectionId) => {
        const response = await axiosInstance.get(`/collections/${collectionId}`);
        return response.data;
    },

    createCollection: async (data) => {
        const response = await axiosInstance.post("/collections/create", data);
        return response.data;
    },

    updateCollection: async (collectionId, data) => {
        const response = await axiosInstance.put(`/collections/${collectionId}`, data);
        return response.data;
    },

    deleteCollection: async (collectionId) => {
        const response = await axiosInstance.delete(`/collections/${collectionId}`);
        return response.data;
    },

    // API Endpoints
    getApiEndpoints: async ({ limit = 500, offset = 0, search = null, type = null } = {}) => {
        const params = { limit, offset };
        if (search) params.search = search;
        if (type) params.type_filter = type;
        const response = await axiosInstance.get("/api-endpoints/list", { params });
        return response.data;
    },

    getApiEndpoint: async (endpointId) => {
        const response = await axiosInstance.get(`/api-endpoints/${endpointId}`);
        return response.data;
    },

    createApiEndpoint: async (data) => {
        const response = await axiosInstance.post("/api-endpoints/create", data);
        return response.data;
    },

    updateApiEndpoint: async (endpointId, data) => {
        const response = await axiosInstance.put(`/api-endpoints/${endpointId}`, data);
        return response.data;
    },

    deleteApiEndpoint: async (endpointId) => {
        const response = await axiosInstance.delete(`/api-endpoints/${endpointId}`);
        return response.data;
    },

    // API Tester - call custom endpoint (GET with pagination)
    callCustomEndpoint: async (endpointId, { limit = 10, offset = 0 } = {}) => {
        const response = await axiosInstance.get(`/data-models/custom-endpoint/${endpointId}`, {
            params: { limit, offset },
        });
        return response.data;
    },

    // API Tester - generic call for auto_crud or any endpoint
    testApiCall: async ({ path, method = 'GET', params = {}, body = null }) => {
        const url = path.startsWith('/') ? path : `/${path}`;
        const config = { url, method, params };
        if (body != null && ['POST', 'PUT', 'PATCH'].includes(method.toUpperCase())) {
            config.data = body;
        }
        const response = await axiosInstance.request(config);
        return response.data;
    },
};
