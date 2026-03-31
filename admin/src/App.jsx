import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Layout } from 'antd';
import { BrowserRouter as Router, Routes, Route, Navigate, useNavigate, useSearchParams } from 'react-router-dom';
import Header from './components/Header';
import Footer from './components/Footer';
import Sidebar from './components/Sidebar';
import AppTabs from './components/AppTabs';
import Login from './pages/Login';
import GoogleOAuthCallback from './pages/GoogleOAuthCallback';
import Dashboard from './pages/Dashboard';
import ListPage from './pages/ListPage';
import AddForm from './pages/AddForm';
import Settings from './pages/Settings';
import ChangePassword from './pages/ChangePassword';
import Themes from './pages/Themes';
import Database from './pages/Database';
import DbQuery from './pages/DbQuery';
import SchedulerWorkers from './pages/SchedulerWorkers';
import JobTemplates from './pages/JobTemplates';
import Jobs from './pages/Jobs';
import Schedulers from './pages/Schedulers';
import FlattenedDatas from './pages/FlattenedDatas';
import DataLifecyclePolicies from './pages/DataLifecyclePolicies';
import DataModels from './pages/DataModels';
import IconExplorer from './pages/IconExplorer';
import Collections from './pages/Collections';
import ApiEndpoints from './pages/ApiEndpoints';
import IntegrationManager from './pages/IntegrationManager';
import OrganizationUsers from './pages/OrganizationUsers';
import PersonalAccessTokens from './pages/PersonalAccessTokens';
import { useAuth } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import ReLoginModal from './components/ReLoginModal';
import IdleTimer from './components/IdleTimer';
import { getAccountIdFromUrl } from './utils/api';

/**
 * Helper component to preserve account parameter when navigating
 */
const NavigateWithAccount = ({ to, ...props }) => {
  const accountId = getAccountIdFromUrl();
  const targetPath = accountId ? `${to}${to.includes('?') ? '&' : '?'}account=${accountId}` : to;
  return <Navigate to={targetPath} {...props} />;
};

const { Content, Sider } = Layout;

