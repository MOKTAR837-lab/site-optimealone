param(
  # Image de ton site
  [string] $Image = "ghcr.io/moktar837-lab/site-optimealone:latest",

  # Domaine public pointant vers ton serveur (A/AAAA dans DNS)
  [string] $Domain = "site.example.com",

  # Email pour Let's Encrypt (obligatoire pour HTTPS auto propre)
  [string] $Email = "admin@site.example.com",

  # Ports hôte à exposer
  [int] $HttpPort = 80,
  [int] $HttpsPort = 443,

  # Port du conteneur web (ce que ton image écoute)
  [int] $ContainerPort = 8080,

  # Variables app
  [string] $Site = "https://site.example.com",
  [string] $BackendUrl = "http://backend:8000",
  [string] $ApiBase = "/api/v1",

  # Démarrer automatiquement après génération
  [switch] $Start
)

# 1) Compose (proxy + web)
$compose = @"
services:
  web:
    image: $Image
    environment:
      SITE: "$Site"
      BACKEND_URL: "$BackendUrl"
      API_BASE: "$ApiBase"
    networks:
      - webnet
    restart: unless-stopped

  caddy:
    image: caddy:2
    depends_on:
      - web
    ports:
      - "$($HttpPort):80"
      - "$($HttpsPort):443"
    environment:
      # Pour ACME/Let's Encrypt
      ACME_AGREE: "true"
      EMAIL: "$Email"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - webnet
    restart: unless-stopped

networks:
  webnet:

volumes:
  caddy_data:
  caddy_config:
"@

# 2) Caddyfile
$caddy = @"
{
  email $Email
  # logging basique
  log {
    output stdout
    format console
    level INFO
  }
  # compression
  encode gzip zstd
}

$Domain {
  @secureHeaders {
    header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    header X-Content-Type-Options "nosniff"
    header X-Frame-Options "DENY"
    header Referrer-Policy "strict-origin-when-cross-origin"
    header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https:;"
  }

  handle {
    import secureHeaders
    reverse_proxy web:$ContainerPort
  }

  @health {
    path /health
  }
  respond @health 200
}
"@

# 3) Écrire les fichiers
$composePath = Join-Path (Get-Location) "docker-compose.proxy.yml"
$caddyPath   = Join-Path (Get-Location) "Caddyfile"

$compose | Set-Content -Path $composePath -Encoding utf8
$caddy   | Set-Content -Path $caddyPath   -Encoding utf8

Write-Host " Généré : $composePath" -ForegroundColor Green
Write-Host " Généré : $caddyPath"   -ForegroundColor Green

Write-Host "`n  Rappels :" -ForegroundColor Yellow
Write-Host "  1) Crée un enregistrement DNS A (et AAAA si IPv6) pour $Domain vers l'IP de ton serveur." -ForegroundColor Yellow
Write-Host "  2) Ouvre les ports $HttpPort/$HttpsPort sur le firewall." -ForegroundColor Yellow

# 4) (Optionnel) Démarrer
if ($Start) {
  try { docker version | Out-Null } catch {
    Write-Error "Docker ne semble pas démarré. Lance Docker Desktop / service Docker puis relance avec -Start."
    exit 1
  }

  Write-Host "`n Démarrage : docker compose -f docker-compose.proxy.yml up -d" -ForegroundColor Cyan
  docker compose -f docker-compose.proxy.yml up -d

  if ($LASTEXITCODE -eq 0) {
    Write-Host " Stack en ligne. Essaye : https://$Domain" -ForegroundColor Green
    Write-Host "   (le certificat Let's Encrypt peut prendre ~30s la 1ère fois)" -ForegroundColor DarkGray
  } else {
    Write-Warning "Le démarrage a retourné $LASTEXITCODE. Regarde 'docker compose -f docker-compose.proxy.yml logs -f caddy'."
  }
}
