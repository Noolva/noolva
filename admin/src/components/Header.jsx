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
    BgColorsOutlined,
    BulbOutlined,
    BulbFilled
} from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';
import { api } from '../utils/api';
import './Header.css';
import { useTheme } from '../contexts/ThemeContext';
import { useToken } from 'antd/es/theme/internal';
import CookieBanner from './CookieBanner';
import AccountSwitcher from './AccountSwitcher';
import { SettingOutlined } from '@ant-design/icons';
const { Header: AntHeader } = Layout;

const Header = ({ onAppSelect, onMenuSelect }) => {
    const [dropdownOpen, setDropdownOpen] = useState(false);
    const { currentAccount } = useAuth();
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

    // Fetch apps on mount and whenever account changes (so 9-dot menu shows correct apps)
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
        setDropdownOpen(false); // close dropdown when account changes
    }, [currentAccount?.id]);

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
                    // Use app_image_url from DB. If it's a relative "/assets/..." path, prefix API base URL.
                    const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:9001';
                    const raw = app.app_image_url;
                    const iconUrl =
                        raw
                            ? (raw.startsWith('http://') || raw.startsWith('https://')
                                ? raw
                                : `${apiBaseUrl}${raw}`)
                            : `/app_icons/${app.app_name || app.app_id}.png`;
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

    const { isDark, toggleDark, primary, secondary } = useTheme();
    const handleLanguageSelect = ({ key }) => {
        console.log('Selected language:', key);
        // Add your logic to change language here
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
                        key={currentAccount?.id ?? 'no-account'}
                        popupRender={() => (
                            <AppGridMenu
                                onAppSelect={onAppSelect}
                                closeDropdown={() => setDropdownOpen(false)}
                            />
                        )}
                        trigger={['click']}
                        placement="bottomLeft"
                        open={dropdownOpen}
                        onOpenChange={(flag) => setDropdownOpen(flag)}
                        classNames={{ root: 'header-apps-dropdown-overlay' }}
                        styles={{ root: { marginTop: -4, zIndex: 10001 } }}
                    >
                        <div
                            role="button"
                            tabIndex={0}
                            aria-haspopup="menu"
                            aria-expanded={dropdownOpen}
                            style={{
                                cursor: 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                height: '100%',
                                outline: 'none',
                            }}
                            onClick={(e) => {
                                e.preventDefault();
                                e.stopPropagation();
                                setDropdownOpen(true);
                            }}
                            onKeyDown={(e) => {
                                if (e.key === 'Enter' || e.key === ' ') {
                                    e.preventDefault();
                                    setDropdownOpen(true);
                                }
                            }}
                        >
                            <NineDotIcon size={22} color="currentColor" />
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
                    <Space
                        style={{ cursor: 'pointer' }}
                        onClick={toggleDark}
                        title={isDark ? 'Switch to Light' : 'Switch to Dark'}
                    >
                        {isDark ? (<BulbOutlined className="icon" />) : (<BulbFilled className="icon" />)}
                    </Space>
                    <Space
                        style={{ cursor: 'pointer' }}
                        onClick={() => onMenuSelect?.('settings')}
                        title="Settings"
                    >
                        <SettingOutlined className="icon" />
                    </Space>

                    <Dropdown menu={{ items: languageItems, onClick: handleLanguageSelect }} trigger={['click']}>
                        <Space style={{ cursor: 'pointer' }}>
                            <i className="fas fa-language" style={{ color: 'currentColor' }}></i>
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