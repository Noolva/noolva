import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  server: {
    host: "::",
    port: 3000,
    proxy: {
      // All JSON API routes are under /api on the backend
      '/api': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      '/assets': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
      // Use /app/ (trailing slash) so /app_icons/* is not proxied and is served from public/app_icons
      '/app/': {
        target: 'http://localhost:9001',
        changeOrigin: true,
      },
    },
  },
  plugins: [react()],
})
