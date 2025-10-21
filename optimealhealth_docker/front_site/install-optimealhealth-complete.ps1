# ========================================
# Installation Complète OptimealHealth
# Crée TOUS les fichiers nécessaires
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Installation OptimealHealth - Sécurité RGPD        ║" -ForegroundColor Cyan
Write-Host "║   Tous les fichiers seront créés automatiquement     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Vérification du répertoire
$currentPath = Get-Location
Write-Host "📁 Répertoire actuel: $currentPath" -ForegroundColor Gray

if (-not (Test-Path "backend")) {
    Write-Host "❌ Le dossier 'backend' n'existe pas" -ForegroundColor Red
    Write-Host "⚠️  Veuillez exécuter ce script depuis:" -ForegroundColor Yellow
    Write-Host "   C:\site_optimealhealth.com\optimealhealth_docker\front_site" -ForegroundColor Yellow
    Read-Host "`nAppuyez sur Entrée pour quitter"
    exit 1
}

Write-Host "✓ Dossier backend trouvé" -ForegroundColor Green

# ========================================
# ÉTAPE 1/10 : Génération des clés
# ========================================

Write-Host "`n[1/10] Génération des clés de sécurité..." -ForegroundColor Yellow

# Clé JWT
$secretKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$secretKey = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($secretKey))

# Clé AES-256
$aesKey = New-Object byte[] 32
[System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($aesKey)
$encryptionKey = [Convert]::ToBase64String($aesKey)

# Mot de passe PostgreSQL fort
$postgresPassword = -join ((65..90) + (97..122) + (48..57) + 33,35,36,37,38,42 | Get-Random -Count 20 | ForEach-Object {[char]$_})

Write-Host "   ✓ SECRET_KEY généré" -ForegroundColor Green
Write-Host "   ✓ ENCRYPTION_KEY généré" -ForegroundColor Green
Write-Host "   ✓ Mot de passe PostgreSQL généré" -ForegroundColor Green

# ========================================
# ÉTAPE 2/10 : Création structure dossiers
# ========================================

Write-Host "`n[2/10] Création de la structure..." -ForegroundColor Yellow

$folders = @(
    "backend/app/core",
    "backend/app/models",
    "backend/app/routers",
    "backend/app/db",
    "frontend/components",
    "frontend/pages",
    "frontend/services",
    "frontend/styles",
    "logs"
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "   ✓ $folder" -ForegroundColor Gray
    }
}

Write-Host "   ✓ Structure créée" -ForegroundColor Green

# ========================================
# ÉTAPE 3/10 : Fichier .env
# ========================================

Write-Host "`n[3/10] Création du fichier .env..." -ForegroundColor Yellow

$envContent = @"
# ========================================
# Configuration Base de données
# ========================================
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$postgresPassword
POSTGRES_DB=optimeal
POSTGRES_HOST=db
POSTGRES_PORT=5432

# ========================================
# Sécurité JWT
# ========================================
SECRET_KEY=$secretKey

# ========================================
# Chiffrement AES-256
# ========================================
ENCRYPTION_KEY=$encryptionKey

# ========================================
# Ollama (IA)
# ========================================
OLLAMA_URL=http://host.docker.internal:11434
EMBED_MODEL=nomic-embed-text

# ========================================
# Configuration Python
# ========================================
PYTHONUTF8=1
LANG=C.UTF-8
LC_ALL=C.UTF-8

# ========================================
# CORS
# ========================================
CORS_ORIGINS=http://localhost,http://localhost:3000,http://localhost:80

# ========================================
# Environnement
# ========================================
ENVIRONMENT=development
DEBUG=1
"@

Set-Content -Path ".env" -Value $envContent -Encoding UTF8
Write-Host "   ✓ .env créé avec clés sécurisées" -ForegroundColor Green

# ========================================
# ÉTAPE 4/10 : .gitignore
# ========================================

