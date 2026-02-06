/**
 * Session idle lock helpers. Shared across tabs via localStorage so duplicate tabs cannot bypass.
 * Used by IdleTimer, ReLoginModal, AuthContext, and api interceptor.
 */
const SESSION_LOCKED_KEY = 'session_locked';
const SESSION_LOCKED_2FA_KEY = 'session_locked_require_2fa';

export const getSessionLocked = () => localStorage.getItem(SESSION_LOCKED_KEY) === '1';
export const getSessionLockedRequire2FA = () => localStorage.getItem(SESSION_LOCKED_2FA_KEY) === '1';
export const setSessionLocked = (require2fa = false) => {
    localStorage.setItem(SESSION_LOCKED_KEY, '1');
    localStorage.setItem(SESSION_LOCKED_2FA_KEY, require2fa ? '1' : '0');
};
export const clearSessionLock = () => {
    localStorage.removeItem(SESSION_LOCKED_KEY);
    localStorage.removeItem(SESSION_LOCKED_2FA_KEY);
};
