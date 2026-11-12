# Malkkeum demo server: Postgres + API in dev mode (login codes shown on screen, no SMS) with sample data.
# Runs in its own window titled "Malkkeum Server". Closing that window stops the server.
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Malkkeum Server (keep this open during the demo)'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$pg = 'F:\tools\pgsql\bin'
$db = 'malkkeum_demo_v12'  # the backup kit (older server) keeps 'malkkeum_demo'
$env:PGPASSWORD = 'localdev'

& "$pg\pg_isready.exe" -h localhost -p 5433 *> $null
if ($LASTEXITCODE -ne 0) { & "$pg\pg_ctl.exe" -D 'F:\tools\pgdata' -l 'F:\tools\pgdata\server.log' -o '-p 5433' start | Out-Null; Start-Sleep 3 }
$exists = & "$pg\psql.exe" -h localhost -p 5433 -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db'"
if ($exists -ne '1') { & "$pg\createdb.exe" -h localhost -p 5433 -U postgres $db }

$builtFor = (Get-Content "$here\api-address.txt" -EA SilentlyContinue | Select-Object -First 1)
$envFile = "$here\demo.env"
if (-not (Test-Path $envFile)) {
  $hex = { -join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) }) }
  @("JWT_SECRET=$(& $hex)", "DATA_KEY=$(& $hex)") | Set-Content $envFile
}
Get-Content $envFile | ForEach-Object { $k, $v = $_ -split '=', 2; Set-Item "env:$k" $v }
$env:DATABASE_URL = "postgres://postgres:localdev@localhost:5433/$db"
$env:BIND_ADDR = '0.0.0.0:8080'
$env:PUBLIC_BASE_URL = if ($builtFor) { "http://${builtFor}:8080" } else { 'http://127.0.0.1:8080' }
$env:UPLOAD_DIR = "$here\uploads"
$env:DEV_MODE = '1'
$env:ALLOWED_ORIGINS = 'http://localhost:8081'
$env:SEED_ADMIN_EMAIL = 'owner@demo.local'
$env:SEED_ADMIN_PASSWORD = 'malkkeum-demo-2026'
$env:RATE_LIMIT_AUTH_PER_MIN = '1000'
# Demo only: the owner signs in to the console without setting up an authenticator app.
$env:STAFF_MFA_REQUIRED = '0'

if (-not (Test-Path "$here\.demo-loaded")) {
  & "$here\api.exe" demo load
  if ($LASTEXITCODE -ne 0) { throw 'demo load failed' }
  New-Item "$here\.demo-loaded" -ItemType File | Out-Null
}
Write-Host "Malkkeum server on $($env:PUBLIC_BASE_URL). Keep this window open." -ForegroundColor Green
& "$here\api.exe"
