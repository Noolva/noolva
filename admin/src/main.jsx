import React from 'react';
import ReactDOM from 'react-dom/client';
import { App as AntApp } from 'antd';
import App from './App';
import { AuthProvider } from './contexts/AuthContext';
import { loadRuntimeConfig } from './bootstrapRuntime';
import { APP_VERSION, GIT_SHA } from './buildInfo';
import { NOOLVA_CONSOLE } from './branding';
import 'antd/dist/reset.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
import './index.css';

async function start() {
  await loadRuntimeConfig();
  if (typeof window !== 'undefined') {
    window.__NOOLVA_BUILD__ = { version: APP_VERSION, gitSha: GIT_SHA };
    document.title = NOOLVA_CONSOLE;
  }
  ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
      <AntApp>
        <AuthProvider>
          <App />
        </AuthProvider>
      </AntApp>
    </React.StrictMode>
  );
}

start().catch((err) => {
  console.error('App bootstrap failed:', err);
});