param(
  [string] $Image = "ghcr.io/moktar837-lab/site-optimealone:latest",
  [int]    $HttpPort = 80,          # Port hôte
  [int]    $ContainerPort = 8080,   # Port exposé par le container (ton image écoute 8080)
  [string] $Site = "http://localhost",
  [string] $BackendUrl = "http://backend:8000",
  [string] $ApiBase = "/api/v1",
  [switch] $Start
)

# 1) Contenu docker-compose.yml (interpolation activée)
$compose = @"
services:
  web:
    image: $Image
    ports:
      - "$($HttpPort):$($ContainerPort)"
    environment:
      SITE: "$Site"
      BACKEND_URL: "$BackendUrl"
      API_BASE: "$ApiBase"
    restart: unless-stopped
"@

# 2) Écrire le fichier
$path = Join-Path (Get-Location) "docker-compose.yml"
$compose | Set-Content -Path $path -Encoding utf8
Write-Host " Fichier généré : $path" -ForegroundColor Green

# 3) Petit rappel
Write-Host "Astuce : ajuste SITE/BACKEND_URL/API_BASE via les paramètres du script." -ForegroundColor Yellow

# 4) (Optionnel) Démarrer le stack
if ($Start) {
  try { docker version | Out-Null } catch {
    Write-Error "Docker ne semble pas démarré. Lance Docker Desktop puis relance avec -Start."
    exit 1
  }
  Write-Host " Démarrage : docker compose up -d" -ForegroundColor Cyan
  docker compose up -d
  if ($LASTEXITCODE -eq 0) {
    Write-Host " Stack démarré. Ouvre http://localhost:$HttpPort" -ForegroundColor Green
  } else {
    Write-Warning "Le démarrage a retourné un code non nul ($LASTEXITCODE). Vérifie 'docker compose logs'."
  }
}
