param([int]$Port = 3000)
$ErrorActionPreference = "Stop"
$ROOT = $PSScriptRoot; if(-not $ROOT){ $ROOT = (Get-Location).Path }
Set-Location $ROOT

function WriteUtf8([string]$Path,[string]$Content){
  $dir = Split-Path -Parent $Path
  if($dir){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($Path,$Content,[Text.UTF8Encoding]::new($false))
}

Write-Host "1) Nettoyage override"
Remove-Item "$ROOT\docker-compose.override.yml" -Force -ErrorAction Ignore

Write-Host "2) Frontend: astro.config.mjs sur port $Port"
$astro = @"
import { defineConfig } from "astro/config";
import react from "@astrojs/react";
export default defineConfig({
  integrations: [react()],
  server: { port: __PORT__, host: true }
});
"@ -replace "__PORT__", $Port
WriteUtf8 "$ROOT\frontend\astro.config.mjs" $astro

Write-Host "3) Frontend: URLs API -> 8000 (ignore .astro cache)"
Get-ChildItem "$ROOT\frontend" -Recurse -File -Include *.ts,*.tsx,*.astro |
  Where-Object { $_.FullName -notmatch '\\\.astro\\' } |
  ForEach-Object {
    $t = Get-Content -Raw $_.FullName
    $t = $t -replace 'http://localhost:8010','http://localhost:8000'
    WriteUtf8 $_.FullName $t
  }

Write-Host "4) Backend: CORS_ORIGINS pour 3000 et 4321"
$corsLine = 'CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:4321,http://127.0.0.1:4321'
$envTargets = @("$ROOT\.env","$ROOT\backend\.env")
foreach($p in $envTargets){
  $txt = (Test-Path $p) ? (Get-Content -Raw $p) : ""
  if($txt -match '^\s*CORS_ORIGINS\s*=' ){
    $txt = [regex]::Replace($txt,'^\s*CORS_ORIGINS\s*=.*$', $corsLine,'Multiline')
  } else {
    if($txt.Trim().Length -gt 0){ $txt = $txt.TrimEnd()+"`r`n" }
    $txt += $corsLine+"`r`n"
  }
  WriteUtf8 $p $txt
}

Write-Host "5) Backend: patch CORS si ligne cassée"
$mainPath = Get-ChildItem -Recurse -File -Filter main.py |
  Where-Object { $_.FullName -match '\\backend\\app\\main\.py$' } |
  Select-Object -First 1
if(-not $mainPath){ throw "backend\app\main.py introuvable" }

$bad = 'allow_origins=settings.CORS_ORIGINS.split(","),") if o],'
$good = 'allow_origins=[o.strip() for o in settings.CORS_ORIGINS.split(",") if o.strip()],'
$code = Get-Content -Raw $mainPath.FullName
$changed = $false
if($code -like "*$bad*"){ $code = $code -replace [regex]::Escape($bad), $good; $changed=$true }
if($code -notmatch 'from\s+fastapi\.middleware\.cors\s+import\s+CORSMiddleware'){
  if($code -match 'from\s+fastapi\s+import\s+[^\r\n]+'){
    $code = [regex]::Replace($code,'(from\s+fastapi\s+import\s+[^\r\n]+)','${1}'+"`r`nfrom fastapi.middleware.cors import CORSMiddleware",1)
  } else { $code = "from fastapi.middleware.cors import CORSMiddleware`r`n$code" }
  $changed = $true
}
if($changed){
  Copy-Item $mainPath.FullName ($mainPath.FullName + ".bak") -Force
  WriteUtf8 $mainPath.FullName $code
}

Write-Host "6) Rebuild + Up"
docker compose down --remove-orphans | Out-Null
docker compose build backend
docker compose up -d

Write-Host "7) Vérifs"
docker compose ps
Write-Host "`nAPI /api/health → code HTTP attendu 200:"
& "$Env:SystemRoot\System32\curl.exe" -s -o NUL -w "%{http_code}`n" http://localhost:8000/api/health
Write-Host "`nFront → http://localhost:$Port/"

