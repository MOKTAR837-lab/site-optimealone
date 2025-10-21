$ErrorActionPreference = "Stop"
$ROOT = (Get-Location).Path

function WriteUtf8($path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $enc = [System.Text.UTF8Encoding]::new($false)
  [IO.File]::WriteAllText($path, $content, $enc)
}

Write-Host "1) Supprimer override éventuel"
Remove-Item "$ROOT\docker-compose.override.yml" -Force -ErrorAction Ignore

Write-Host "2) Rebasculer le front sur http://localhost:8000 (ignore .astro cache)"
Get-ChildItem "$ROOT\frontend" -Recurse -Include *.ts,*.tsx,*.astro -File |
  Where-Object { $_.FullName -notmatch '\\\.astro\\' } |
  ForEach-Object {
    $txt = Get-Content -Raw $_.FullName
    $txt = $txt -replace 'http://localhost:8010','http://localhost:8000'
    WriteUtf8 $_.FullName $txt
  }

Write-Host "3) Forcer CORS_ORIGINS dans ocr_api/.env"
$apiEnv = "$ROOT\ocr_api\.env"
if(Test-Path $apiEnv){
  $envTxt = Get-Content -Raw $apiEnv
  $corsLine = "CORS_ORIGINS=http://localhost:3000"
  if($envTxt -match '^\s*CORS_ORIGINS\s*=' ){ 
    $envTxt = [regex]::Replace($envTxt,'^\s*CORS_ORIGINS\s*=.*$', $corsLine,'Multiline')
  } else {
    $envTxt = $envTxt.TrimEnd() + "`r`n$corsLine`r`n"
  }
  WriteUtf8 $apiEnv $envTxt
} else {
  WriteUtf8 $apiEnv "CORS_ORIGINS=http://localhost:3000`r`n"
}

Write-Host "4) Corriger ocr_api/app/main.py (bloc CORS)"
$mainCandidates = @(
  "$ROOT\ocr_api\app\main.py",
  "$ROOT\backend\app\main.py",
  "$ROOT\app\main.py"
)
$mainPath = $mainCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if(-not $mainPath){ throw "main.py introuvable sous ocr_api\app\ ou backend\app\" }

$code = Get-Content -Raw $mainPath

# Import CORSMiddleware
if($code -notmatch 'from\s+fastapi\.middleware\.cors\s+import\s+CORSMiddleware'){
  # insère après la première ligne d'import FastAPI si possible, sinon en tête
  if($code -match 'from\s+fastapi\s+import\s+[^\r\n]+'){
    $code = [regex]::Replace($code,'(from\s+fastapi\s+import\s+[^\r\n]+)','$1' + "`r`nfrom fastapi.middleware.cors import CORSMiddleware",1)
  } else {
    $code = "from fastapi.middleware.cors import CORSMiddleware`r`n" + $code
  }
}

# Variable origins
if($code -notmatch 'origins\s*=\s*\[o\.strip\(\) for o in settings\.CORS_ORIGINS\.split\('){
  # place origins après un import de settings si possible, sinon après les imports
  $origLine = "origins = [o.strip() for o in settings.CORS_ORIGINS.split(',') if o.strip()]"
  if($code -match 'settings\.CORS_ORIGINS'){
    # insère juste après la première occurrence de settings.CORS_ORIGINS dans le fichier
    $code = [regex]::Replace($code,'(settings\.CORS_ORIGINS[^\r\n]*\r?\n)',"`$1$origLine`r`n",1)
  } else {
    # insère après les imports
    $code = [regex]::Replace($code,'(\r?\n){2,}',"`r`n",1)
    $code = $code -replace '(\r?\n)(from\s|import\s)',$1 + "$origLine`r`n" + '$2',1
    if($code -notmatch [regex]::Escape($origLine)){ $code = $origLine + "`r`n" + $code }
  }
}

# Remplacer lignes fautives d'allow_origins
$code = [regex]::Replace($code,'allow_origins\s*=\s*settings\.CORS_ORIGINS\.split\([^\)]*\)[^\r\n]*','allow_origins=origins,')
$code = $code -replace 'allow_origins=settings\.CORS_ORIGINS\.split\(","\),"\) if o\],','allow_origins=origins,'

# Si aucun middleware CORS correct, injecter un bloc propre après la création de app
if($code -notmatch 'app\.add_middleware\(\s*CORSMiddleware'){
  # chercher ligne app = FastAPI(...)
  if($code -match 'app\s*=\s*FastAPI\([^\)]*\)'){
    $code = [regex]::Replace($code,
      '(app\s*=\s*FastAPI\([^\)]*\).*\r?\n)',
      "`$1`r`napp.add_middleware(CORSMiddleware,`r`n    allow_origins=origins,`r`n    allow_credentials=True,`r`n    allow_methods=['*'],`r`n    allow_headers=['*'],`r`n)`r`n",
      1, 'Singleline')
  } else {
    # injecte en fin de fichier par défaut
    $code += "`r`napp.add_middleware(CORSMiddleware,`r`n    allow_origins=origins,`r`n    allow_credentials=True,`r`n    allow_methods=['*'],`r`n    allow_headers=['*'],`r`n)`r`n"
  }
}

WriteUtf8 $mainPath $code
Write-Host "   Patch CORS appliqué à: $mainPath"

Write-Host "5) Rebuild & relance Docker"
docker compose down --remove-orphans | Out-Null
# Assainir le moteur si besoin
try { wsl --shutdown | Out-Null } catch {}
Start-Sleep -Seconds 2
docker compose build backend
docker compose up -d
Start-Sleep -Seconds 2
docker compose ps
docker compose logs --tail=80 backend

Write-Host "6) Test API (HTTP code attendu: 401 si non connecté)"
& "$Env:SystemRoot\System32\curl.exe" -s -o NUL -w "%{http_code}`n" http://localhost:8000/me