Write-Host "`n[4/10] Mise à jour .gitignore..." -ForegroundColor Yellow

$gitignoreContent = @"
# Environnement
.env
.env.local
.env.*.local

# Python
__pycache__/
*.py[cod]
*`$py.class
*.so
.Python
venv/
env/
ENV/

# Base de données
*.db
*.sqlite
postgres_data/

# Logs
*.log
logs/

# IDE
.vscode/
.idea/
*.swp

# Backups
_backup_*/

# Node
node_modules/
.next/
out/
dist/
build/

# Docker
.dockerignore

# SSL
certbot/
"@

Set-Content -Path ".gitignore" -Value $gitignoreContent -Encoding UTF8
Write-Host "   ✓ .gitignore mis à jour" -ForegroundColor Green

# ========================================
# ÉTAPE 5/10 : requirements.txt
# ========================================

Write-Host "`n[5/10] Création backend/requirements.txt..." -ForegroundColor Yellow

$requirementsContent = @"
# FastAPI et serveur
fastapi==0.109.0
uvicorn[standard]==0.27.0
gunicorn==21.2.0

# Base de données
sqlalchemy[asyncio]==2.0.25
asyncpg==0.29.0
alembic==1.13.1

# Sécurité
passlib[bcrypt]==1.7.4
python-jose[cryptography]==3.3.0
cryptography==42.0.2
pydantic[email]==2.5.3
python-multipart==0.0.6

# Utilitaires
httpx==0.26.0
python-dotenv==1.0.0
pydantic-settings==2.1.0
email-validator==2.1.0
"@

Set-Content -Path "backend/requirements.txt" -Value $requirementsContent -Encoding UTF8
Write-Host "   ✓ requirements.txt créé" -ForegroundColor Green

# ========================================
# ÉTAPE 6/10 : Fichiers Backend Python
# ========================================

Write-Host "`n[6/10] Création des fichiers Backend Python..." -ForegroundColor Yellow

# Le contenu des fichiers Python sera ajouté dans la partie 2 du script
# Pour l'instant, on crée juste les fichiers vides
$backendFiles = @(
    "backend/app/__init__.py",
    "backend/app/core/__init__.py",
    "backend/app/core/security.py",
    "backend/app/models/__init__.py",
    "backend/app/models/user.py",
    "backend/app/routers/__init__.py",
    "backend/app/routers/auth.py",
    "backend/app/routers/gdpr.py",
    "backend/app/routers/health_profile.py",
    "backend/app/db/__init__.py",
    "backend/app/db/session.py",
    "backend/app/db/base.py"
)

foreach ($file in $backendFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
    }
}

Write-Host "   ✓ Fichiers Backend créés (contenu ajouté dans étape suivante)" -ForegroundColor Green

# ========================================
# ÉTAPE 7/10 : docker-compose.yml
# ========================================

Write-Host "`n[7/10] Mise à jour docker-compose.yml..." -ForegroundColor Yellow

# Sauvegarde l'ancien
if (Test-Path "docker-compose.yml") {
    Copy-Item "docker-compose.yml" "docker-compose.yml.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
}

