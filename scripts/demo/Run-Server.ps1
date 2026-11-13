# Malkkeum demo server: Postgres + API in dev mode (login codes shown on screen, no SMS) with sample data.
# Runs in its own window titled "Malkkeum Server". Closing that window stops the server.
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Malkkeum Server (keep this open during the demo)'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# PostgreSQL 17: bin folder from PG_BIN or PATH; data directory from PGDATA (only needed when it is not running yet).
$pg = $env:PG_BIN
if (-not $pg) { $c = Get-Command pg_ctl.exe -EA SilentlyContinue; if ($c) { $pg = Split-Path -Parent $c.Source } }
if (-not $pg) { throw 'PostgreSQL 17 not found: put its bin folder on PATH or set PG_BIN.' }
$db = 'malkkeum_demo_v12'  # the backup kit (older server) keeps 'malkkeum_demo'
$env:PGPASSWORD = 'localdev'

& "$pg\pg_isready.exe" -h localhost -p 5433 *> $null
if ($LASTEXITCODE -ne 0) {
  if (-not $env:PGDATA) { throw 'PostgreSQL is not running on port 5433; set PGDATA so it can be started.' }
  & "$pg\pg_ctl.exe" -D $env:PGDATA -l "$env:PGDATA\server.log" -o '-p 5433' start | Out-Null; Start-Sleep 3
}
$exists = & "$pg\psql.exe" -h localhost -p 5433 -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db'"
$created = $exists -ne '1'
if ($created) {
  & "$pg\createdb.exe" -h localhost -p 5433 -U postgres $db
  if ($LASTEXITCODE -ne 0) { throw "createdb $db failed" }
}

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

# Sample data only into a database created just now: an existing kit database keeps its data.
if ($created) {
  & "$here\api.exe" demo load
  if ($LASTEXITCODE -ne 0) {
    # Drop the half-loaded database so the next start creates and loads it again.
    & "$pg\dropdb.exe" -h localhost -p 5433 -U postgres $db
    throw 'demo load failed'
  }
}
Write-Host "Malkkeum server on $($env:PUBLIC_BASE_URL). Keep this window open." -ForegroundColor Green
& "$here\api.exe"
