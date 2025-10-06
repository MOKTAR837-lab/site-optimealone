// astro.config.mjs
// @ts-check
import { defineConfig } from 'astro/config';
import node from '@astrojs/node';

export default defineConfig({
  output: 'server',
  adapter: node({
    mode: 'standalone',
  }),
  server: { host: '127.0.0.1', port: 4321 },
  vite: { server: { strictPort: true } },
  // site: 'https://optimealhealth.com',
});