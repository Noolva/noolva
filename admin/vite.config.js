import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { readFileSync } from 'node:fs'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const __dirname = dirname(fileURLToPath(import.meta.url))
const pkg = JSON.parse(readFileSync(join(__dirname, 'package.json'), 'utf-8'))

function shortGitSha() {
  if (process.env.CI_COMMIT_SHORT_SHA) return process.env.CI_COMMIT_SHORT_SHA
  try {
    return execSync('git rev-parse --short HEAD', { encoding: 'utf-8' }).trim()
  } catch {
    return ''
  }
}

// https://vite.dev/config/
export default defineConfig({
  base: '/console/',
  define: {
    __APP_VERSION__: JSON.stringify(pkg.version),
    __GIT_SHA__: JSON.stringify(shortGitSha()),
  },
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
