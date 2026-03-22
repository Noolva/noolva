/**
 * Runtime config loaded from /console/runtime-config.json before the app mounts.
 *
 * Shape: { "apiOrigin": "https://api.example.com", "scope": "saas" }
 * - apiOrigin: scheme+host[:port] only, e.g. https://karandev.noolva.com — or include …/api; we normalize once.
 * - scope: theme API query param; omit → VITE_APP_SCOPE → "saas"
 */

export function getRuntimeConfig() {
    if (typeof window === 'undefined') return {};
    return window.__NOOLVA_RUNTIME__ && typeof window.__NOOLVA_RUNTIME__ === 'object'
        ? window.__NOOLVA_RUNTIME__
        : {};
}

/** Configured host or full …/api string from runtime file, then VITE_API_URL (no trailing slash). */
function configuredApiHostOrRoot() {
    const r = getRuntimeConfig();
    const fromFile = r.apiOrigin;
    if (fromFile !== undefined && fromFile !== null && String(fromFile).trim() !== '') {
        return String(fromFile).trim().replace(/\/+$/, '');
    }
    return (import.meta.env.VITE_API_URL || '').replace(/\/+$/, '');
}

/**
 * JSON API base URL with trailing slash.
 * Trailing slash matters: axios uses the URL() rules; a request path like "/auth/me" would otherwise
 * replace the whole path and drop …/api (you would see requests to /auth/me on the site root).
 */
export function resolveApiBaseUrl() {
    const s = configuredApiHostOrRoot();
    let base;
    if (!s) base = '/api';
    else if (s.endsWith('/api')) base = s;
    else base = `${s}/api`;
    return base.endsWith('/') ? base : `${base}/`;
}

/** Origin only (for /assets/…); strips a trailing /api from configured value. */
export function resolveApiOrigin() {
    const s = configuredApiHostOrRoot();
    if (!s) return '';
    if (s.endsWith('/api')) return s.slice(0, -4);
    return s;
}

/**
 * For /assets/… when API returns a relative path.
 * Prefer resolveApiAssetUrl() for DB paths like /assets/foo.svg so same-host deploys use /api/assets/…
 * (nginx proxies /api to the API; /assets at site root would hit the wrong static app).
 */
export function getApiOriginForAssets() {
    const o = resolveApiOrigin();
    if (o) return o;
    if (typeof window !== 'undefined' && window.location?.origin) {
        return window.location.origin.replace(/\/$/, '');
    }
    return (import.meta.env.VITE_API_URL || 'http://localhost:9001').replace(/\/$/, '');
}

/**
 * Build URL for files under the API assets dir. DB paths are usually /assets/….
 * Uses /api/assets/… when using same-origin JSON (/api proxy), so nginx can reach FastAPI.
 */
export function resolveApiAssetUrl(path) {
    if (path == null || path === '') return path;
    const s = String(path).trim();
    if (!s) return s;
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    const base = resolveApiBaseUrl().replace(/\/+$/, '');
    const withSlash = s.startsWith('/') ? s : `/assets/${s}`;
    if (withSlash.startsWith('/assets/')) {
        return `${base}${withSlash}`;
    }
    return `${getApiOriginForAssets()}${withSlash}`;
}

/** App scope for /themes/* APIs (must match backend expectations). */
export function resolveAppScope() {
    const r = getRuntimeConfig();
    const fromFile = r.scope;
    if (fromFile !== undefined && fromFile !== null && String(fromFile).trim() !== '') {
        return String(fromFile).trim();
    }
    return (import.meta.env.VITE_APP_SCOPE || 'saas').trim();
}

/** Full URL for browser redirects (e.g. OAuth). */
export function resolveGoogleAuthUrl() {
    const base = resolveApiBaseUrl();
    if (base.startsWith('http')) return `${base}auth/google`;
    if (typeof window !== 'undefined' && window.location?.origin) {
        return `${window.location.origin}${base}auth/google`;
    }
    return `${base}auth/google`;
}
