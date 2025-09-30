// @ts-check
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: process.env.SITE ?? 'http://localhost:4321',
  output: 'server',              // <= IMPORTANT pour activer les endpoints /api/*
  integrations: [react()],
  vite: { plugins: [tailwindcss()] },
});