import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { ConfigProvider, theme as antdTheme } from 'antd';
import { api } from '../utils/api';
import { resolveAppScope } from '../config/runtimeApi';
import { useAuth } from './AuthContext';

const ThemeContext = createContext();

const THEME_MODE_KEY = 'noolva_theme_mode';

export const themes = {
    // Theme 1 (Default): clean corporate neutral
    default: {
        name: 'Default Corporate',
        light: {
            bg: '#f5f7fb',
            surface: '#ffffff',
            text: '#101828',
            textSecondary: '#475467',
            border: '#e4e7ec',
        },
        dark: {
            bg: '#0b1220',
            surface: '#0f172a',
            text: '#f8fafc',
            textSecondary: '#cbd5e1',
            border: '#26324a',
        },
    },
    // Theme 2: slate + subtle contrast corporate
    slate: {
        name: 'Slate Corporate',
        light: {
            bg: '#f6f8fa',
            surface: '#ffffff',
            text: '#0f172a',
            textSecondary: '#334155',
            border: '#e2e8f0',
        },
        dark: {
            bg: '#0a0f1a',
            surface: '#111827',
            text: '#f1f5f9',
            textSecondary: '#cbd5e1',
            border: '#263040',
        },
    },
};

const DEFAULT_PRIMARY = '#1890ff';
const DEFAULT_SECONDARY = '#52c41a';
const DEFAULT_FONT_BASE = 14;
const DEFAULT_FONT_SMALL = 12;
const DEFAULT_FONT_LARGE = 16;

const DEFAULT_HEADER_BG = '#2563eb';
const DEFAULT_SIDEBAR_BG = '#f1f5f9';

