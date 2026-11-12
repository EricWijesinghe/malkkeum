# Malkkeum one-click demo: server (own window) + owner console + Android emulator with both apps.
#   "Malkkeum Demo.cmd" -> this script. Every step is checked; it stops with a clear message instead of half-working.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
function Step($m) { Write-Host "`n== $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "   OK  $m" -ForegroundColor Green }
$builtFor = (Get-Content "$here\api-address.txt" -EA SilentlyContinue | Select-Object -First 1)
$public = if ($builtFor) { "http://${builtFor}:8080" } else { 'http://127.0.0.1:8080' }
$healthy = { try { (Invoke-WebRequest http://127.0.0.1:8080/health -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 } catch { $false } }

Step 'Server'
if (-not (& $healthy)) {
  # Started through WMI so it is its own process: it keeps running even if this window is closed.
  $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$here\Run-Server.ps1`""
  Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd; CurrentDirectory = $here } | Out-Null
  $t = 0; while (-not (& $healthy) -and $t -lt 120) { Start-Sleep 1; $t++ }
  if (-not (& $healthy)) { throw 'The server did not start. Look at the "Malkkeum Server" window for the error.' }
}
Ok "server at $public (separate 'Malkkeum Server' window - keep it open)"

Step 'Owner console'
if ((Test-Path "$here\console") -and -not (Get-NetTCPConnection -LocalPort 8081 -State Listen -EA SilentlyContinue)) {
  # Full path: a WMI-created process does not search PATH the way the shell does.
  $py = (Get-Command python -EA SilentlyContinue).Source
  if (-not $py) { $py = (Get-Command py -EA SilentlyContinue).Source }
  if (-not $py) { throw 'Python is needed to serve the owner console (install Python 3).' }
  $cmd = "`"$py`" -m http.server 8081 --directory `"$here\console`""
  Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd; CurrentDirectory = $here } | Out-Null
  $t = 0; while (-not (Get-NetTCPConnection -LocalPort 8081 -State Listen -EA SilentlyContinue) -and $t -lt 20) { Start-Sleep 1; $t++ }
}
if (-not (Get-NetTCPConnection -LocalPort 8081 -State Listen -EA SilentlyContinue)) { throw 'The owner console did not start on port 8081.' }
Start-Process 'http://localhost:8081/'
Ok 'http://localhost:8081  (owner@demo.local / malkkeum-demo-2026)'

Step 'Android emulator + apps'
& "$here\Run-Emulator.ps1"
$adb = "$(if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" })\platform-tools\adb.exe"
$probe = cmd /c "`"$adb`" shell toybox wget -q -O - $public/health 2>nul"
if ($probe -notmatch 'ok') { throw "The emulator cannot reach $public. Allow api.exe in Windows Firewall (Private), then run again." }
Ok 'emulator reaches the server'
Write-Host "`nDemo ready. Sign in with any phone number: the 6-digit code appears on screen." -ForegroundColor Green
