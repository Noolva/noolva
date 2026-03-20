import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  server: {
    host: "::",
    port: 3000,
    proxy: {
      '/auth': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      '/config': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      '/schedulers': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      '/jobs': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      '/job-templates': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      '/workers': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      // Use /app/ (trailing slash) so /app_icons/* is not proxied and is served from public/app_icons
      '/app/': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      '/integrations': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      '/menus': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
    },
  },
  plugins: [react()],
})