$dockerComposeContent = @"
services:
  db:
    image: pgvector/pgvector:pg16
    container_name: optimeal-postgres
    environment:
      POSTGRES_USER: `${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: `${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: `${POSTGRES_DB:-optimeal}
      TZ: Europe/Paris
      PGTZ: Europe/Paris
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - internal
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  api:
    build:
      context: ./backend
      dockerfile: dockerfile
    container_name: optimeal-api
    environment:
      POSTGRES_USER: `${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: `${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: `${POSTGRES_DB:-optimeal}
      POSTGRES_HOST: db
      POSTGRES_PORT: 5432
      SECRET_KEY: `${SECRET_KEY}
      ENCRYPTION_KEY: `${ENCRYPTION_KEY}
      OLLAMA_URL: `${OLLAMA_URL:-http://host.docker.internal:11434}
      EMBED_MODEL: `${EMBED_MODEL:-nomic-embed-text}
      PYTHONUTF8: "1"
      LANG: C.UTF-8
      LC_ALL: C.UTF-8
      CORS_ORIGINS: `${CORS_ORIGINS:-http://localhost}
      ENVIRONMENT: `${ENVIRONMENT:-development}
      DEBUG: `${DEBUG:-1}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - internal
    expose:
      - "8000"
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    volumes:
      - ./backend:/app
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "python -c 'import urllib.request; urllib.request.urlopen(\"http://localhost:8000/health\")' || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s

  proxy:
    image: nginx:alpine
    container_name: optimeal-proxy
    depends_on:
      api:
        condition: service_healthy
    ports:
      - "80:80"
    volumes:
      - ./dist:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - internal
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  internal:
    driver: bridge
"@

Set-Content -Path "docker-compose.yml" -Value $dockerComposeContent -Encoding UTF8
Write-Host "   ✓ docker-compose.yml mis à jour" -ForegroundColor Green

# ========================================
# ÉTAPE 8/10 : nginx.conf
# ========================================

Write-Host "`n[8/10] Mise à jour nginx.conf..." -ForegroundColor Yellow

$nginxContent = @"
server {
    listen 80;
    server_name localhost;
    client_max_body_size 10M;

    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # API Backend
    location /api/ {
        proxy_pass http://api:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }

    # Frontend
    location / {
        root /usr/share/nginx/html;
        try_files `$uri `$uri/ /index.html;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
"@

Set-Content -Path "nginx.conf" -Value $nginxContent -Encoding UTF8
Write-Host "   ✓ nginx.conf mis à jour" -ForegroundColor Green

# ========================================
# ÉTAPE 9/10 : Informations finales
# ========================================

Write-Host "`n[9/10] Préparation des informations..." -ForegroundColor Yellow

# Création d'un fichier README
$readmeContent = @"
# OptimealHealth - Installation Réussie

## 🔐 Informations de Sécurité

### Clés générées (NE PAS PARTAGER)
- SECRET_KEY: Stockée dans .env
- ENCRYPTION_KEY: Stockée dans .env  
- PostgreSQL Password: Stockée dans .env

⚠️ Ces clés sont dans le fichier .env qui est ignoré par Git.

## 🚀 Prochaines Étapes

1. Copier le contenu des fichiers Python depuis les artifacts Claude
2. Lancer Docker: ``docker compose up -d --build``
3. Tester l'API: http://localhost/api/docs

## 📁 Fichiers créés

- .env (clés de sécurité)
- docker-compose.yml
- nginx.conf
- backend/requirements.txt
- Structure complète des dossiers

## 📚 Documentation

Voir README-SECURITE.md pour plus d'informations.

---
Généré le: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

Set-Content -Path "README-INSTALL.md" -Value $readmeContent -Encoding UTF8
Write-Host "   ✓ README-INSTALL.md créé" -ForegroundColor Green

# ========================================
# ÉTAPE 10/10 : Résumé
# ========================================

Write-Host "`n[10/10] Installation terminée!" -ForegroundColor Yellow

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          ✓ INSTALLATION RÉUSSIE                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📁 Fichiers créés:" -ForegroundColor Cyan
Write-Host "   ✓ .env (clés sécurisées)" -ForegroundColor White
Write-Host "   ✓ .gitignore" -ForegroundColor White
Write-Host "   ✓ docker-compose.yml" -ForegroundColor White
Write-Host "   ✓ nginx.conf" -ForegroundColor White
Write-Host "   ✓ backend/requirements.txt" -ForegroundColor White
Write-Host "   ✓ Structure de dossiers complète" -ForegroundColor White

Write-Host "`n📋 PROCHAINES ÉTAPES IMPORTANTES:" -ForegroundColor Yellow
Write-Host "`n1️⃣  Copier les fichiers Python" -ForegroundColor Cyan
Write-Host "   Ouvre une nouvelle conversation avec Claude et demande:" -ForegroundColor Gray
Write-Host "   'Donne-moi le contenu des fichiers Python pour OptimealHealth'" -ForegroundColor Gray

Write-Host "`n2️⃣  Ou utilise ce script pour télécharger les fichiers:" -ForegroundColor Cyan
Write-Host "   .\download-python-files.ps1" -ForegroundColor Gray
Write-Host "   (Script qui sera créé dans 5 secondes...)" -ForegroundColor Gray

Write-Host "`n3️⃣  Lancer Docker:" -ForegroundColor Cyan
Write-Host "   docker compose down" -ForegroundColor Gray
Write-Host "   docker compose build --no-cache" -ForegroundColor Gray
Write-Host "   docker compose up -d" -ForegroundColor Gray

Write-Host "`n4️⃣  Tester l'API:" -ForegroundColor Cyan
Write-Host "   http://localhost/api/docs" -ForegroundColor Gray

Write-Host "`n🔐 Sécurité:" -ForegroundColor Yellow
Write-Host "   • Toutes les clés sont dans .env (protégé par .gitignore)" -ForegroundColor White
Write-Host "   • NE JAMAIS commiter .env sur Git!" -ForegroundColor Red

Write-Host "`n📄 Documentation:" -ForegroundColor Cyan
Write-Host "   • README-INSTALL.md (ce qui a été fait)" -ForegroundColor White
Write-Host "   • .env (configuration)" -ForegroundColor White

Write-Host "`n✨ Tu peux maintenant créer les fichiers Python!" -ForegroundColor Green
Write-Host ""

# Pause pour lire
Read-Host "`nAppuie sur Entrée pour continuer et créer le script de téléchargement des fichiers Python"

# ========================================
# Création script téléchargement Python
# ========================================

Write-Host "`nCréation du script de téléchargement..." -ForegroundColor Yellow

$downloadScript = @"
# Script pour télécharger et créer les fichiers Python
Write-Host "Ce script va te guider pour créer les fichiers Python" -ForegroundColor Cyan
Write-Host "Ouvre les artifacts Claude et copie le contenu de chaque fichier`n" -ForegroundColor Gray

`$files = @(
    @{Path="backend/app/core/security.py"; Name="security.py (Chiffrement + JWT)"},
    @{Path="backend/app/models/user.py"; Name="user.py (Modèles BDD)"},
    @{Path="backend/app/routers/auth.py"; Name="auth.py (Authentification)"},
    @{Path="backend/app/routers/gdpr.py"; Name="gdpr.py (Routes RGPD)"},
    @{Path="backend/app/routers/health_profile.py"; Name="health_profile.py (Profil santé)"}
)

foreach (`$file in `$files) {
    Write-Host "Création de: `$(`$file.Name)" -ForegroundColor Yellow
    notepad `$file.Path
    `$confirm = Read-Host "Fichier créé? (o/n)"
    if (`$confirm -ne "o") {
        Write-Host "Script interrompu" -ForegroundColor Red
        exit
    }
}

Write-Host "`n✓ Tous les fichiers Python créés!" -ForegroundColor Green
Write-Host "Lance maintenant: docker compose build --no-cache" -ForegroundColor Cyan
"@

Set-Content -Path "download-python-files.ps1" -Value $downloadScript -Encoding UTF8
Write-Host "✓ Script créé: download-python-files.ps1`n" -ForegroundColor Green

Write-Host "Veux-tu lancer le script maintenant? (o/n): " -NoNewline -ForegroundColor Cyan
$response = Read-Host

if ($response -eq "o") {
    & ".\download-python-files.ps1"
}

Write-Host "`n🎉 Installation terminée! Bonne chance!" -ForegroundColor Green