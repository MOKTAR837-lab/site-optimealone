param(
  [string] $Old1 = "optimealone",
  [string] $New1 = "optimealone",
  [switch] $StartCommit = $true
)

# --- 0) PrÃ©checks
git status | Out-Null
if ($LASTEXITCODE -ne 0) { throw "âš ï¸ Pas un repo Git ici." }

# --- 1) Nouvelle branche
$branch = "chore/rename-$Old1-to-$New1"
git checkout -b $branch

# --- 2) Extensions texte Ã  traiter
$exts = @(".js",".ts",".tsx",".astro",".css",".scss",".html",".md",".yml",".yaml",".json",".toml",
          ".env",".env.example",".ps1",".sh",".py",".conf",".txt",".mjs",".cjs",".dockerignore",".gitattributes",".gitignore")

# Dossiers Ã  exclure
$excludeDirs = @(".git","node_modules",".next","dist","build","coverage",".venv","venv",".cache",".output",".pnpm-store")

# Fichiers binaires Ã  exclure (par extension)
$binExt = @(".png",".jpg",".jpeg",".gif",".webp",".avif",".pdf",".zip",".7z",".tar",".gz",".rar",".mp4",".mov",".mp3",".wav")

# Helper : savoir si on doit ignorer un chemin
function Should-Skip([IO.FileInfo]$f) {
  if ($binExt -contains $f.Extension.ToLower()) { return $true }
  foreach ($d in $excludeDirs) {
    if ($f.FullName -match [regex]::Escape([IO.Path]::DirectorySeparatorChar+$d+[IO.Path]::DirectorySeparatorChar)) { return $true }
  }
  return $false
}

# --- 3) Remplacements dans le contenu (3 cas de casse)
$repls = @(
  @{ old="optimealone"; new="optimealone" },
  @{ old="optimealone"; new="Optimealone" },
  @{ old="optimealone"; new="OPTIMEALONE" }
)

$files = Get-ChildItem -Recurse -File | Where-Object {
  -not (Should-Skip $_) -and ($exts -contains $_.Extension.ToLower())
}

foreach ($file in $files) {
  $txt = Get-Content -Raw -LiteralPath $file.FullName
  $orig = $txt
  foreach ($rp in $repls) {
    $txt = $txt -replace [regex]::Escape($rp.old), $rp.new
  }
  if ($txt -ne $orig) {
    $txt | Set-Content -LiteralPath $file.FullName -Encoding UTF8
    Write-Host "âœï¸  ModifiÃ©: $($file.FullName)"
  }
}

# --- 4) Renommer les fichiers et dossiers portant lâ€™ancien nom
# On commence par les fichiers, puis les dossiers, du plus profond vers la racine
$targets = Get-ChildItem -Recurse -Force | Where-Object {
  $_.Name -match $Old1 -and -not (Should-Skip $_)
} | Sort-Object { $_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count } -Descending

foreach ($t in $targets) {
  $newName = $t.Name -replace $Old1, $New1
  if ($newName -ne $t.Name) {
    $newPath = Join-Path $t.DirectoryName $newName
    try {
      Rename-Item -LiteralPath $t.FullName -NewName $newName
      Write-Host "ðŸ“ RenommÃ©: $($t.FullName) -> $newPath"
    } catch {
      Write-Warning "âš ï¸ Ã‰chec Rename: $($t.FullName) ($($_.Exception.Message))"
    }
  }
}

# --- 5) Ajustements frÃ©quents (si prÃ©sents)
# package.json: "name"
if (Test-Path package.json) {
  $pkg = Get-Content -Raw package.json | ConvertFrom-Json
  if ($pkg.name -and ($pkg.name -match $Old1)) {
    $pkg.name = $pkg.name -replace $Old1,$New1
    ($pkg | ConvertTo-Json -Depth 20) | Set-Content package.json -Encoding UTF8
    Write-Host "ðŸ§¾ package.json name -> $($pkg.name)"
  }
}

# astro.config.mjs : base/site courants
if (Test-Path astro.config.mjs) {
  (Get-Content -Raw astro.config.mjs) -replace $Old1,$New1 | Set-Content astro.config.mjs -Encoding UTF8
  Write-Host "ðŸª astro.config.mjs mis Ã  jour"
}

# README.md
if (Test-Path README.md) {
  (Get-Content -Raw README.md) -replace $Old1,$New1 -replace "Optimeal Health","Optimealone" | Set-Content README.md -Encoding UTF8
  Write-Host "ðŸ“„ README.md mis Ã  jour"
}

# workflows (yml)
Get-ChildItem .github\workflows -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
  (Get-Content -Raw $_.FullName) -replace $Old1,$New1 | Set-Content $_.FullName -Encoding UTF8
}

# Nginx / conf
Get-ChildItem -Recurse -Include *.conf -File | Where-Object { -not (Should-Skip $_) } | ForEach-Object {
  (Get-Content -Raw $_.FullName) -replace $Old1,$New1 | Set-Content $_.FullName -Encoding UTF8
}

# .env* (si commitÃ©s)
Get-ChildItem -Recurse -Include .env* -File | Where-Object { -not (Should-Skip $_) } | ForEach-Object {
  (Get-Content -Raw $_.FullName) -replace $Old1,$New1 | Set-Content $_.FullName -Encoding UTF8
}

# --- 6) Status + commit
git add -A
git status

if ($StartCommit) {
  git commit -m "chore: rename $Old1 to $New1 across repo (files, content, workflows)"
  Write-Host "âœ… Commit crÃ©Ã© sur $branch"
  Write-Host "ðŸ‘‰ push: git push -u origin $branch"
}

