import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  integrations: [react(), tailwind()],
  server: { port: 3000, host: true },
  vite: {
    server: {
      proxy: {
        // garde le préfixe /api, le backend écoute déjà sur /api/*
        '/api': {
          target: 'http://localhost:8000',
          changeOrigin: true,
        },
      },
    },
  },
});