export const ThemeProvider = ({ children }) => {
    const { user } = useAuth();
    const [isDark, setIsDark] = useState(false);
    const [themeKey, setThemeKey] = useState('default');
    const [primary, setPrimary] = useState(DEFAULT_PRIMARY);
    const [secondary, setSecondary] = useState(DEFAULT_SECONDARY);
    const [headerBgColor, setHeaderBgColor] = useState(DEFAULT_HEADER_BG);
    const [sidebarBgColor, setSidebarBgColor] = useState(DEFAULT_SIDEBAR_BG);
    const [fontBase, setFontBase] = useState(DEFAULT_FONT_BASE);
    const [fontSmall, setFontSmall] = useState(DEFAULT_FONT_SMALL);
    const [fontLarge, setFontLarge] = useState(DEFAULT_FONT_LARGE);
    const [settingsLoaded, setSettingsLoaded] = useState(false);

    const toggleDark = () => {
        const newDark = !isDark;
        setIsDark(newDark);
        try {
            localStorage.setItem(THEME_MODE_KEY, newDark ? 'dark' : 'light');
        } catch (e) { }
        document.body.setAttribute('data-theme', newDark ? 'dark' : 'light');
    };

    const setPrimarySecondary = (primary, secondary) => {
        setPrimary(primary);
        setSecondary(secondary);
    };

    const selectThemeByKey = (key) => {
        if (themes[key]) {
            setThemeKey(key);
        }
    };

    // Load theme from themes API (best-effort)
    useEffect(() => {
        let mounted = true;
        const load = async () => {
            try {
                // Theme mode from header toggle - persisted in localStorage
                try {
                    const stored = localStorage.getItem(THEME_MODE_KEY);
                    if (stored === 'dark' || stored === 'light') setIsDark(stored === 'dark');
                } catch (e) { }

                const res = await api.getActiveTheme({ scope: resolveAppScope(), user_id: user?.user_id ?? undefined });
                const t = res?.theme;
                if (!mounted || !t) {
                    if (mounted) setSettingsLoaded(true);
                    return;
                }

                const rawTj = t.theme_json;
                const tj = (() => {
                    if (!rawTj) return {};
                    if (typeof rawTj === 'string') {
                        try { return JSON.parse(rawTj); } catch { return {}; }
                    }
                    return rawTj;
                })();
                if (typeof tj.theme === 'string' && themes[tj.theme]) setThemeKey(tj.theme);
                if (typeof tj.theme_color_primary === 'string') setPrimary(tj.theme_color_primary);
                if (typeof tj.theme_color_secondary === 'string') setSecondary(tj.theme_color_secondary);
                if (typeof tj.header_bg_color === 'string') setHeaderBgColor(tj.header_bg_color === 'none' ? '' : tj.header_bg_color);
                else setHeaderBgColor(DEFAULT_HEADER_BG);
                if (typeof tj.sidebar_bg_color === 'string') setSidebarBgColor(tj.sidebar_bg_color === 'none' ? '' : tj.sidebar_bg_color);
                else setSidebarBgColor(DEFAULT_SIDEBAR_BG);

                if (typeof tj.font_size_base === 'number') setFontBase(tj.font_size_base);
                else if (typeof tj.font_size_base === 'string') setFontBase(parseInt(tj.font_size_base, 10) || DEFAULT_FONT_BASE);
                if (typeof tj.font_size_small === 'number') setFontSmall(tj.font_size_small);
                else if (typeof tj.font_size_small === 'string') setFontSmall(parseInt(tj.font_size_small, 10) || DEFAULT_FONT_SMALL);
                if (typeof tj.font_size_large === 'number') setFontLarge(tj.font_size_large);
                else if (typeof tj.font_size_large === 'string') setFontLarge(parseInt(tj.font_size_large, 10) || DEFAULT_FONT_LARGE);
            } catch (e) {
                // ignore - defaults will be used
            } finally {
                if (mounted) setSettingsLoaded(true);
            }
        };
        load();
        return () => { mounted = false; };
    }, [user?.user_id]);

    // Apply CSS variables globally for custom CSS pieces (header/login/tabs)
    useEffect(() => {
        const root = document.body;
        const palette = (themes[themeKey] || themes.default)[isDark ? 'dark' : 'light'];
        root.setAttribute('data-theme', isDark ? 'dark' : 'light');
        root.style.setProperty('--bg-color', palette.bg);
        root.style.setProperty('--surface-color', palette.surface);
        root.style.setProperty('--text-color', palette.text);
        root.style.setProperty('--text-secondary-color', palette.textSecondary);
        root.style.setProperty('--border-color', palette.border);
        root.style.setProperty('--primary-color', primary);
        root.style.setProperty('--secondary-color', secondary);
        root.style.setProperty('--header-bg-color', headerBgColor || 'transparent');
        root.style.setProperty('--sidebar-bg-color', sidebarBgColor || 'transparent');
        // Sidebar right border: dark border in light mode, light border in dark mode so it's always visible
        const sidebarBorderColor = isDark ? 'rgba(255, 255, 255, 0.2)' : 'rgba(0, 0, 0, 0.18)';
        root.style.setProperty('--sidebar-border-color', sidebarBorderColor);
        root.style.setProperty('--header-text-color', (headerBgColor && headerBgColor !== 'transparent') ? '#ffffff' : 'var(--text-color)');
        root.style.setProperty('--sidebar-text-color', (sidebarBgColor && sidebarBgColor !== 'transparent') ? '#ffffff' : 'var(--text-color)');
        root.style.setProperty('--font-size-base', `${fontBase}px`);
        root.style.setProperty('--font-size-small', `${fontSmall}px`);
        root.style.setProperty('--font-size-large', `${fontLarge}px`);
    }, [isDark, themeKey, primary, secondary, headerBgColor, sidebarBgColor, fontBase, fontSmall, fontLarge]);

    const theme = useMemo(() => {
        const palette = (themes[themeKey] || themes.default)[isDark ? 'dark' : 'light'];
        return {
            token: {
                colorPrimary: primary,
                colorSuccess: secondary,
                colorBgLayout: palette.bg,
                colorBgContainer: palette.surface,
                colorText: palette.text,
                colorTextSecondary: palette.textSecondary,
                colorBorderSecondary: palette.border,
                borderRadius: 8,
                fontSize: fontBase,
                fontSizeSM: fontSmall,
                fontSizeLG: fontLarge,
            },
            algorithm: isDark ? antdTheme.darkAlgorithm : antdTheme.defaultAlgorithm,
        };
    }, [isDark, themeKey, primary, secondary, fontBase, fontSmall, fontLarge]);

    return (
        <ThemeContext.Provider value={{
            isDark,
            toggleDark,
            settingsLoaded,
            primary,
            secondary,
            headerBgColor,
            sidebarBgColor,
            setHeaderBgColor,
            setSidebarBgColor,
            fontBase,
            fontSmall,
            fontLarge,
            themeKey,
            themes,
            setPrimarySecondary,
            selectThemeByKey,
            setIsDark,
            setThemeKey,
            setFontBase,
            setFontSmall,
            setFontLarge,
        }}>
            <ConfigProvider theme={theme}>
                {children}
            </ConfigProvider>
        </ThemeContext.Provider>
    );
};

export const useTheme = () => useContext(ThemeContext);
