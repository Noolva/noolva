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
    executeQuery: async (query) => {
        const response = await axiosInstance.post("/dev-console/database/execute-query", {
            query,
            limit: 1000
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

    deleteDataModel: async (modelId, deleteTable = false) => {
        const response = await axiosInstance.delete(`/data-models/model/${modelId}`, {
            params: { delete_table: deleteTable }
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
};
