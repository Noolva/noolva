import React, { useState } from 'react';
import { Layout } from 'antd';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Header from './components/Header';
import Footer from './components/Footer';
import Sidebar from './components/Sidebar';
import AppTabs from './components/AppTabs';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import ListPage from './pages/ListPage';
import AddForm from './pages/AddForm';
import Settings from './pages/Settings';
import Database from './pages/Database';
import DbQuery from './pages/DbQuery';
import { useAuth } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';

const { Content, Sider } = Layout;

const AppContent = () => {
  const [selectedApp, setSelectedApp] = useState(null);
  const [selectedAppData, setSelectedAppData] = useState(null);
  const [tabs, setTabs] = useState({ activeKey: '', items: [] });

  const addTab = (key, label, content) => {
    if (!tabs.items.some(tab => tab.key === key)) {
      const newItems = [...tabs.items, { key, label, content }];
      setTabs({ activeKey: key, items: newItems });
    } else {
      setTabs({ ...tabs, activeKey: key });
    }
  };

  const removeTab = (targetKey) => {
    let newActiveKey = tabs.activeKey;
    let lastIndex = -1;
    tabs.items.forEach((tab, i) => {
      if (tab.key === targetKey) lastIndex = i - 1;
    });
    const newItems = tabs.items.filter(tab => tab.key !== targetKey);
    if (newItems.length && newActiveKey === targetKey) {
      newActiveKey = newItems[lastIndex >= 0 ? lastIndex : 0]?.key || '';
    }
    setTabs({ activeKey: newActiveKey, items: newItems });
  };

  const renderContent = (key, menuData) => {
    switch (key) {
      case 'overview': return <Dashboard />;
      case 'stats': return <div>Stats Page</div>;
      case 'list': return <ListPage />;
      case 'add': return <AddForm />;
      case 'settings': return <Settings />;
      case 'dev_console_database': return <Database />;
      case 'dev_console_db_query': return <DbQuery />;
      default: {
        // Try to render based on menu title if available
        if (menuData?.menu_title) {
          const title = menuData.menu_title.toLowerCase().replace(/\s+/g, '_');
          if (title === 'database') return <Database />;
          if (title === 'db_query' || title === 'db query') return <DbQuery />;
        }
        return <div>Unknown Page: {key}</div>;
      }
    }
  };

  const handleSubmenuSelect = (key, menuData) => {
    const label = menuData?.menu_title || key.charAt(0).toUpperCase() + key.slice(1);
    addTab(key, label, renderContent(key, menuData));
  };

  const handleAppSelect = (appKey, appData) => {
    setSelectedApp(appKey);
    setSelectedAppData(appData);
    // Clear tabs when switching apps
    setTabs({ activeKey: '', items: [] });
  };

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header onAppSelect={handleAppSelect} onMenuSelect={handleSubmenuSelect} />
      <Layout>
        {selectedApp && (
          <Sider width={200} className="site-layout-background">
            <Sidebar
              selectedApp={selectedApp}
              selectedAppData={selectedAppData}
              onSelect={handleSubmenuSelect}
            />
          </Sider>
        )}
        <Layout style={{ padding: '0 10px 10px' }}>
          <Content style={{ margin: '5px 0' }}>
            <AppTabs tabs={tabs} onChange={(key) => setTabs({ ...tabs, activeKey: key })} onEdit={removeTab} />
          </Content>
          <Footer />
        </Layout>
      </Layout>
    </Layout>
  );
};

const App = () => {
  const { user, loading, initialized } = useAuth();

  // Show loading spinner while initializing
  if (!initialized || loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
        <div>Loading...</div>
      </div>
    );
  }

  return (
    <ThemeProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/*" element={user ? <AppContent /> : <Navigate to="/login" />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
};

export default App;
