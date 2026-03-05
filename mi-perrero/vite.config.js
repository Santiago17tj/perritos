import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico'],
      manifest: {
        name: 'Mi Perrero',
        short_name: 'Perrero',
        description: 'Contabilidad de perros calientes',
        theme_color: '#c0392b',
        background_color: '#1a0a00',
        display: 'standalone',
        icons: [
          {
            src: 'https://api.iconify.design/twemoji:hot-dog.svg',
            sizes: '192x192',
            type: 'image/svg+xml'
          },
          {
            src: 'https://api.iconify.design/twemoji:hot-dog.svg',
            sizes: '512x512',
            type: 'image/svg+xml'
          }
        ]
      }
    })
  ],
})
