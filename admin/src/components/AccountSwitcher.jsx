import React, { useState } from 'react';
import { Dropdown, Avatar, Typography, Button, Space, Divider } from 'antd';
import { UserOutlined, LogoutOutlined, SwapOutlined, DeleteOutlined, PlusOutlined } from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';

const { Text } = Typography;

const AccountSwitcher = () => {
    const { user, accounts, currentAccount, switchAccount, removeAccount, logout } = useAuth();
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);

    const handleSwitchAccount = async (account) => {
        if (account.id === currentAccount?.id) return;
        
        setLoading(true);
        try {
            await switchAccount(account);
        } finally {
            setLoading(false);
        }
    };

    const handleRemoveAccount = async (account, e) => {
        e.stopPropagation();
        await removeAccount(account.id);
    };

    const handleLogout = async () => {
        await logout();
        navigate('/login');
    };

    const menuItems = [
        {
            key: 'current',
            label: (
                <div style={{ padding: '8px 0' }}>
                    <Text strong>Current Account</Text>
                    <br />
                    <Text type="secondary" style={{ fontSize: '12px' }}>
                        {currentAccount?.username}
                    </Text>
                    {currentAccount?.companyName && (
                        <>
                            <br />
                            <Text type="secondary" style={{ fontSize: '12px' }}>
                                {currentAccount.companyName}
                            </Text>
                        </>
                    )}
                </div>
            ),
            disabled: true,
        },
        {
            type: 'divider',
        },
    ];

    // Add other accounts
    accounts
        .filter(acc => acc.id !== currentAccount?.id)
        .forEach((account) => {
            menuItems.push({
                key: `account-${account.id}`,
                label: (
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                            <Text>{account.username}</Text>
                            {account.companyName && (
                                <div>
                                    <Text type="secondary" style={{ fontSize: '12px' }}>
                                        {account.companyName}
                                    </Text>
                                </div>
                            )}
                        </div>
                        <Button
                            type="text"
                            size="small"
                            icon={<DeleteOutlined />}
                            danger
                            onClick={(e) => handleRemoveAccount(account, e)}
                            style={{ marginLeft: '8px' }}
                        />
                    </div>
                ),
                onClick: () => handleSwitchAccount(account),
                icon: <SwapOutlined />,
            });
        });

    if (accounts.length > 1 || currentAccount) {
        menuItems.push({
            type: 'divider',
        });
    }

    // Add "Add Account" option
    menuItems.push({
        key: 'add-account',
        label: 'Add Account',
        icon: <PlusOutlined />,
        onClick: () => {
            navigate('/login');
        },
    });

    menuItems.push({
        type: 'divider',
    });

    menuItems.push({
        key: 'logout',
        label: 'Logout',
        icon: <LogoutOutlined />,
        danger: true,
        onClick: handleLogout,
    });

    return (
        <Dropdown
            menu={{ items: menuItems }}
            placement="bottomRight"
            trigger={['click']}
            arrow
        >
            <Space style={{ cursor: 'pointer' }}>
                <Avatar 
                    icon={<UserOutlined />}
                    src={user?.avatar_url}
                    style={{ backgroundColor: '#1890ff' }}
                >
                    {currentAccount?.username?.charAt(0).toUpperCase()}
                </Avatar>
                <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.2 }}>
                    <Text strong style={{ fontSize: '14px' }}>
                        {user?.first_name && user?.last_name 
                            ? `${user.first_name} ${user.last_name}` 
                            : user?.username || 'User'}
                    </Text>
                    {currentAccount?.companyName && (
                        <Text type="secondary" style={{ fontSize: '12px' }}>
                            {currentAccount.companyName}
                        </Text>
                    )}
                </div>
            </Space>
        </Dropdown>
    );
};

export default AccountSwitcher;
