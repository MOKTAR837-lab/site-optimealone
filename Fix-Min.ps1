# Fix-Min.ps1 — rollback override, corrige CORS, rebuild backend
$ErrorActionPreference="Stop"
$ROOT = (Get-Location).Path

# 0) Pas d'override
Remove-Item "$ROOT\docker-compose.override.yml" -Force -ErrorAction Ignore

# 1) CORS_ORIGINS dans ocr_api/.env
$apiEnv="$ROOT\ocr_api\.env"
if(Test-Path $apiEnv){
  $t=Get-Content -Raw $apiEnv
  $line='CORS_ORIGINS=http://localhost:3000'
  if($t -match '^\s*CORS_ORIGINS\s*='){ $t=[regex]::Replace($t,'^\s*CORS_ORIGINS\s*=.*$', $line,'Multiline') }
  else { $t=$t.TrimEnd()+"`r`n$line`r`n" }
  [IO.File]::WriteAllText($apiEnv,$t,[Text.UTF8Encoding]::new($false))
}

# 2) Patch ocr_api/app/main.py (sécurisé)
$main = Join-Path $ROOT 'ocr_api\app\main.py'
if(-not (Test-Path $main)){ throw "introuvable: $main" }
Copy-Item $main "$main.bak" -Force

$code = Get-Content -Raw $main

# a) s'assurer de l'import CORS
if($code -notmatch 'from\s+fastapi\.middleware\.cors\s+import\s+CORSMiddleware'){
  $code = $code -replace '(^from\s+fastapi\s+import[^\r\n]*\r?\n)','${1}from fastapi.middleware.cors import CORSMiddleware'+"`r`n",1
}

# b) remplacer tout allow_origins=... par une liste propre
$code = [regex]::Replace($code,
  'allow_origins\s*=\s*[^,]+,',
  "allow_origins=[o.strip() for o in settings.CORS_ORIGINS.split(',') if o.strip()],"
)

[IO.File]::WriteAllText($main,$code,[Text.UTF8Encoding]::new($false))

# 3) Rebuild + up
docker compose down --remove-orphans | Out-Null
wsl --shutdown | Out-Null
Start-Sleep -Seconds 2
docker compose build backend
docker compose up -d
Start-Sleep -Seconds 2

# 4) Logs + test
docker compose logs --tail=80 backend
& "$Env:SystemRoot\System32\curl.exe" -s -o NUL -w "%{http_code}`n" http://localhost:8000/me
