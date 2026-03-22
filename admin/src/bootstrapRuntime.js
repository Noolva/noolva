/**
 * Load public/runtime-config.json (copied to dist root) before React mounts.
 * Deployments can overwrite dist/runtime-config.json per environment without a new JS build.
 */
export async function loadRuntimeConfig() {
    if (typeof window === 'undefined') return;
    const base = import.meta.env.BASE_URL;
    try {
        const res = await fetch(`${base}runtime-config.json`, { cache: 'no-store' });
        window.__NOOLVA_RUNTIME__ = res.ok ? await res.json() : {};
    } catch {
        window.__NOOLVA_RUNTIME__ = {};
    }
}
