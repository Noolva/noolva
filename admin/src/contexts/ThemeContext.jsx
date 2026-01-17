import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { ConfigProvider, theme as antdTheme } from 'antd';
import { api } from '../utils/api';

const ThemeContext = createContext();

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

export const ThemeProvider = ({ children }) => {
    const [isDark, setIsDark] = useState(false);
    const [themeKey, setThemeKey] = useState('default');
    const [primary, setPrimary] = useState(DEFAULT_PRIMARY);
    const [secondary, setSecondary] = useState(DEFAULT_SECONDARY);
    const [fontBase, setFontBase] = useState(DEFAULT_FONT_BASE);
    const [fontSmall, setFontSmall] = useState(DEFAULT_FONT_SMALL);
    const [fontLarge, setFontLarge] = useState(DEFAULT_FONT_LARGE);
    const [settingsLoaded, setSettingsLoaded] = useState(false);

    const toggleDark = () => {
        const newDark = !isDark;
        setIsDark(newDark);
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

    // Load settings once (best-effort)
    useEffect(() => {
        let mounted = true;
        const load = async () => {
            try {
                const res = await api.getSettings({
                    keys: [
                        'theme',
                        'theme_color_primary',
                        'theme_color_secondary',
                        'theme_mode',
                        'font_size_base',
                        'font_size_small',
                        'font_size_large',
                    ],
                    scope: 'global',
                });
                const s = res?.settings || {};
                if (!mounted) return;

                if (typeof s.theme === 'string' && themes[s.theme]) setThemeKey(s.theme);
                if (typeof s.theme_color_primary === 'string') setPrimary(s.theme_color_primary);
                if (typeof s.theme_color_secondary === 'string') setSecondary(s.theme_color_secondary);
                if (typeof s.theme_mode === 'string') setIsDark(s.theme_mode === 'dark');

                if (typeof s.font_size_base === 'number') setFontBase(s.font_size_base);
                if (typeof s.font_size_small === 'number') setFontSmall(s.font_size_small);
                if (typeof s.font_size_large === 'number') setFontLarge(s.font_size_large);
            } catch (e) {
                // ignore - defaults will be used
            } finally {
                if (mounted) setSettingsLoaded(true);
            }
        };
        load();
        return () => { mounted = false; };
    }, []);

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
        root.style.setProperty('--font-size-base', `${fontBase}px`);
        root.style.setProperty('--font-size-small', `${fontSmall}px`);
        root.style.setProperty('--font-size-large', `${fontLarge}px`);
    }, [isDark, themeKey, primary, secondary, fontBase, fontSmall, fontLarge]);

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
