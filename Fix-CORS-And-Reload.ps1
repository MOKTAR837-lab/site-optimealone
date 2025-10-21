$ErrorActionPreference="Stop"
$ROOT = $PSScriptRoot; if(-not $ROOT){ $ROOT=(Get-Location).Path }

function W([string]$p,[string]$c){ $d=Split-Path -Parent $p; if($d){New-Item -Force -Type Directory $d|Out-Null}; [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($false)) }

# 0) Retire tout override
Remove-Item (Join-Path $ROOT 'docker-compose.override.yml') -Force -ErrorAction Ignore

# 1) Corrige CORS dans ocr_api/app/main.py
$main = Join-Path $ROOT 'ocr_api\app\main.py'
if(!(Test-Path $main)){ throw "Introuvable: $main" }
Copy-Item $main "$main.bak" -Force
$code = Get-Content -Raw $main

# a) import CORSMiddleware si absent
if($code -notmatch 'from\s+fastapi\.middleware\.cors\s+import\s+CORSMiddleware'){
  if($code -match 'from\s+fastapi\s+import\s+[^\r\n]+'){
    $code = [regex]::Replace($code,'(from\s+fastapi\s+import\s+[^\r\n]+)','${1}'+"`r`nfrom fastapi.middleware.cors import CORSMiddleware",1)
  } else {
    $code = "from fastapi.middleware.cors import CORSMiddleware`r`n$code"
  }
}

# b) remplace tout bloc app.add_middleware(CORSMiddleware, ...) par un bloc propre
$pattern = 'app\.add_middleware\(\s*CORSMiddleware.*?\)\s*'
$replacement = "origins = [o.strip() for o in settings.CORS_ORIGINS.split(',') if o.strip()]`r`napp.add_middleware(CORSMiddleware, allow_origins=origins, allow_credentials=$true, allow_methods=['*'], allow_headers=['*'])`r`n"
$code = [regex]::Replace($code,$pattern,$replacement,[System.Text.RegularExpressions.RegexOptions]::Singleline)

# c) si aucun bloc trouvé, injecte après app = FastAPI(...)
if($code -notmatch 'app\.add_middleware\(\s*CORSMiddleware'){
  $code = [regex]::Replace($code,'(app\s*=\s*FastAPI\([^\)]*\))',"`$1`r`n$replacement",1,[System.Text.RegularExpressions.RegexOptions]::Singleline)
}

W $main $code

# 2) Force CORS_ORIGINS dans ocr_api/.env
$envp = Join-Path $ROOT 'ocr_api\.env'
$line = 'CORS_ORIGINS=http://localhost:3000'
if(Test-Path $envp){
  $t = Get-Content -Raw $envp
  if($t -match '^\s*CORS_ORIGINS\s*='){ $t=[regex]::Replace($t,'^\s*CORS_ORIGINS\s*=.*$', $line,'Multiline') } else { $t=$t.TrimEnd()+"`r`n$line`r`n" }
  W $envp $t
}else{ W $envp "$line`r`n" }

# 3) Rebuild + up
docker compose down --remove-orphans | Out-Null
docker compose build backend
docker compose up -d

Start-Sleep -Seconds 2
docker compose logs --tail=80 backend

# 4) Test API (utilise curl.exe, pas l’alias PowerShell)
& "$Env:SystemRoot\System32\curl.exe" -s -o NUL -w "%{http_code}`n" http://localhost:8000/healthz
