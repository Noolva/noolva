import React, { useState, useEffect } from 'react';
import {
    Layout,
    Input,
    Switch,
    Dropdown,
    Avatar,
    Badge,
    Drawer,
    Space,
    Select,
    Spin
} from 'antd';
import {
    UserOutlined,
    SearchOutlined,
    AppstoreOutlined,
    BellOutlined,
    ShopOutlined,
    DownOutlined,
    BgColorsOutlined
} from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';
import { api } from '../utils/api';
import './Header.css';
import { useTheme } from '../contexts/ThemeContext';
import { useToken } from 'antd/es/theme/internal';
import CookieBanner from './CookieBanner';
import AccountSwitcher from './AccountSwitcher';
const { Header: AntHeader } = Layout;

const Header = ({ onAppSelect }) => {
    const [dropdownOpen, setDropdownOpen] = useState(false);
    const { Option } = Select;
    const NineDotIcon = ({ size = 24, color = 'white', onClick }) => (
        <svg
            width={size}
            height={size}
            viewBox="0 0 24 24"
            fill={color}
            xmlns="http://www.w3.org/2000/svg"
            onClick={onClick}
            style={{ cursor: 'pointer' }}
        >
            {[0, 1, 2].flatMap((row) =>
                [0, 1, 2].map((col) => (
                    <circle
                        key={`${row}-${col}`}
                        cx={4 + col * 8}
                        cy={4 + row * 8}
                        r="2"
                    />
                ))
            )}
        </svg>
    );
    const [apps, setApps] = useState([]);
    const [appsLoading, setAppsLoading] = useState(true);

    // Fetch apps on component mount
    useEffect(() => {
        const fetchApps = async () => {
            try {
                setAppsLoading(true);
                const response = await api.getApps();
                setApps(response.apps || []);
            } catch (error) {
                console.error('Failed to fetch apps:', error);
                setApps([]);
            } finally {
                setAppsLoading(false);
            }
        };
        fetchApps();
    }, []);

    const AppGridMenu = ({ onAppSelect, closeDropdown }) => {
        const { isDark, color } = useTheme();

        const background = isDark ? '#1f1f1f' : '#fff';
        const textColor = isDark ? '#fff' : '#000';
        const boxShadow = isDark
            ? '0 2px 8px rgba(0,0,0,0.65)'
            : '0 2px 8px rgba(0,0,0,0.15)';

        if (appsLoading) {
            return (
                <div style={{ padding: 20, textAlign: 'center', background, borderRadius: 8, boxShadow }}>
                    <Spin size="small" />
                </div>
            );
        }

        if (apps.length === 0) {
            return (
                <div style={{ padding: 20, textAlign: 'center', background, borderRadius: 8, boxShadow, color: textColor }}>
                    No apps available
                </div>
            );
        }

        return (
            <div
                style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(3, 80px)',
                    gap: 12,
                    padding: 12,
                    background: background,
                    borderRadius: 8,
                    boxShadow: boxShadow,
                }}
            >
                {apps.map(app => {
                    // Use app_image_url from database, or fallback to local path
                    const iconUrl = app.app_image_url || `/app_icons/${app.app_name || app.app_id}.png`;
                    const appKey = app.app_id || app.app_uuid || app.app_name;
                    const appTitle = app.app_title || app.app_name || 'Untitled';

                    return (
                        <div
                            key={appKey}
                            style={{
                                display: 'flex',
                                flexDirection: 'column',
                                alignItems: 'center',
                                textAlign: 'center',
                                cursor: 'pointer',
                                transition: 'all 0.2s',
                            }}
                            onClick={() => {
                                onAppSelect(appKey, app);
                                closeDropdown(); // close when selected
                            }}
                            onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.05)'}
                            onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
                        >
                            <img
                                src={iconUrl}
                                alt={appTitle}
                                width={40}
                                height={40}
                                style={{ borderRadius: 6 }}
                                onError={(e) => {
                                    // Fallback to default icon if image fails to load
                                    e.target.src = '/app_icons/default.png';
                                }}
                            />
                            <span style={{ marginTop: 6, fontSize: 12, color: textColor }}>
                                {appTitle}
                            </span>
                        </div>
                    );
                })}
            </div>
        );
    };
    const AppGridMenuDropdown = (
        <AppGridMenu
            onAppSelect={onAppSelect}
            closeDropdown={() => setDropdownOpen(false)}
        />
    );
    const companies = [
        { key: 'company_a', label: 'Company A' },
        { key: 'company_b', label: 'Company B' },
        { key: 'company_c', label: 'Company C' },
    ];
    const languageItems = [
        {
            key: 'en',
            label: 'English',
        },
        {
            key: 'ta',
            label: 'Tamil',
        },
        {
            key: 'hi',
            label: 'Hindi',
        },
        {
            key: 'ml',
            label: 'Malayalam',
        },
    ];

    const {
        isDark,
        toggleDark,
        themeKey,
        themes,
        selectThemeByKey,
        color
    } = useTheme();

    const colorThemes = Object.keys(themes); // Corrected
    const handleLanguageSelect = ({ key }) => {
        console.log('Selected language:', key);
        // Add your logic to change language here
    };
    const toggleTheme = (checked) => {
        toggleDark(); // Properly toggle dark mode
        document.body.setAttribute('data-theme', checked ? 'dark' : 'light');
    };
    useEffect(() => {
        const root = document.body;
        root.setAttribute('data-theme', isDark ? 'dark' : 'light');
        root.style.setProperty('--primary-color', color.primary);
        root.style.setProperty('--secondary-color', color.secondary);
    }, [isDark, color]);
    const colorDropdownItems = colorThemes.map((key) => ({
        key,
        label: (
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div
                    style={{
                        width: 16,
                        height: 16,
                        borderRadius: '50%',
                        backgroundColor: themes[key].primary,
                        border: '1px solid #ddd',
                    }}
                />
                <div
                    style={{
                        width: 16,
                        height: 16,
                        borderRadius: '50%',
                        backgroundColor: themes[key].secondary,
                        border: '1px solid #ddd',
                    }}
                />
                <span>{key.replace(/_/g, ' ')}</span> {/* ✅ Wrap string in a span */}
            </div>
        ),
    }));



    const handleColorSelect = ({ key }) => {

        selectThemeByKey(key);
    };

    return (
        <>
            <AntHeader className="header">
                <div className="header-left">

                    <ShopOutlined className="icon" />
                    <span className="brand-name">MyCompany</span>
                </div>

                <div className="header-middle">
                    <Dropdown
                        overlay={AppGridMenuDropdown}
                        trigger={['click']}
                        placement="bottomLeft"
                        open={dropdownOpen}
                        onOpenChange={(flag) => setDropdownOpen(flag)}
                        overlayStyle={{ marginTop: -4 }} // Adjust the popup dropdown position slightly upward
                    >
                        <div
                            style={{
                                cursor: 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                height: '100%', // aligns it with header height
                            }}
                        >
                            <NineDotIcon size={25} color="white" />
                        </div>
                    </Dropdown>

                    <Input
                        style={{ width: 300, height: 32 }}
                        className="search-bar"
                        prefix={<SearchOutlined />}
                        placeholder="Search..."
                    />

                </div>

                <div className="header-right">
                    <Select
                        showSearch
                        style={{ width: 200 }}
                        placeholder="Select a company"
                        optionFilterProp="children"
                        filterOption={(input, option) =>
                            option.children.toLowerCase().includes(input.toLowerCase())
                        }
                    >
                        {companies.map((company) => (
                            <Option key={company.key} value={company.key}>
                                {company.label}
                            </Option>
                        ))}
                    </Select>
                    <Switch
                        className="theme-switch"
                        checked={isDark}
                        onChange={toggleTheme}
                        checkedChildren="🌙"
                        unCheckedChildren="☀️"
                    />

                    <Dropdown menu={{ items: colorDropdownItems, onClick: handleColorSelect }} trigger={['click']}>
                        <Space> <i className="fas fa-adjust" style={{ color: 'white' }}></i>
                            {/*  <DownOutlined /> */}
                        </Space>
                    </Dropdown>

                    <Dropdown menu={{ items: languageItems, onClick: handleLanguageSelect }} trigger={['click']}>
                        <Space style={{ cursor: 'pointer' }}>
                            <i className="fas fa-language" style={{ color: 'white' }}></i>
                            {/*  <DownOutlined style={{ color: 'white' }} /> */}
                        </Space>
                    </Dropdown>


                    <Badge count={3}>
                        <BellOutlined className="icon" />
                    </Badge>

                    <AccountSwitcher />
                </div>
            </AntHeader >
            <CookieBanner />


        </>
    );
};

export default Header;