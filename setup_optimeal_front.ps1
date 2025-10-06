# setup_optimeal_front.ps1
# Installe/actualise un front Astro + Tailwind (pages .astro SEO), UTF-8 SANS BOM, idempotent.
# Déploiement statique optionnel vers un webroot Nginx sans modifier la conf Nginx.
param(
  [string]$FrontRoot = "C:\site_optimealhealth.com\optimealhealth_docker\front_site",
  [switch]$NoBuild,
  [switch]$StageAsNew,
  [switch]$Overwrite,
  [switch]$DryRun,
  [switch]$ProtectNginx = $true,
  [string]$ReportPath,
  [string]$WebRoot,       # ex: "C:\nginx\html" (ou /var/www/html)
  [switch]$AtomicDeploy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "[OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "[ERR]  $m" -ForegroundColor Red }

if ($StageAsNew -and $Overwrite) { Err "Options incompatibles: -StageAsNew et -Overwrite"; exit 1 }

# Chemin cible
Info "Chemin cible: $FrontRoot"
if (-not (Test-Path $FrontRoot)) { New-Item -ItemType Directory -Path $FrontRoot -Force | Out-Null }

# Node/npm check (Astro 4 => Node >= 18.14)
try {
  $nodeV = node -v; $npmV = npm -v
  $nodeMajor = [int]($nodeV.TrimStart('v').Split('.')[0])
  $nodeMinor = [int]($nodeV.TrimStart('v').Split('.')[1])
  if ($nodeMajor -lt 18 -or ($nodeMajor -eq 18 -and $nodeMinor -lt 14)) {
    Err "Node $nodeV détecté (< 18.14). Requis: Node >= 18.14"; exit 1
  }
  Ok "Node $nodeV / npm $npmV détectés"
} catch { Err "Node.js + npm requis"; exit 1 }

# Journal CSV
$Report = New-Object System.Collections.Generic.List[object]
function Log-Action([string]$Path,[string]$Action){
  $Report.Add([PSCustomObject]@{ Timestamp = (Get-Date); Action = $Action; Path = $Path })
}

# Écriture UTF-8 sans BOM
function Write-NoBom {
  param([string]$Path,[string]$Content)
  if ($DryRun) { Info "DryRun: Write $Path"; return }
  $dir = Split-Path $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# Protection Nginx
$ProtectedPatterns = @('nginx.conf$', '\.conf$', 'nginx\\', '/nginx/', '^conf$', '^logs$', '\blog$', '\bcache$')
function Test-ProtectedPath([string]$Path){
  if (-not $ProtectNginx) { return $false }
  foreach($pat in $ProtectedPatterns){ if ($Path -imatch $pat) { return $true } }
  return $false
}

# Sauvegardes
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $FrontRoot ("_backup_"+$stamp)
if (-not $DryRun) { New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null }

# Écriture safe
function Write-SafeFile {
  param([string]$Path,[string]$Content,[string]$BackupRoot,[switch]$Binary)

  if (Test-ProtectedPath $Path) {
    Warn "Ignoré (protégé Nginx): $Path"
    Log-Action $Path "SkipProtected"
    return
  }

  if (Test-Path $Path) {
    if ($Overwrite) {
      $rel = Resolve-Path $Path | Split-Path -NoQualifier
      $dest = Join-Path $BackupRoot $rel
      if (-not $DryRun) {
        New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
        Copy-Item $Path $dest -Force
      }
      if ($DryRun) { Info "DryRun: overwrite $Path (backup->$dest)"; Log-Action $Path "Overwrite"; return }
      if ($Binary) { [IO.File]::WriteAllBytes($Path, [Convert]::FromBase64String($Content)) } else { Write-NoBom -Path $Path -Content $Content }
      Ok "Écrasé (avec backup): $Path"; Log-Action $Path "Overwritten"
    } elseif ($StageAsNew) {
      $newPath = "$Path.new"
      if ($DryRun) { Info "DryRun: stage-as-new $newPath"; Log-Action $newPath "StagedNew"; return }
      if ($Binary) { [IO.File]::WriteAllBytes($newPath, [Convert]::FromBase64String($Content)) } else { Write-NoBom -Path $newPath -Content $Content }
      Ok "Existant inchangé; version de comparaison: $newPath"; Log-Action $newPath "StagedNew"
    } else {
      Info "Existant conservé: $Path"; Log-Action $Path "Kept"
    }
  } else {
    if ($DryRun) { Info "DryRun: create $Path"; Log-Action $Path "Create"; return }
    if ($Binary) { [IO.File]::WriteAllBytes($Path, [Convert]::FromBase64String($Content)) } else { Write-NoBom -Path $Path -Content $Content }
    Ok "Créé: $Path"; Log-Action $Path "Created"
  }
}

# Arbo
$dirs = @(
  "public",
  "src",
  "src/styles",
  "src/components",
  "src/layouts",
  "src/pages",
  "src/pages/blog"
)
foreach($d in $dirs){ if (-not $DryRun) { New-Item -ItemType Directory -Path (Join-Path $FrontRoot $d) -Force | Out-Null } }

# ----- FICHIERS (UTF-8 SANS BOM) -----
$F = @{}

# package.json (Astro + Tailwind + Sitemap + Sharp)
$F["package.json"] = @'
{
  "name": "optimeal-health",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview"
  },
  "dependencies": {
    "astro": "^4.15.0",
    "@astrojs/tailwind": "^5.1.0",
    "@astrojs/sitemap": "^3.1.4",
    "sharp": "^0.33.4"
  },
  "devDependencies": {
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.47",
    "tailwindcss": "^3.4.14",
    "typescript": "^5.6.3"
  }
}
'@

# astro.config.mjs (SEO + vars publiques pour FastAPI)
$F["astro.config.mjs"] = @'
import { defineConfig } from "astro/config";
import tailwind from "@astrojs/tailwind";
import sitemap from "@astrojs/sitemap";

export default defineConfig({
  site: import.meta.env.SITE || "https://optimealhealth.com",
  integrations: [tailwind(), sitemap()],
  output: "static",
  vite: {
    define: {
      "import.meta.env.PUBLIC_BACKEND_URL": JSON.stringify(process.env.PUBLIC_BACKEND_URL || process.env.BACKEND_URL || "http://localhost:8000"),
      "import.meta.env.PUBLIC_API_BASE": JSON.stringify(process.env.PUBLIC_API_BASE || process.env.API_BASE || "/api/v1")
    }
  }
});
'@

# tailwind.config.js — on respecte TON fichier existant (safelist comprise)
# (si déjà présent, on le conserve sauf -Overwrite ; contenu issu de ton upload)
$F["tailwind.config.js"] = @'
/** @type {import(''tailwindcss'').Config} */
export default {
  content: ["./src/**/*.{astro,html,md,mdx,js,ts,tsx}", "./public/**/*.html"],
  safelist: [{ pattern: /(bg|text|border)-(green|red|blue|slate)-(100|500|700)/ }]
};
'@

# postcss + tsconfig
$F["postcss.config.cjs"] = @'
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {} } };
'@

