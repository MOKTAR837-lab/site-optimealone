# Optimeal Health — Frontend Astro

## Démarrage
```bash
npm install
cp .env.example .env
npm run dev
```

## Variables
- SITE (par ex. http://localhost:4321)
- BACKEND_URL (par ex. http://localhost:8000)
- API_BASE (par ex. /api/v1)
- STRIPE_PUBLIC_KEY (clé publique test)

## Proxies API
Les routes `/api/*` proxient vers `${BACKEND_URL}${API_BASE}` pour éviter le CORS.

## Build
```bash
npm run build && npm run preview
```