const AppContent = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [selectedApp, setSelectedApp] = useState(null);
  const [selectedAppData, setSelectedAppData] = useState(null);
  const [autoHideSidebar, setAutoHideSidebar] = useState(false);
  const [sidebarHoverExpanded, setSidebarHoverExpanded] = useState(false);
  // Store all tabs globally - each tab knows which app it belongs to
  // { activeKey, items: [{ key, label, menuData, appKey, appData }] }
  const [tabs, setTabs] = useState({ activeKey: '', items: [] });

  // Update browser URL when tab changes - preserve account parameter
  const updateURL = useCallback((appKey, tabKey) => {
    const params = new URLSearchParams(window.location.search);
    // Preserve account parameter if it exists
    const accountId = params.get('account');

    // Clear and rebuild params
    params.delete('app');
    params.delete('tab');

    if (appKey) params.set('app', String(appKey));
    if (tabKey) {
      params.set('tab', String(tabKey));
    }
    // Preserve account parameter
    if (accountId) {
      params.set('account', accountId);
    }

    const newURL = `${window.location.pathname}?${params.toString()}`;
    window.history.replaceState({}, '', newURL);
  }, []);

  // Render content for a given key and menu data
  const renderContent = useCallback((key, menuData) => {
    switch (key) {
      case 'overview': return <Dashboard />;
      case 'stats': return <div>Stats Page</div>;
      case 'list': return <ListPage />;
      case 'add': return <AddForm />;
      case 'settings': return <Settings />;
      case 'change_password': return <ChangePassword />;
      case 'themes': return <Themes />;
      case 'dev_console_database': return <Database />;
      case 'dev_console_db_query': return <DbQuery />;
      case 'dev_console_scheduler_workers': return <SchedulerWorkers />;
      case 'dev_console_job_templates': return <JobTemplates />;
      case 'dev_console_jobs': return <Jobs />;
      case 'dev_console_schedulers': return <Schedulers />;
      case 'dev_console_flattened_datas': return <FlattenedDatas />;
      case 'dev_console_data_lifecycle': return <DataLifecyclePolicies />;
      case 'studio_data_models': return <DataModels />;
      case 'data_models': return <DataModels />;
      case 'studio_icons': return <IconExplorer />;
      case 'studio_collections': return <Collections />;
      case 'studio_api_endpoints': return <ApiEndpoints />;
      case 'studio_integrations': return <IntegrationManager />;
      case 'studio_asset_gallery': return <IconExplorer />;
      case 'org_users': return <OrganizationUsers />;
      case 'personal_access_tokens': return <PersonalAccessTokens />;
      default: {
        // Try to match by route_path from menuData (since key might be menu_id)
        if (menuData?.route_path) {
          const routePath = menuData.route_path;
          if (routePath === 'dev_console_database') return <Database />;
          if (routePath === 'dev_console_db_query') return <DbQuery />;
          if (routePath === 'dev_console_scheduler_workers') return <SchedulerWorkers />;
          if (routePath === 'dev_console_job_templates') return <JobTemplates />;
          if (routePath === 'dev_console_jobs') return <Jobs />;
          if (routePath === 'dev_console_schedulers') return <Schedulers />;
          if (routePath === 'dev_console_flattened_datas') return <FlattenedDatas />;
          if (routePath === 'dev_console_data_lifecycle') return <DataLifecyclePolicies />;
          if (routePath === 'studio_data_models' || routePath === 'data_models') return <DataModels />;
          if (routePath === 'studio_icons') return <IconExplorer />;
          if (routePath === 'studio_collections') return <Collections />;
          if (routePath === 'studio_api_endpoints') return <ApiEndpoints />;
          if (routePath === 'studio_integrations') return <IntegrationManager />;
          if (routePath === 'studio_asset_gallery') return <IconExplorer />;
          if (routePath === 'settings') return <Settings />;
          if (routePath === 'change_password') return <ChangePassword />;
          if (routePath === 'themes') return <Themes />;
          if (routePath === 'org_users') return <OrganizationUsers />;
          if (routePath === 'personal_access_tokens') return <PersonalAccessTokens />;
        }
        // Try to render based on menu title if available
        if (menuData?.menu_title) {
          const title = menuData.menu_title.toLowerCase().replace(/\s+/g, '_');
          if (title === 'database') return <Database />;
          if (title === 'db_query' || title === 'db query') return <DbQuery />;
          if (title === 'icons') return <IconExplorer />;
          // Settings parent row (submenu) has no route_path; old tabs may still use this menu_id
          if (title === 'settings') return <Settings />;
        }
        return <div>Unknown Page: {key}</div>;
      }
    }
  }, []);

  // Update URL when tab changes
  const updateTabs = useCallback((newTabs) => {
    setTabs(newTabs);
    // Update URL when tabs change
    if (newTabs.activeKey) {
      const activeTab = newTabs.items.find(tab => tab.key === newTabs.activeKey);
      if (activeTab && activeTab.appKey) {
        updateURL(activeTab.appKey, newTabs.activeKey);
      }
    } else {
      // No active tab, clear tab from URL but keep app
      const params = new URLSearchParams();
      if (selectedApp) params.set('app', selectedApp);
      const newURL = `${window.location.pathname}?${params.toString()}`;
      window.history.replaceState({}, '', newURL);
    }
  }, [selectedApp, updateURL]);

  const addTab = useCallback((key, label, menuData, appKey = null, appData = null) => {
    const currentAppKey = appKey || selectedApp;
    const currentAppData = appData || selectedAppData;

    if (!tabs.items.some(tab => tab.key === key)) {
      const newItems = [...tabs.items, { key, label, menuData, appKey: currentAppKey, appData: currentAppData }];
      const newTabs = { activeKey: key, items: newItems };
      updateTabs(newTabs);
    } else {
      const newTabs = { ...tabs, activeKey: key };
      updateTabs(newTabs);
      // Switch app/sidebar to match the tab's app
      const tab = tabs.items.find(tab => tab.key === key);
      if (tab && tab.appKey && tab.appKey !== selectedApp) {
        setSelectedApp(tab.appKey);
        setSelectedAppData(tab.appData);
      }
    }
  }, [selectedApp, selectedAppData, tabs, updateTabs]);

  const removeTab = useCallback((targetKey) => {
    let newActiveKey = tabs.activeKey;
    let lastIndex = -1;
    tabs.items.forEach((tab, i) => {
      if (tab.key === targetKey) lastIndex = i - 1;
    });
    const newItems = tabs.items.filter(tab => tab.key !== targetKey);
    // Allow closing all tabs - if no tabs left, set empty
    if (newItems.length && newActiveKey === targetKey) {
      newActiveKey = newItems[lastIndex >= 0 ? lastIndex : 0]?.key || '';
    } else if (newItems.length === 0) {
      newActiveKey = '';
    }
    const newTabs = { activeKey: newActiveKey, items: newItems };
    updateTabs(newTabs);

    // If we closed the active tab and there's a new active tab, switch to its app
    if (newActiveKey) {
      const newActiveTab = newItems.find(tab => tab.key === newActiveKey);
      if (newActiveTab && newActiveTab.appKey && newActiveTab.appKey !== selectedApp) {
        setSelectedApp(newActiveTab.appKey);
        setSelectedAppData(newActiveTab.appData);
      }
    }
  }, [selectedApp, tabs, updateTabs]);

  const duplicateTab = useCallback((targetKey) => {
    const tabToDuplicate = tabs.items.find(tab => tab.key === targetKey);
    if (tabToDuplicate) {
      // Find all existing duplicates to determine the next number
      const baseLabel = tabToDuplicate.label.replace(/\s*\(\d+\)$/, ''); // Remove existing number suffix
      const duplicatePattern = new RegExp(`^${baseLabel.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s*\\(\\d+\\)$`);
      const existingDuplicates = tabs.items.filter(tab =>
        duplicatePattern.test(tab.label) || tab.label === baseLabel
      );

      // Find the highest number used
      let maxNumber = 0;
      existingDuplicates.forEach(tab => {
        const match = tab.label.match(/\((\d+)\)$/);
        if (match) {
          maxNumber = Math.max(maxNumber, parseInt(match[1], 10));
        } else if (tab.label === baseLabel) {
          maxNumber = Math.max(maxNumber, 0); // Original counts as (0) or base
        }
      });

      const nextNumber = maxNumber + 1;
      const newKey = `${targetKey}_${nextNumber}_${Date.now()}`;
      const newLabel = `${baseLabel} (${nextNumber})`;

      // Store menuData and app info so content can be re-rendered
      addTab(newKey, newLabel, tabToDuplicate.menuData, tabToDuplicate.appKey, tabToDuplicate.appData);
    }
  }, [tabs, addTab]);

  const closeAllTabs = useCallback(() => {
    updateTabs({ activeKey: '', items: [] });
  }, [updateTabs]);

  const closeLeftTabs = useCallback((targetKey) => {
    const targetIndex = tabs.items.findIndex(tab => tab.key === targetKey);
    if (targetIndex > 0) {
      const newItems = tabs.items.slice(targetIndex);
      const newTabs = {
        activeKey: tabs.activeKey === targetKey ? targetKey : tabs.activeKey,
        items: newItems
      };
      updateTabs(newTabs);
    }
  }, [tabs, updateTabs]);

  const closeRightTabs = useCallback((targetKey) => {
    const targetIndex = tabs.items.findIndex(tab => tab.key === targetKey);
    if (targetIndex >= 0 && targetIndex < tabs.items.length - 1) {
      const newItems = tabs.items.slice(0, targetIndex + 1);
      const newTabs = {
        activeKey: tabs.activeKey === targetKey ? targetKey : tabs.activeKey,
        items: newItems
      };
      updateTabs(newTabs);
    }
  }, [tabs, updateTabs]);

  const closeOtherTabs = useCallback((targetKey) => {
    const tabToKeep = tabs.items.find(tab => tab.key === targetKey);
    if (tabToKeep) {
      updateTabs({ activeKey: targetKey, items: [tabToKeep] });
      // Switch to the kept tab's app
      if (tabToKeep.appKey && tabToKeep.appKey !== selectedApp) {
        setSelectedApp(tabToKeep.appKey);
        setSelectedAppData(tabToKeep.appData);
      }
    }
  }, [selectedApp, tabs, updateTabs]);

  const openInNewBrowserTab = useCallback((targetKey) => {
    const tab = tabs.items.find(tab => tab.key === targetKey);
    if (tab && tab.appKey) {
      // Use URLSearchParams to properly handle encoding (menu_id should be clean)
      const params = new URLSearchParams();
      params.set('app', String(tab.appKey));
      params.set('tab', String(targetKey));
      // Preserve account parameter from current URL
      const currentAccountId = getAccountIdFromUrl();
      if (currentAccountId) {
        params.set('account', currentAccountId);
      }
      const url = `${window.location.origin}${window.location.pathname}?${params.toString()}`;
      window.open(url, '_blank');
    }
  }, [tabs]);

  const handleSubmenuSelect = useCallback((key, menuData) => {
    const label = menuData?.menu_title || key.charAt(0).toUpperCase() + key.slice(1);
    addTab(key, label, menuData, selectedApp, selectedAppData);
  }, [addTab, selectedApp, selectedAppData]);

  const handleAppSelect = useCallback((appKey, appData) => {
    setSelectedApp(appKey);
    setSelectedAppData(appData);
    // Don't clear tabs - they persist globally
    // When switching apps, check if there's an active tab from the new app
    // If yes, keep it active. If no, just update URL with the new app
    if (tabs.activeKey) {
      const activeTab = tabs.items.find(tab => tab.key === tabs.activeKey);
      // If active tab belongs to the new app, keep it active
      if (activeTab && activeTab.appKey === appKey) {
        updateURL(appKey, tabs.activeKey);
      } else {
        // Active tab is from different app, just switch app (no tab in URL)
        updateURL(appKey, '');
      }
    } else {
      // No active tab, just update URL with new app
      updateURL(appKey, '');
    }
  }, [tabs, updateURL]);

  const handleTabChange = useCallback((key) => {
    const newTabs = { ...tabs, activeKey: key };
    updateTabs(newTabs);

    // Switch app/sidebar to match the tab's app
    const tab = tabs.items.find(tab => tab.key === key);
    if (tab && tab.appKey && tab.appKey !== selectedApp) {
      setSelectedApp(tab.appKey);
      setSelectedAppData(tab.appData);
    }
  }, [selectedApp, tabs, updateTabs]);

  // Initialize from URL - fetch apps and load app/tab from URL
  const [apps, setApps] = useState([]);
  const [appsLoaded, setAppsLoaded] = useState(false);
  const [menusByApp, setMenusByApp] = useState({});
  const [urlInitialized, setUrlInitialized] = useState(false);

  useEffect(() => {
    const fetchApps = async () => {
      try {
        const { api } = await import('./utils/api');
        const response = await api.getApps();
        setApps(response.apps || []);
        setAppsLoaded(true);
      } catch (error) {
        console.error('Failed to fetch apps:', error);
        setApps([]);
        setAppsLoaded(true);
      }
    };
    fetchApps();
  }, []);

  // Load "Auto Hide Sidebar" setting for layout
  useEffect(() => {
    let mounted = true;
    const load = async () => {
      try {
        const { api } = await import('./utils/api');
        const res = await api.getSettings({ keys: 'auto_hide_sidebar', scope: 'global' });
        const val = res?.settings?.auto_hide_sidebar;
        if (mounted) setAutoHideSidebar(val === true || val === 'true' || val === 'yes');
      } catch (e) {
        // ignore
      }
    };
    load();
    return () => { mounted = false; };
  }, []);

  // Update auto_hide_sidebar (persist to settings and local state)
  const updateAutoHideSidebar = useCallback(async (value) => {
    setAutoHideSidebar(!!value);
    try {
      const { api } = await import('./utils/api');
      await api.updateSettings({ scope: 'global', settings: { auto_hide_sidebar: !!value } });
    } catch (e) {
      console.warn('Failed to persist auto_hide_sidebar', e);
    }
  }, []);

  // Initialize from URL after apps are loaded
  useEffect(() => {
    if (!appsLoaded) return;

    const appFromURL = searchParams.get('app');
    const tabFromURL = searchParams.get('tab');

    if (appFromURL && !selectedApp) {
      // Find the app from URL - handle both string and number comparison
      const appData = apps.find(app => {
        const appKey = app.app_id || app.app_uuid || app.app_name;
        // Compare as strings to handle both "5" and 5
        return String(appKey) === String(appFromURL) || appKey === appFromURL;
      });

      if (appData) {
        const appKey = appData.app_id || appData.app_uuid || appData.app_name;
        setSelectedApp(appKey);
        setSelectedAppData(appData);

        setUrlInitialized(true);
      } else {
        setUrlInitialized(true);
      }
    } else {
      setUrlInitialized(true);
    }
  }, [appsLoaded, apps, searchParams, selectedApp, urlInitialized]);

  // Fetch menus when app is selected
  useEffect(() => {
    if (!selectedApp || !selectedAppData) return;

    const fetchMenus = async () => {
      try {
        const { api } = await import('./utils/api');
        const appId = selectedAppData.app_id || selectedApp;
        const response = await api.getMenusForApp(appId);
        const menusList = Array.isArray(response) ? response : (response?.menus || response?.data || []);
        setMenusByApp(prev => ({
          ...prev,
          [selectedApp]: menusList
        }));
      } catch (error) {
        console.error('Failed to fetch menus:', error);
        setMenusByApp(prev => ({
          ...prev,
          [selectedApp]: []
        }));
      }
    };

    fetchMenus();
  }, [selectedApp, selectedAppData]);

  // Track which URL tab we've already synced to avoid re-running when our own updateTabs/addTab updates state
  const urlTabSyncedRef = useRef(null);

  // Create/activate tab from URL after menus are loaded
  useEffect(() => {
    if (!selectedApp || !urlInitialized) return;

    const tabFromURL = searchParams.get('tab');
    if (!tabFromURL) return;

    const syncKey = `${selectedApp}-${tabFromURL}`;
    if (urlTabSyncedRef.current === syncKey) return;

    // Decode URL if it was encoded
    const decodedTabKey = decodeURIComponent(tabFromURL);
    const appKey = selectedAppData?.app_id || selectedAppData?.app_uuid || selectedAppData?.app_name || selectedApp;
    const menus = menusByApp[appKey] || [];

    // Check if tab already exists globally
    const existingTab = tabs.items.find(tab => tab.key === decodedTabKey || tab.key === tabFromURL);
    if (existingTab) {
      // Tab exists, just activate it and switch to its app
      if (tabs.activeKey !== existingTab.key) {
        const newTabs = { ...tabs, activeKey: existingTab.key };
        updateTabs(newTabs);
      }
      urlTabSyncedRef.current = syncKey;
      if (existingTab.appKey && existingTab.appKey !== selectedApp) {
        setSelectedApp(existingTab.appKey);
        setSelectedAppData(existingTab.appData);
      }
    } else {
      // Tab doesn't exist - find menu data and create it
      if (menus.length === 0) return; // wait for menus to load, don't set ref so we retry when menusByApp updates

      const menuData = menus.find(menu => {
        const menuId = String(menu.menu_id || '');
        const menuUuid = String(menu.menu_uuid || '');
        const routePath = String(menu.route_path || '');
        const menuTitle = menu.menu_title?.toLowerCase().replace(/\s+/g, '_') || '';

        return menuId === decodedTabKey || menuId === tabFromURL ||
          menuUuid === decodedTabKey || menuUuid === tabFromURL ||
          routePath === decodedTabKey || routePath === tabFromURL ||
          menuTitle === decodedTabKey.toLowerCase() || menuTitle === tabFromURL.toLowerCase();
      });

      if (menuData) {
        const tabKey = menuData.menu_id || menuData.menu_uuid || decodedTabKey;
        const label = menuData.menu_title || decodedTabKey.charAt(0).toUpperCase() + decodedTabKey.slice(1).replace(/_/g, ' ');
        addTab(tabKey, label, menuData, appKey, selectedAppData);
      } else {
        const label = decodedTabKey.charAt(0).toUpperCase() + decodedTabKey.slice(1).replace(/_/g, ' ');
        addTab(decodedTabKey, label, null, appKey, selectedAppData);
      }
      urlTabSyncedRef.current = syncKey;
    }
  }, [selectedApp, selectedAppData, urlInitialized, searchParams, menusByApp, tabs, updateTabs, addTab]);

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header onAppSelect={handleAppSelect} onMenuSelect={handleSubmenuSelect} />
      <Layout>
        <div
          onMouseEnter={selectedApp && autoHideSidebar ? () => setSidebarHoverExpanded(true) : undefined}
          onMouseLeave={selectedApp && autoHideSidebar ? () => setSidebarHoverExpanded(false) : undefined}
          style={{ position: 'relative' }}
        >
          <Sider
            width={selectedApp ? 200 : 0}
            collapsed={selectedApp && autoHideSidebar ? !sidebarHoverExpanded : false}
            collapsedWidth={selectedApp ? 48 : 0}
            className="site-layout-background app-sidebar"
            style={{
              transition: 'width 0.2s ease-in-out, min-width 0.2s ease-in-out',
              overflow: 'hidden',
              background: 'var(--sidebar-bg-color, var(--primary-color, #001529))'
            }}
          >
            {selectedApp && (
              <Sidebar
                selectedApp={selectedApp}
                selectedAppData={selectedAppData}
                onSelect={handleSubmenuSelect}
                autoHideSidebar={autoHideSidebar}
                onAutoHideSidebarChange={updateAutoHideSidebar}
                collapsed={selectedApp && autoHideSidebar ? !sidebarHoverExpanded : false}
              />
            )}
          </Sider>
        </div>
        <Layout style={{ padding: '0 10px 10px' }}>
          <Content style={{ margin: '5px 0' }}>
            <AppTabs
              tabs={tabs}
              renderContent={renderContent}
              onChange={handleTabChange}
              onEdit={removeTab}
              onDuplicate={duplicateTab}
              onCloseAll={closeAllTabs}
              onCloseLeft={closeLeftTabs}
              onCloseRight={closeRightTabs}
              onCloseOthers={closeOtherTabs}
              onOpenInNewTab={openInNewBrowserTab}
            />
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
          <Route path="/oauth/google-callback" element={<GoogleOAuthCallback />} />
          <Route path="/*" element={user ? <><IdleTimer /><AppContent /><ReLoginModal /></> : <NavigateWithAccount to="/login" />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
};

export default App;
