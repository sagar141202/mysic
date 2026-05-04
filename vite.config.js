import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

/**
 * vite.config.js
 *
 * Dev server:  /ytproxy/*  →  https://www.youtube.com/*  (Vite rewrite, dev only)
 * Production:  vercel.json  routes /ytproxy/* → /api/ytproxy
 *              netlify.toml routes /ytproxy/* → netlify function
 *
 * The client always calls /ytproxy/results?search_query=...
 * No env vars needed — the host environment handles routing.
 */
export default defineConfig({
  plugins: [react()],

  server: {
    proxy: {
      '/ytproxy': {
        target: 'https://www.youtube.com',
        changeOrigin: true,
        rewrite: path => path.replace(/^\/ytproxy/, ''),
        configure: (proxy) => {
          proxy.on('proxyRes', (proxyRes) => {
            delete proxyRes.headers['x-frame-options']
            proxyRes.headers['access-control-allow-origin'] = '*'
          })
        },
      },
    },
  },

  build: {
    chunkSizeWarningLimit: 800,
  },
})
