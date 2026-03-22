/** Injected at build time via vite.config.js `define` (package.json + optional git SHA). */
export const APP_VERSION = __APP_VERSION__;
export const GIT_SHA = __GIT_SHA__;
export const BUILD_LABEL = GIT_SHA ? `${APP_VERSION} (${GIT_SHA})` : APP_VERSION;
