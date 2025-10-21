# Fix-Backend-Min.ps1 — patch ciblé, sans override
$ErrorActionPreference="Stop"
$ROOT = (Get-Location).Path

function W([string]$p,[string]$c){ $d=Split-Path -Parent $p; if($d){New-Item -Force -Type Directory $d|Out-Null}; [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($false)) }

# 0) Pas d'override
Remove-Item "$ROOT\docker-compose.override.yml" -Force -ErrorAction Ignore

# 1) Fichier main.py à patcher (backend/app/main.py ou équivalent)
$main = Get-ChildItem -Recurse -File -Filter main.py |
  Where-Object { $_.FullName -match '\\backend\\app\\main\.py$' -or $_.FullName -match '\\app\\main\.py$' } |
  Select-Object -First 1
if(-not $main){ throw "main.py introuvable (cherche backend\app\main.py)" }

# 2) Patch CORS: remplacer UNIQUEMENT la ligne cassée
$bad = 'allow_origins=settings.CORS_ORIGINS.split(","),") if o],'
$good = 'allow_origins=[o.strip() for o in settings.CORS_ORIGINS.split(",") if o.strip()],'
$code = Get-Content -Raw $main.FullName
$changed = $false
if($code -like "*$bad*"){ $code = $code -replace [regex]::Escape($bad), $good; $changed = $true }

# Ajouter l'import CORSMiddleware si absent (sans toucher le reste)
if($code -notmatch 'from\s+fastapi\.middleware\.cors\s+import\s+CORSMiddleware'){
  if($code -match 'from\s+fastapi\s+import\s+[^\r\n]+'){
    $code = [regex]::Replace($code,'(from\s+fastapi\s+import\s+[^\r\n]+)','${1}'+"`r`nfrom fastapi.middleware.cors import CORSMiddleware",1)
  } else {
    $code = "from fastapi.middleware.cors import CORSMiddleware`r`n$code"
  }
  $changed = $true
}

if($changed){
  Copy-Item $main.FullName ($main.FullName + ".bak") -Force
  W $main.FullName $code
  Write-Host "Patch appliqué: $($main.FullName)"
} else {
  Write-Host "Aucun patch nécessaire: $($main.FullName)"
}

# 3) Forcer CORS_ORIGINS côté backend (.env)
$apiEnv = @("$ROOT\backend\.env","$ROOT\ocr_api\.env") | Where-Object { Test-Path $_ } | Select-Object -First 1
if(-not $apiEnv){ $apiEnv = "$ROOT\backend\.env" }
$t = (Test-Path $apiEnv) ? (Get-Content -Raw $apiEnv) : ""
$line='CORS_ORIGINS=http://localhost:3000'
if($t -match '^\s*CORS_ORIGINS\s*='){ $t=[regex]::Replace($t,'^\s*CORS_ORIGINS\s*=.*$', $line,'Multiline') } else { $t=$t.TrimEnd()+"`r`n$line`r`n" }
W $apiEnv $t
Write-Host "CORS_ORIGINS fixé dans: $apiEnv"

# 4) Rebuild + up
docker compose down --remove-orphans | Out-Null
wsl --shutdown | Out-Null
Start-Sleep -Seconds 2
docker compose build backend
docker compose up -d
Start-Sleep -Seconds 2

# 5) Logs + test
docker compose logs --tail=80 backend
& "$Env:SystemRoot\System32\curl.exe" -s -o NUL -w "%{http_code}`n" http://localhost:8000/docs
