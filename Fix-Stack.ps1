param(
  [int]$Port = 3000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$root = (Get-Location).Path

function Write-Text($Path, [string]$Content){
  $dir = Split-Path -Parent $Path
  if($dir){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# 1) Arborescence front
New-Item -ItemType Directory -Force -Path "frontend/src/{pages,layouts,components,scripts,lib,styles}" | Out-Null

# 2) Astro config + Tailwind
Write-Text "frontend/astro.config.mjs" @"
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  integrations: [react(), tailwind()],
  server: { port: $Port, host: true }
});
"@

Write-Text "frontend/tailwind.config.mjs" @"
export default {
  content: ['./src/**/*.{astro,html,js,jsx,ts,tsx}'],
  theme: { extend: {} },
  plugins: [],
};
"@

Write-Text "frontend/src/styles/global.css" @"
@tailwind base;
@tailwind components;
@tailwind utilities;
"@

# 3) Layout de base
Write-Text "frontend/src/layouts/BaseLayout.astro" @"
---
interface Props { title?: string; description?: string }
const { title = 'Optimealone', description = '' } = Astro.props as Props;
---
<!doctype html>
<html lang="fr">
  <head>
    <meta charset='utf-8' />
    <meta name='viewport' content='width=device-width,initial-scale=1' />
    <title>{title}</title>
    <meta name='description' content={description} />
    <link rel='stylesheet' href='/src/styles/global.css' />
  </head>
  <body class='min-h-screen bg-stone-50 text-slate-900'>
    <slot />
  </body>
</html>
"@

# 4) Pages
Write-Text "frontend/src/pages/index.astro" @"
---
import BaseLayout from '../layouts/BaseLayout.astro';
---
<BaseLayout title='Optimealone'>
  <main class='min-h-screen grid place-items-center p-8'>
    <div class='max-w-xl text-center space-y-6'>
      <h1 class='text-3xl font-bold'>Bienvenue</h1>
      <p class='text-gray-600'>Connectez-vous pour accéder au tableau de bord.</p>
      <div class='flex gap-3 justify-center'>
        <a href='/login' class='px-4 py-2 rounded bg-emerald-600 text-white'>Se connecter</a>
        <a href='/dashboard' class='px-4 py-2 rounded border border-gray-300'>Aller au dashboard</a>
      </div>
    </div>
  </main>
</BaseLayout>
"@

Write-Text "frontend/src/pages/login.astro" @"
---
import BaseLayout from '../layouts/BaseLayout.astro';
---
<BaseLayout title='Connexion'>
  <main class='min-h-screen grid place-items-center p-6'>
    <div class='w-full max-w-md bg-white rounded-2xl shadow p-6 space-y-4'>
      <h1 class='text-2xl font-semibold'>Se connecter</h1>
      <div id='error'   class='hidden text-sm text-red-600'></div>
      <div id='success' class='hidden text-sm text-emerald-600'></div>
      <form id='loginForm' class='space-y-3'>
        <input id='email'    type='email'    placeholder='Email'       required class='w-full border rounded px-3 py-2'>
        <input id='password' type='password' placeholder='Mot de passe' required class='w-full border rounded px-3 py-2'>
        <button id='submitBtn' type='submit' class='w-full bg-emerald-600 text-white rounded px-4 py-2'>Se connecter</button>
      </form>
      <p class='text-sm text-gray-500'>Pas de compte ? <a href='/register' class='text-emerald-700 underline'>Créer un compte</a></p>
    </div>
  </main>
  <script type='module' src='/src/scripts/auth-login.ts'></script>
</BaseLayout>
"@

Write-Text "frontend/src/pages/register.astro" @"
---
import BaseLayout from '../layouts/BaseLayout.astro';
---
<BaseLayout title='Créer un compte'>
  <main class='min-h-screen grid place-items-center p-6'>
    <div class='w-full max-w-md bg-white rounded-2xl shadow p-6 space-y-4'>
      <h1 class='text-2xl font-semibold'>Créer un compte</h1>
      <div id='error'   class='hidden text-sm text-red-600'></div>
      <div id='success' class='hidden text-sm text-emerald-600'></div>
      <form id='registerForm' class='space-y-3'>
        <input id='email'    type='email'    placeholder='Email'       required class='w-full border rounded px-3 py-2'>
        <input id='password' type='password' placeholder='Mot de passe' required class='w-full border rounded px-3 py-2'>
        <button id='submitBtn' type='submit' class='w-full bg-emerald-600 text-white rounded px-4 py-2'>Créer</button>
      </form>
      <p class='text-sm text-gray-500'>Déjà inscrit ? <a href='/login' class='text-emerald-700 underline'>Se connecter</a></p>
    </div>
  </main>
  <script type='module' src='/src/scripts/auth-register.ts'></script>
</BaseLayout>
"@

Write-Text "frontend/src/pages/dashboard.astro" @"
---
import BaseLayout from '../layouts/BaseLayout.astro';
---
<BaseLayout title='Dashboard - Optimealone'>
  <main class='min-h-screen bg-gray-50 py-12 px-4'>
    <div class='max-w-7xl mx-auto'>
      <div class='bg-white rounded-2xl shadow-xl p-8'>
        <h1 class='text-3xl font-bold text-gray-900 mb-6'>Tableau de bord</h1>
        <div id='userInfo' class='mb-8'><div class='animate-pulse h-20 bg-gray-200 rounded'></div></div>
        <div class='grid md:grid-cols-3 gap-6'>
          <div class='bg-emerald-50 p-6 rounded-xl border border-emerald-200'>
            <h3 class='font-semibold text-emerald-900 mb-2'>Analyses effectuées</h3>
            <p class='text-3xl font-bold text-emerald-600'>0</p>
          </div>
          <div class='bg-blue-50 p-6 rounded-xl border border-blue-200'>
            <h3 class='font-semibold text-blue-900 mb-2'>Quota restant</h3>
            <p class='text-3xl font-bold text-blue-600'>10/10</p>
          </div>
          <div class='bg-purple-50 p-6 rounded-xl border border-purple-200'>
            <h3 class='font-semibold text-purple-900 mb-2'>Statut</h3>
            <p class='text-lg font-semibold text-purple-600'>Gratuit</p>
          </div>
        </div>
        <div class='mt-8'>
          <a href='/pedagogique' class='inline-block px-6 py-3 bg-emerald-600 text-white rounded-lg font-semibold hover:bg-emerald-700 transition'>
            Commencer une analyse →
          </a>
        </div>
      </div>
    </div>
  </main>
  <script type='module' src='/src/scripts/auth-dashboard.ts'></script>
</BaseLayout>
"@

# 5) Supabase client + scripts
Write-Text "frontend/src/lib/supabase.ts" @"
import { createClient } from '@supabase/supabase-js';
export const supabase = createClient(
  import.meta.env.PUBLIC_SUPABASE_URL!,
  import.meta.env.PUBLIC_SUPABASE_ANON_KEY!
);
"@

Write-Text "frontend/src/scripts/auth-dashboard.ts" @"
import { supabase } from '../lib/supabase';
(async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) { window.location.href = '/login'; return; }
  const el = document.getElementBy
