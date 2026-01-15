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
      '/app': {
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
