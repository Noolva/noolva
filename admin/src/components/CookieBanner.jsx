// src/components/CookieBanner.jsx
import React, { useState, useEffect } from 'react';
import { Alert, Button, Space } from 'antd';

const CookieBanner = () => {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    // Check localStorage to see if user already accepted
    const accepted = localStorage.getItem('cookieAccepted');
    if (!accepted) {
      setVisible(true);
    }
  }, []);

  const acceptCookies = () => {
    localStorage.setItem('cookieAccepted', 'true');
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <Alert
      banner
      showIcon={false}
      style={{
        position: 'fixed',
        bottom: 0,
        width: '100%',
        zIndex: 1001,
        padding: '12px 24px',
        backgroundColor: '#f0f2f5',
        border: '1px solid #d9d9d9',
      }}
      message={
        <Space size="middle">
          <span>
            We use cookies to improve your experience. By continuing, you accept
            our <a href="/cookie-policy" target="_blank" rel="noopener">Cookie Policy</a>.
          </span>
          <Button type="primary" size="small" onClick={acceptCookies}>
            Accept
          </Button>
        </Space>
      }
    />
  );
};

export default CookieBanner;
