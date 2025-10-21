
 param([int]$Port = 3000)
$ErrorActionPreference = "Stop"

# Racine sûre
$ROOT = $PSScriptRoot
if (-not $ROOT) { $ROOT = (Get-Location).Path }
Set-Location $ROOT

function WriteUtf8([string]$Path,[string]$Content){
  $dir = Split-Path -Parent $Path
  if($dir){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path,$Content,$enc)
}

Write-Host "1) Supprimer tout override"
Remove-Item "$ROOT\docker-compose.override.yml" -Force -ErrorAction Ignore

Write-Host "2) Frontend: astro.config.mjs (port $Port)"
$astro = @"
import { defineConfig } from "astro/config";
import react from "@astrojs/react";
export default defineConfig({
  integrations: [react()],
  server: { port: __PORT__, host: true }
});
"@
$astro = $astro -replace "__PORT__", $Port
WriteUtf8 "$ROOT\frontend\astro.config.mjs" $astro

Write-Host "3) Frontend: remettre les URLs API sur 8000 (ignore le cache .astro)"
$frontFiles = Get-ChildItem "$ROOT\frontend" -Recurse -File -Include *.ts,*.tsx,*.astro | Where-Object { $_.FullName -notmatch '\\\.astro\\' }
foreach($f in $frontFiles){
  $t = Get-Content -Raw $f.FullName
  $t = $t -replace 'http://localhost:8010','http://localhost:8000'
  WriteUtf8 $f.FullName $t
}

Write-Host "4) Backend: CORS_ORIGINS pour $Port et 4321"
$corsLine = "CORS_ORIGINS=http://localhost:$Port,http://127.0.0.1:$Port,http://localhost:4321,http://127.0.0.1:4321"
$envTargets = @("$ROOT\.env","$ROOT\backend\.env","$ROOT\ocr_api\.env")
foreach($p in $envTargets){
  $txt = ""
  if(Test-Path $p){ $txt = Get-Content -Raw $p }
  if($txt -match '^\s*CORS_ORIGINS\s*='){
    $txt = [regex]::Replace($txt,'^\s*CORS_ORIGINS\s*=.*$', $corsLine,'Multiline')
  } else {
    if($txt.Trim().Length -gt 0){ $txt = $txt.TrimEnd()+"`r`n" }
    $txt += $corsLine+"`r`n"
  }
  WriteUtf8 $p $txt
}

Write-Host "5) Backend: patch CORS si nécessaire (backend/app/main.py)"
# localiser main.py
$mainPath = $null
$try1 = Join-Path $ROOT "backend\app\main.py"
$try2 = Join-Path $ROOT "ocr_api\app\main.py"
if(Test-Path $try1){ $mainPath = $try1 } elseif(Test-Path $try2){ $mainPath = $try2 } else {
  $cand = Get-ChildItem -Recurse -File -Filter main.py | Where-Object { $_.FullName -match '\\app\\main\.py$' } | Select-Object -First 1
  if($cand){ $mainPath = $cand.FullName }
}
if(-not $mainPath){ throw "main.py introuvable (attendu: backend\app\main.py)" }

$code = Get-Content -Raw $mainPath
$changed = $false

# a) import CORSMiddleware si absent
if($code -notmatch 'from\s+fastapi\.middleware\.cors\s+import\s+CORSMiddleware'){
  if($code -match 'from\s+fastapi\s+import\s+[^\r\n]+'){
    $code = [regex]::Replace($code,'(from\s+fastapi\s+import\s+[^\r\n]+)','${1}'+"`r`nfrom fastapi.middleware.cors import CORSMiddleware",1)
  } else {
    $code = "from fastapi.middleware.cors import CORSMiddleware`r`n$code"
  }
  $changed = $true
}

# b) assurer la variable origins
if($code -notmatch 'origins\s*=\s*\[o\.strip\(\)\s+for\s+o\s+in\s+settings\.CORS_ORIGINS\.split'){
  $code = $code + "`r`norigins = [o.strip() for o in settings.CORS_ORIGINS.split(',') if o.strip()]`r`n"
  $changed = $true
}

# c) normaliser allow_origins=...
$norm = [regex]::Replace($code,'allow_origins\s*=\s*[^,]+,','allow_origins=origins,')
if($norm -ne $code){ $code = $norm; $changed = $true }

if($changed){
  Copy-Item $mainPath ($mainPath + ".bak") -Force
  WriteUtf8 $mainPath $code
  Write-Host "   -> Patch appliqué à $mainPath (backup .bak)"
} else {
  Write-Host "   -> Aucun patch CORS requis"
}

Write-Host "6) Rebuild & Up"
docker compose down --remove-orphans | Out-Null
docker compose build backend
docker compose up -d

Write-Host "7) Vérifs"
docker compose ps

# Tests API: /api/health ou /health selon app
$curl = Join-Path $Env:SystemRoot "System32\curl.exe"
Write-Host "`nTest /api/health :"
& $curl -s -o NUL -w "%{http_code}`n" http://localhost:8000/api/health
Write-Host "Test /health :"
& $curl -s -o NUL -w "%{http_code}`n" http://localhost:8000/health
Write-Host "Test /docs :"
& $curl -s -o NUL -w "%{http_code}`n" http://localhost:8000/docs

Write-Host "`nFront → http://localhost:$Port/"
