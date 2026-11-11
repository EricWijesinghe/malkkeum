# Malkkeum local demo: Postgres + API (dev mode, sample data) on this PC, reachable from phones on
# the same Wi-Fi and from the Android emulator. Lives next to api.exe in the demo folder.
#   Start Demo.cmd  ->  this script
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$pg = 'F:\tools\pgsql\bin'
$pgData = 'F:\tools\pgdata'
$db = 'malkkeum_demo'
$env:PGPASSWORD = 'localdev'

function Step($m) { Write-Host "`n== $m" -ForegroundColor Cyan }

Step 'Database'
& "$pg\pg_isready.exe" -h localhost -p 5433 *> $null
if ($LASTEXITCODE -ne 0) {
  & "$pg\pg_ctl.exe" -D $pgData -l "$pgData\server.log" -o '-p 5433' start | Out-Null
  Start-Sleep 3
}
$exists = & "$pg\psql.exe" -h localhost -p 5433 -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db'"
if ($exists -ne '1') { & "$pg\createdb.exe" -h localhost -p 5433 -U postgres $db }

# The APKs were built for this address; phones must be on the same Wi-Fi.
$builtFor = (Get-Content "$here\api-address.txt" -ErrorAction SilentlyContinue | Select-Object -First 1)
$wifi = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
if ($builtFor -and $wifi -and $builtFor -ne $wifi) {
  Write-Warning "The apps were built for $builtFor but this PC's Wi-Fi address is now $wifi. Phones will not connect; the emulator still works."
}
$public = if ($builtFor) { "http://${builtFor}:8080" } else { 'http://127.0.0.1:8080' }

$envFile = "$here\demo.env"
if (-not (Test-Path $envFile)) {
  $hex = { -join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) }) }
  @(
    "JWT_SECRET=$(& $hex)"
    "DATA_KEY=$(& $hex)"
  ) | Set-Content $envFile
}
Get-Content $envFile | ForEach-Object { $k, $v = $_ -split '=', 2; Set-Item "env:$k" $v }
$env:DATABASE_URL = "postgres://postgres:localdev@localhost:5433/$db"
$env:BIND_ADDR = '0.0.0.0:8080'
$env:PUBLIC_BASE_URL = $public
$env:UPLOAD_DIR = "$here\uploads"
$env:DEV_MODE = '1'
$env:ALLOWED_ORIGINS = 'http://localhost:8081'
$env:SEED_ADMIN_EMAIL = 'owner@demo.local'
$env:SEED_ADMIN_PASSWORD = 'malkkeum-demo-2026'

if (-not (Test-Path "$here\.demo-loaded")) {
  Step 'Sample data (first run only)'
  & "$here\api.exe" demo load
  if ($LASTEXITCODE -ne 0) { throw 'demo load failed' }
  New-Item "$here\.demo-loaded" -ItemType File | Out-Null
}

Step 'Owner console'
if (Test-Path "$here\console") {
  Start-Process -WindowStyle Minimized python -ArgumentList '-m', 'http.server', '8081', '--directory', "$here\console"
  Start-Process 'http://localhost:8081/'
  Write-Host 'Console: http://localhost:8081  (owner@demo.local / malkkeum-demo-2026)'
}

Step "API on $public  (Ctrl+C to stop)"
Write-Host 'Phone on the same Wi-Fi: allow "api.exe" when Windows Firewall asks (Private networks).'
Write-Host 'Login codes are shown on screen in demo mode - no SMS is sent.'
& "$here\api.exe"
