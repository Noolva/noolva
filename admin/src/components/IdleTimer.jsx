import React, { useRef, useEffect, useCallback } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { setSessionLocked } from '../utils/api';

const IDLE_EVENTS = ['mousedown', 'mousemove', 'keydown', 'scroll', 'touchstart'];

/**
 * When user is logged in and effective_idle_timeout_minutes > 0, locks session after that many
 * minutes of inactivity. Sets session lock in localStorage (shared across tabs) and dispatches
 * auth:idleLock. All API requests are blocked until user re-authenticates; duplicate tabs cannot bypass.
 */
export default function IdleTimer() {
    const { user } = useAuth();
    const timeoutRef = useRef(null);
    const lastActivityRef = useRef(Date.now());

    const lock = useCallback(() => {
        if (!user?.user_id) return;
        setSessionLocked(!!user.enable_2fa);
        window.dispatchEvent(new CustomEvent('auth:idleLock', {
            detail: { enable_2fa: !!user.enable_2fa },
        }));
    }, [user?.user_id, user?.enable_2fa]);

    const resetTimer = useCallback(() => {
        lastActivityRef.current = Date.now();
        if (timeoutRef.current) {
            clearTimeout(timeoutRef.current);
            timeoutRef.current = null;
        }
        const minutes = user?.effective_idle_timeout_minutes;
        if (minutes == null || minutes < 0) return;
        const ms = minutes * 60 * 1000;
        timeoutRef.current = setTimeout(lock, ms);
    }, [user?.effective_idle_timeout_minutes, lock]);

    useEffect(() => {
        if (!user?.user_id) return;
        const minutes = user?.effective_idle_timeout_minutes;
        if (minutes == null || minutes < 0) return;
        resetTimer();
        const onActivity = () => resetTimer();
        IDLE_EVENTS.forEach(ev => window.addEventListener(ev, onActivity));
        return () => {
            IDLE_EVENTS.forEach(ev => window.removeEventListener(ev, onActivity));
            if (timeoutRef.current) clearTimeout(timeoutRef.current);
        };
    }, [user?.user_id, user?.effective_idle_timeout_minutes, resetTimer]);

    return null;
}
