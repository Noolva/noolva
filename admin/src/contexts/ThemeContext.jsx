import React, { createContext, useContext, useState, useMemo } from 'react';
import { ConfigProvider, theme as antdTheme } from 'antd';

const ThemeContext = createContext();

export const themes = {
    blue_green: {
        primary: '#1890ff',
        secondary: '#52c41a',
    },
    purple_orange: {
        primary: '#722ed1',
        secondary: '#fa8c16',
    },
    pink_gray: {
        primary: '#eb2f96',
        secondary: '#8c8c8c',
    },
    teal_gold: {
        primary: '#13c2c2',
        secondary: '#faad14',
    },
};

export const ThemeProvider = ({ children }) => {
    const [isDark, setIsDark] = useState(false);
    const [themeKey, setThemeKey] = useState('blue_green');
    const [color, setColor] = useState(themes[themeKey]);

    const toggleDark = () => {
        const newDark = !isDark;
        setIsDark(newDark);
        document.body.setAttribute('data-theme', newDark ? 'dark' : 'light');
    };

    const setPrimarySecondary = (primary, secondary) => {
        setColor({ primary, secondary });
    };

    const selectThemeByKey = (key) => {
        if (themes[key]) {
            setColor(themes[key]);
            setThemeKey(key);
        }
    };

    const theme = useMemo(() => ({
        token: {
            colorPrimary: color.primary,
            colorSuccess: color.secondary,
        },
        algorithm: isDark ? antdTheme.darkAlgorithm : antdTheme.defaultAlgorithm,
    }), [isDark, color]);

    return (
        <ThemeContext.Provider value={{
            isDark,
            toggleDark,
            color,
            themeKey,
            themes,
            setPrimarySecondary,
            selectThemeByKey,
        }}>
            <ConfigProvider theme={theme}>
                {children}
            </ConfigProvider>
        </ThemeContext.Provider>
    );
};

export const useTheme = () => useContext(ThemeContext);