$F["tsconfig.json"] = @'
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": { "baseUrl": "." }
}
'@

# .env.example (+ .env si absent)
$F[".env.example"] = @'
SITE=https://optimealhealth.com
BACKEND_URL=http://localhost:8000
API_BASE=/api/v1
PUBLIC_BACKEND_URL=http://localhost:8000
PUBLIC_API_BASE=/api/v1
'@

$envPath = Join-Path $FrontRoot ".env"
if (-not (Test-Path $envPath)) { $F[".env"] = $F[".env.example"] }

# public
$F["public/favicon.svg"] = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" role="img" aria-label="OptiMeal">
  <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#10B981"/><stop offset="1" stop-color="#059669"/>
  </linearGradient></defs>
  <rect width="128" height="128" rx="24" fill="url(#g)"/>
  <text x="50%" y="50%" dy=".35em" text-anchor="middle" font-family="Poppins, Arial" font-size="56" fill="#fff">OM</text>
</svg>
'@

# styles globaux Tailwind
$F["src/styles/global.css"] = @'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Base typographique légère */
:root { --brand:#10B981; }
html { scroll-behavior:smooth; }
.prose a { @apply text-slate-900 underline decoration-2 decoration-slate-300 hover:decoration-[var(--brand)]; }
.btn-primary { @apply px-5 py-3 rounded-xl bg-[var(--brand)] text-white font-semibold hover:brightness-95; }
.card { @apply bg-white border border-slate-200 rounded-2xl shadow-sm; }
'@

# env types
$F["src/env.d.ts"] = @'
/// <reference types="astro/client" />
interface ImportMetaEnv {
  readonly SITE: string;
  readonly PUBLIC_BACKEND_URL: string;
  readonly PUBLIC_API_BASE: string;
}
interface ImportMeta { env: ImportMetaEnv }
'@

# Layout de base (SEO + JSON-LD)
$F["src/layouts/BaseLayout.astro"] = @'
---
import "../styles/global.css";
interface Props { title: string; description?: string; image?: string; }
const { title, description = "OptiMeal Health — Assistant nutritionnel éducatif (non clinique).", image = "/og.jpg" } = Astro.props;
const canon = new URL(Astro.url.pathname, Astro.site);
---
<!DOCTYPE html>
<html lang="fr" class="scroll-smooth">
  <head>
    <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" href="/favicon.svg" />
    <link rel="canonical" href={canon} />
    <title>{title} | OptiMeal Health</title>
    <meta name="description" content={description} />
    <meta name="theme-color" content="#10B981" />
    <meta property="og:type" content="website" /><meta property="og:title" content={title} />
    <meta property="og:description" content={description} /><meta property="og:url" content={canon} />
    <script type="application/ld+json">
      {JSON.stringify({"@context":"https://schema.org","@type":"Organization","name":"OptiMeal Health","url":(Astro.site||"").toString(),"logo":"/favicon.svg"})}
    </script>
  </head>
  <body class="antialiased bg-white text-slate-900">
    <a href="#main" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:bg-black focus:text-white focus:px-3 focus:py-2 rounded">Aller au contenu</a>
    <slot name="header" />
    <main id="main"><slot /></main>
    <slot name="footer" />
  </body>
</html>
'@

# Header & Footer
$F["src/components/Header.astro"] = @'
<header class="sticky top-0 z-40 bg-white/90 backdrop-blur border-b border-slate-200">
  <div class="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
    <a href="/" class="flex items-center gap-2">
      <img src="/favicon.svg" alt="" class="w-8 h-8 rounded-lg" aria-hidden="true" />
      <span class="font-semibold">OptiMeal Health</span>
    </a>
    <nav class="hidden md:flex items-center gap-6 text-sm">
      <a href="/#features" class="hover:text-emerald-600">Fonctionnalités</a>
      <a href="/#pricing" class="hover:text-emerald-600">Offres</a>
      <a href="/blog" class="hover:text-emerald-600">Blog</a>
      <a href="/login" class="text-slate-600">Connexion</a>
      <a href="/signup" class="btn-primary">Essayer gratuitement</a>
    </nav>
  </div>
</header>
'@

$F["src/components/Footer.astro"] = @'
<footer class="border-t border-slate-200 mt-16">
  <div class="max-w-7xl mx-auto px-4 py-10 grid md:grid-cols-4 gap-8 text-sm">
    <div class="md:col-span-2">
      <div class="flex items-center gap-2 mb-3">
        <img src="/favicon.svg" alt="" class="w-8 h-8 rounded-lg" aria-hidden="true" />
        <span class="font-semibold">OptiMeal Health</span>
      </div>
      <p class="text-slate-600">Information générale à visée éducative. Ne remplace pas un avis médical. Aucune donnée de santé collectée.</p>
    </div>
    <div>
      <h4 class="font-semibold">Produit</h4>
      <ul class="mt-2 space-y-2">
        <li><a href="/#features" class="hover:text-emerald-700">Fonctionnalités</a></li>
        <li><a href="/#pricing" class="hover:text-emerald-700">Offres</a></li>
        <li><a href="/blog" class="hover:text-emerald-700">Blog</a></li>
      </ul>
    </div>
    <div>
      <h4 class="font-semibold">Légal</h4>
      <ul class="mt-2 space-y-2">
        <li><a href="/privacy" class="hover:text-emerald-700">Confidentialité</a></li>
        <li><a href="/terms" class="hover:text-emerald-700">CGU</a></li>
        <li><a href="/mentions" class="hover:text-emerald-700">Mentions légales</a></li>
        <li><a href="/cookies" class="hover:text-emerald-700">Cookies</a></li>
      </ul>
    </div>
  </div>
  <div class="max-w-7xl mx-auto px-4 pb-8 text-xs text-slate-500">© <script>document.write(new Date().getFullYear())</script> OptiMeal Health. Tous droits réservés.</div>
</footer>
'@

# Cookie banner simple
$F["src/components/CookieBanner.astro"] = @'
<div id="cookie-consent" class="fixed inset-x-0 bottom-0 z-50 hidden md:flex items-center justify-between gap-4 bg-slate-900 text-white p-4">
  <p class="text-sm">Cookies de mesure d''audience anonymisés. <a href="/cookies" class="underline">En savoir plus</a>.</p>
  <div class="flex gap-2">
    <button id="acceptCookies" class="px-3 py-1.5 bg-emerald-500 rounded">Accepter</button>
    <button id="rejectCookies" class="px-3 py-1.5 bg-white text-slate-900 rounded">Refuser</button>
  </div>
</div>
<script>
const KEY="cookie:consent";const b=document.getElementById("cookie-consent");
const show=()=>b?.classList.remove("hidden");const hide=()=>b?.classList.add("hidden");
if(!localStorage.getItem(KEY))show();
document.getElementById("acceptCookies")?.addEventListener("click",()=>{localStorage.setItem(KEY,"accepted");hide();});
document.getElementById("rejectCookies")?.addEventListener("click",()=>{localStorage.setItem(KEY,"rejected");hide();});
</script>
'@

# Sections de la home (non clinique, éducatif)
$F["src/components/Hero.astro"] = @'
<section class="max-w-7xl mx-auto px-4 pt-14 pb-12 grid lg:grid-cols-2 gap-10 items-center">
  <div>
    <h1 class="text-4xl md:text-5xl font-extrabold leading-tight">Posez vos questions nutrition à un <span class="text-emerald-600">diététicien diplômé d''État</span>… gratuitement !</h1>
    <p class="mt-4 text-lg text-slate-600">Réponses éducatives, sourcées et claires. Aucune donnée de santé, uniquement de l''information générale.</p>
    <div class="mt-6 flex flex-col sm:flex-row gap-3">
      <a href="/signup" class="btn-primary text-center">Essayer gratuitement</a>
      <a href="#pricing" class="px-5 py-3 rounded-xl border border-slate-300 hover:bg-slate-50 font-semibold text-center">Voir les offres</a>
    </div>
    <p class="mt-3 text-xs text-slate-500">Freemium : 10 questions/jour. Pas de conseil médical personnalisé.</p>
  </div>
  <div class="card p-4">
    <div class="text-xs text-slate-500 mb-2">Démo</div>
    <div class="space-y-4 text-sm">
      <div class="flex gap-3"><div class="h-8 w-8 rounded-full bg-slate-200" aria-hidden="true"></div><div class="bg-slate-50 border border-slate-200 rounded-2xl p-3 max-w-[90%]">Combien de protéines par jour ?</div></div>
      <div class="flex gap-3"><div class="h-8 w-8 rounded-full bg-emerald-100" aria-hidden="true"></div><div class="bg-white border border-slate-200 rounded-2xl p-3 max-w-[90%]"><p class="font-medium">Réponse (éducative)</p><ul class="list-disc pl-5 mt-1 text-slate-700"><li>Repère général : ≈ 0,8 g/kg/j.</li><li>Varier les sources (végétales & animales).</li><li>Pour du personnalisé → consulter un professionnel.</li></ul><p class="text-xs text-slate-500 mt-2">Citations : Cours “Protéines”, Chap. 2</p></div></div>
    </div>
  </div>
</section>
'@

$F["src/components/Features.astro"] = @'
<section id="features" class="py-16 bg-slate-50">
  <div class="max-w-7xl mx-auto px-4">
    <h2 class="text-3xl font-bold text-center">Pourquoi c''est utile</h2>
    <p class="text-center text-slate-600 mt-2">Éducation nutritionnelle fiable, rapide et transparente.</p>
    <div class="grid md:grid-cols-3 gap-6 mt-10">
      <div class="card p-6"><div class="h-10 w-10 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center mb-3" aria-hidden="true">📚</div><h3 class="font-semibold">Réponses sourcées</h3><p class="text-sm text-slate-600 mt-1">Basées sur vos supports et sources officielles. Citations incluses.</p></div>
      <div class="card p-6"><div class="h-10 w-10 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center mb-3" aria-hidden="true">🏷️</div><h3 class="font-semibold">Décryptage d''étiquettes</h3><p class="text-sm text-slate-600 mt-1">Comprendre Nutri-Score, ingrédients & repères nutritionnels.</p></div>
      <div class="card p-6"><div class="h-10 w-10 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center mb-3" aria-hidden="true">🍽️</div><h3 class="font-semibold">Menus types</h3><p class="text-sm text-slate-600 mt-1">Exemples de repas équilibrés (non personnalisés).</p></div>
    </div>
  </div>
</section>
'@

$F["src/components/Pricing.astro"] = @'
---
const tiers = [
  { name: "Freemium", price: "0€", features: ["Questions/jour: 10", "Réponses éducatives sourcées", "Blog & newsletter"], cta: "/signup" },
  { name: "Premium", price: "9,90€/mois", features: ["Questions illimitées", "Historique personnel", "Guides exclusifs", "Export PDF (plans types)"], cta: "/signup?plan=premium" }
];
---
<section id="pricing" class="py-16">
  <div class="max-w-7xl mx-auto px-4">
    <h2 class="text-3xl font-bold text-center">Commencez gratuitement</h2>
    <p class="text-center text-slate-600 mt-2">Passez au Premium à votre rythme, quand vous en ressentez la valeur.</p>
    <div class="grid md:grid-cols-2 gap-6 mt-10 max-w-5xl mx-auto">
      {tiers.map((t) => (
        <div class={`card p-6 ${t.name === "Premium" ? "border-emerald-500" : ""}`}>
          <h3 class="text-xl font-semibold">{t.name}</h3>
          <p class="text-4xl font-extrabold mt-3">{t.price}<span class="text-base font-medium text-slate-500">/mois</span></p>
          <ul class="mt-6 space-y-2 text-sm">{t.features.map((f) => <li class="flex items-start gap-2"><span>✅</span><span>{f}</span></li>)}</ul>
          <a href={t.cta} class="btn-primary mt-6 inline-block text-center w-full">Choisir</a>
        </div>
      ))}
    </div>
    <p class="text-xs text-slate-500 mt-6 text-center">Information à visée éducative, ne remplace pas un avis médical. Pas de conseil personnalisé.</p>
  </div>
</section>
'@

$F["src/components/Testimonials.astro"] = @'
<section class="py-16 bg-slate-50">
  <div class="max-w-7xl mx-auto px-4">
    <h2 class="text-3xl font-bold text-center">Ils en parlent</h2>
    <div class="grid md:grid-cols-3 gap-6 mt-10">
      <figure class="card p-6 text-sm"><blockquote>« Réponses claires, sourcées, sans blabla. »</blockquote><figcaption class="mt-3 text-slate-500">— Utilisateur test</figcaption></figure>
      <figure class="card p-6 text-sm"><blockquote>« Porté par un pro de santé, ça change tout. »</blockquote><figcaption class="mt-3 text-slate-500">— Lectrice blog</figcaption></figure>
      <figure class="card p-6 text-sm"><blockquote>« On a tout de suite les sources. Top. »</blockquote><figcaption class="mt-3 text-slate-500">— Abonné newsletter</figcaption></figure>
    </div>
  </div>
</section>
'@

$F["src/components/FAQ.astro"] = @'
<section id="faq" class="py-16">
  <div class="max-w-5xl mx-auto px-4">
    <h2 class="text-3xl font-bold text-center">FAQ</h2>
    <div class="mt-10 grid md:grid-cols-2 gap-6">
      <details class="card p-4"><summary class="font-semibold cursor-pointer">Remplace-t-il une consultation ?</summary><p class="mt-2 text-slate-600 text-sm">Non. Service éducatif uniquement.</p></details>
      <details class="card p-4"><summary class="font-semibold cursor-pointer">Collectez-vous des données de santé ?</summary><p class="mt-2 text-slate-600 text-sm">Non. Nom & email uniquement (compte/newsletter).</p></details>
      <details class="card p-4"><summary class="font-semibold cursor-pointer">Combien de questions ?</summary><p class="mt-2 text-slate-600 text-sm">Freemium 10/jour, Premium illimité.</p></details>
      <details class="card p-4"><summary class="font-semibold cursor-pointer">D''où viennent les réponses ?</summary><p class="mt-2 text-slate-600 text-sm">De vos supports pédagogiques (RAG) & sources officielles (citations).</p></details>
    </div>
  </div>
</section>
'@

$F["src/components/BlogTeaser.astro"] = @'
<section class="max-w-7xl mx-auto px-4 py-16">
  <h2 class="text-2xl font-semibold">Derniers articles</h2>
  <div class="grid md:grid-cols-3 gap-6 mt-6">
    <article class="card p-5"><h3 class="font-semibold">Apports journaliers recommandés</h3><p class="text-sm text-slate-600 mt-1">Repères essentiels.</p><a href="/blog/apports-journaliers" class="text-emerald-700 font-semibold mt-2 inline-block">Lire →</a></article>
    <article class="card p-5"><h3 class="font-semibold">Combien de protéines par jour ?</h3><p class="text-sm text-slate-600 mt-1">Bases sourcées.</p><a href="/blog/proteines-par-jour" class="text-emerald-700 font-semibold mt-2 inline-block">Lire →</a></article>
    <article class="card p-5"><h3 class="font-semibold">Menu équilibré sur une semaine</h3><p class="text-sm text-slate-600 mt-1">Idées simples.</p><a href="/blog/menu-equilibre-semaine" class="text-emerald-700 font-semibold mt-2 inline-block">Lire →</a></article>
  </div>
</section>
'@

# Pages
$F["src/pages/index.astro"] = @'
---
import BaseLayout from "../layouts/BaseLayout.astro";
import Header from "../components/Header.astro";
import Footer from "../components/Footer.astro";
import CookieBanner from "../components/CookieBanner.astro";
import Hero from "../components/Hero.astro";
import Features from "../components/Features.astro";
import Pricing from "../components/Pricing.astro";
import Testimonials from "../components/Testimonials.astro";
import FAQ from "../components/FAQ.astro";
import BlogTeaser from "../components/BlogTeaser.astro";
---
<BaseLayout title="Accueil — Assistant nutrition éducatif">
  <Fragment slot="header"><Header /></Fragment>
  <Hero /><Features /><Pricing /><Testimonials /><FAQ /><BlogTeaser />
  <Fragment slot="footer"><Footer /><CookieBanner /></Fragment>
</BaseLayout>
'@

$F["src/pages/signup.astro"] = @'
---
import BaseLayout from "../layouts/BaseLayout.astro";
---
<BaseLayout title="Inscription">
  <section class="min-h-screen flex items-center justify-center bg-slate-50 py-12 px-4">
    <div class="card max-w-md w-full p-8">
      <h1 class="text-2xl font-bold mb-1">Créer un compte</h1>
      <p class="text-sm text-slate-600 mb-6">Nom & email suffisent. Désinscription à tout moment.</p>
      <form id="signup-form" class="grid gap-3">
        <label class="text-sm font-medium">Nom<input name="name" required class="mt-1 w-full rounded-xl border-slate-300 focus:border-emerald-500 focus:ring-emerald-500" /></label>
        <label class="text-sm font-medium">Email<input type="email" name="email" required class="mt-1 w-full rounded-xl border-slate-300 focus:border-emerald-500 focus:ring-emerald-500" /></label>
        <label class="text-sm font-medium">Mot de passe<input type="password" name="password" required class="mt-1 w-full rounded-xl border-slate-300 focus:border-emerald-500 focus:ring-emerald-500" /></label>
        <label class="inline-flex items-start gap-2 text-sm"><input type="checkbox" name="newsletter" class="mt-1 rounded border-slate-300" /><span>Je souhaite recevoir la newsletter (facultatif).</span></label>
        <button id="btn" type="button" class="btn-primary mt-2">Créer mon compte</button>
        <p class="text-xs text-slate-500">En créant un compte, vous acceptez nos <a href="/terms" class="underline">CGU</a> et notre <a href="/privacy" class="underline">Politique de confidentialité</a>.</p>
      </form>
    </div>
  </section>
</BaseLayout>
<script>
const form=document.getElementById("signup-form");
document.getElementById("btn")?.addEventListener("click", async ()=>{
  const fd=new FormData(form); const data=Object.fromEntries(fd.entries());
  const base = import.meta.env.PUBLIC_BACKEND_URL + import.meta.env.PUBLIC_API_BASE;
  // POST /auth/signup (FastAPI)
  alert(`POST ${base}/auth/signup\nBody: ${JSON.stringify({...data, password:"••••"}, null, 2)}`);
});
</script>
'@

$F["src/pages/login.astro"] = @'
---
import BaseLayout from "../layouts/BaseLayout.astro";
---
<BaseLayout title="Connexion">
  <section class="min-h-screen flex items-center justify-center bg-slate-50 py-12 px-4">
    <div class="card max-w-md w-full p-8">
      <h1 class="text-2xl font-bold mb-1">Connexion</h1>
      <form id="login-form" class="grid gap-3 mt-4">
        <label class="text-sm font-medium">Email<input type="email" name="email" required class="mt-1 w-full rounded-xl border-slate-300 focus:border-emerald-500 focus:ring-emerald-500" /></label>
        <label class="text-sm font-medium">Mot de passe<input type="password" name="password" required class="mt-1 w-full rounded-xl border-slate-300 focus:border-emerald-500 focus:ring-emerald-500" /></label>
        <button id="btn" type="button" class="btn-primary mt-2">Se connecter</button>
      </form>
    </div>
  </section>
</BaseLayout>
<script>
const form=document.getElementById("login-form");
document.getElementById("btn")?.addEventListener("click", async ()=>{
  const fd=new FormData(form); const data=Object.fromEntries(fd.entries());
  const base = import.meta.env.PUBLIC_BACKEND_URL + import.meta.env.PUBLIC_API_BASE;
  // POST /auth/login (FastAPI)
  alert(`POST ${base}/auth/login\nBody: ${JSON.stringify({...data, password:"••••"}, null, 2)}`);
});
</script>
'@

$F["src/pages/privacy.astro"] = @'
---
import BaseLayout from "../layouts/BaseLayout.astro";
---
<BaseLayout title="Politique de confidentialité">
  <section class="max-w-4xl mx-auto px-4 py-16 prose">
    <h1>Politique de confidentialité</h1>
    <p><small>Dernière mise à jour : 5 octobre 2025</small></p>
    <h2>1. Collecte</h2><p>Nom, email, données d’usage. Aucune donnée de santé.</p>
    <h2>2. Finalités</h2><p>Gestion de compte, communication, amélioration du service.</p>
    <h2>3. Sécurité</h2><p>Hébergement UE, TLS, moindre privilège.</p>
    <h2>4. Droits</h2><p>Accès, rectification, effacement, portabilité, opposition (contact : dpo@optimealhealth.com).</p>
    <h2>5. Conservation</h2><p>Durée de l’abonnement + 3 ans.</p>
  </section>
</BaseLayout>
'@

$F["src/pages/terms.astro"] = @'
---
import BaseLayout from "../layouts/BaseLayout.astro";
---
<BaseLayout title="Conditions Générales d’Utilisation">
  <section class="max-w-4xl mx-auto px-4 py-16 prose">
    <h1>Conditions Générales d’Utilisation</h1>
    <p><small>Dernière mise à jour : 5 octobre 2025</small></p>
    <h2>1. Objet</h2><p>Ces CGU encadrent l’usage d’OptiMeal Health.</p>
    <h2>2. Nature</h2><p>Service éducatif (non clinique).</p>
    <h2>3. Comptes</h2><p>Responsabilité des identifiants.</p>
    <h2>4. Abonnements</h2><p>Modalités et annulation.</p>
    <h2>5. Données</h2><p>RGPD ; voir la Politique de confidentialité.</p>
  </section>
</BaseLayout>
'@

$F["src/pages/mentions.astro"] = @'
---
import BaseLayout from "../layouts/BaseLayout.astro";
---
<BaseLayout title="Mentions légales">
  <section class="max-w-4xl mx-auto px-4 py-16 prose">
    <h1>Mentions légales</h1>
    <p>Raison sociale, SIRET, responsable de publication, hébergeur (UE), contact.</p>
  </section>
</BaseLayout>
'@

$F["src/pages/cookies.astro"] = @'
---
import BaseLayout from "../layouts/BaseLayout.astro";
---
<BaseLayout title="Cookies">
  <section class="max-w-4xl mx-auto px-4 py-16 prose">
    <h1>Cookies</h1>
    <p>Cookies essentiels et de mesure d''audience anonymisée. Paramétrables via la bannière.</p>
  </section>
</BaseLayout>
'@

$F["src/pages/accessibility.astro"] = @'
---
import BaseLayout from "../layouts/BaseLayout.astro";
---
<BaseLayout title="Accessibilité">
  <section class="max-w-4xl mx-auto px-4 py-16 prose">
    <h1>Accessibilité</h1>
    <p>Navigation clavier, contrastes, alternatives textuelles.</p>
  </section>
</BaseLayout>
'@

$F["src/pages/blog/index.astro"] = @'
---
import BaseLayout from "../../layouts/BaseLayout.astro";
---
<BaseLayout title="Blog — OptiMeal Health">
  <section class="max-w-4xl mx-auto px-4 py-16">
    <h1 class="text-3xl font-semibold">Blog</h1>
    <ul class="mt-6 space-y-2">
      <li><a class="underline" href="/blog/apports-journaliers">Apports journaliers recommandés</a></li>
      <li><a class="underline" href="/blog/proteines-par-jour">Combien de protéines par jour ?</a></li>
      <li><a class="underline" href="/blog/menu-equilibre-semaine">Menu équilibré sur une semaine</a></li>
    </ul>
  </section>
</BaseLayout>
'@

$F["src/pages/blog/[slug].astro"] = @'
---
import BaseLayout from "../../layouts/BaseLayout.astro";
const { slug } = Astro.params;
const articles = {
  "apports-journaliers": { title: "Apports journaliers recommandés", content: "Repères essentiels par nutriment." },
  "proteines-par-jour": { title: "Combien de protéines par jour ?", content: "Les bases sourcées pour y voir clair." },
  "menu-equilibre-semaine": { title: "Menu équilibré sur une semaine", content: "Des idées simples et variées." }
};
const article = articles[slug] ?? { title: "Article", content: "Contenu à venir." };
---
<BaseLayout title={`${article.title} — Blog`} description={article.content}>
  <article class="mx-auto max-w-3xl px-4 py-16 prose"><h1>{article.title}</h1><p>{article.content}</p></article>
</BaseLayout>
'@

$F["src/pages/robots.txt.ts"] = @'
export function GET() {
  const site = import.meta.env.SITE || "https://optimealhealth.com";
  const body = `User-agent: *\nAllow: /\nSitemap: ${site}/sitemap.xml`;
  return new Response(body, { headers: { "Content-Type": "text/plain" } });
}
'@

$F["src/pages/sitemap.xml.ts"] = @'
export async function GET() {
  return new Response("", { headers: { "Content-Type": "application/xml" } });
}
'@

$F["src/pages/404.astro"] = @'
---
import BaseLayout from "../layouts/BaseLayout.astro";
---
<BaseLayout title="Page non trouvée">
  <section class="mx-auto max-w-3xl px-4 py-24 text-center">
    <h1 class="text-6xl font-bold">404</h1>
    <p class="mt-4">Oups, cette page n’existe pas.</p>
    <a class="mt-6 inline-block underline" href="/">Retour à l’accueil</a>
  </section>
</BaseLayout>
'@

# Écrire les fichiers
foreach($k in $F.Keys){
  $full = Join-Path $FrontRoot $k
  Write-SafeFile -Path $full -Content $F[$k] -BackupRoot $backupRoot
}

# npm install/build
if (-not $NoBuild) {
  Push-Location $FrontRoot
  try {
    $useCi = Test-Path (Join-Path $FrontRoot "package-lock.json")
    if ($useCi) { if ($DryRun){ Info "DryRun: skip npm ci" } else { Info "npm ci…"; npm ci | Out-Host } }
    else { if ($DryRun){ Info "DryRun: skip npm install" } else { Info "npm install…"; npm install | Out-Host } }
    if ($DryRun){ Info "DryRun: skip build" } else { Info "npm run build…"; npm run build | Out-Host; Ok "Build ok" }
  } finally { Pop-Location }
} else {
  Warn "NoBuild: npm install/build sautés"
}

# Déploiement statique vers WebRoot (sans toucher Nginx)
function Deploy-Static {
  param([string]$Dist,[string]$WebRoot,[switch]$Atomic)

  if (-not (Test-Path $Dist)) { Err "Dossier dist introuvable: $Dist"; exit 1 }
  if (-not (Test-Path $WebRoot)) { if (-not $DryRun) { New-Item -ItemType Directory -Path $WebRoot -Force | Out-Null } }

  $xf = @("nginx.conf","*.conf")
  $xd = @("conf","logs","temp")

  if ($Atomic) {
    $parent = Split-Path $WebRoot -Parent
    $deployDir = Join-Path $parent ("site-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
    if (-not $DryRun) { New-Item -ItemType Directory -Path $deployDir -Force | Out-Null }
    Info "Copie vers $deployDir (atomique)"
    $opts = "/MIR","/R:2","/W:2","/NFL","/NDL","/NJH","/NJS"
    if ($DryRun) { $opts += "/L" }
    foreach($x in $xf){ $opts += "/XF"; $opts += $x }
    foreach($x in $xd){ $opts += "/XD"; $opts += $x }
    robocopy (Join-Path $FrontRoot "dist") $deployDir $opts | Out-Null
    if (-not $DryRun) {
      Info "Mise à jour WebRoot $WebRoot"
      $opts2 = "/MIR","/R:2","/W:2","/NFL","/NDL","/NJH","/NJS"
      foreach($x in $xf){ $opts2 += "/XF"; $opts2 += $x }
      foreach($x in $xd){ $opts2 += "/XD"; $opts2 += $x }
      robocopy $deployDir $WebRoot $opts2 | Out-Null
      Ok "Déploiement atomique OK (Nginx intact)."
    } else { Info "DryRun: aperçu ROBocopy réalisé (aucune écriture)." }
  } else {
    Info "Sync direct dist → WebRoot (sans toucher conf/logs)"
    $opts = "/MIR","/R:2","/W:2","/NFL","/NDL","/NJH","/NJS"
    if ($DryRun) { $opts += "/L" }
    foreach($x in $xf){ $opts += "/XF"; $opts += $x }
    foreach($x in $xd){ $opts += "/XD"; $opts += $x }
    robocopy (Join-Path $FrontRoot "dist") $WebRoot $opts | Out-Null
    if ($DryRun) { Info "DryRun: aperçu ROBocopy terminé." } else { Ok "Déploiement statique OK (Nginx intact)." }
  }
}

if ($WebRoot) {
  $distPath = Join-Path $FrontRoot "dist"
  Deploy-Static -Dist $distPath -WebRoot $WebRoot -Atomic:$AtomicDeploy
}

# Rapport CSV
if ($ReportPath) {
  if (-not $DryRun) {
    $dir = Split-Path $ReportPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  }
  $Report | Export-Csv -NoTypeInformation -Encoding UTF8 $ReportPath
  Ok "Rapport écrit: $ReportPath"
}

Ok "✅ Front prêt. Pour tester en local: cd `"$FrontRoot`"; npm run preview"
