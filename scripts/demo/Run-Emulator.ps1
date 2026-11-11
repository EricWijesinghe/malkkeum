# Starts the Malkkeum demo emulator (malkkeum_avd, created on first run) and installs both demo apps.
# It never boots any other emulator on this PC, so no other project's apps can show up in a demo.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }
$adb = "$sdk\platform-tools\adb.exe"
$name = 'malkkeum_avd'

if (-not ((& "$sdk\emulator\emulator.exe" -list-avds) -contains $name)) {
  Write-Host "Creating the Malkkeum emulator ($name) ..."
  if (-not $env:JAVA_HOME) {
    $jdk = Get-ChildItem 'C:\Program Files\Java' -Directory -Filter 'jdk*' -EA SilentlyContinue | Select-Object -Last 1
    if ($jdk) { $env:JAVA_HOME = $jdk.FullName }
  }
  'no' | & "$sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd -n $name -k 'system-images;android-34;default;x86_64' -d pixel_6 | Out-Null
}

# A different emulator already running would receive the install, so refuse instead of guessing.
$running = (& $adb devices) -match 'emulator-\d+\s+device'
if ($running) {
  $current = (& $adb emu avd name 2>$null | Select-Object -First 1)
  if ($current -and $current.Trim() -ne $name) { throw "Another emulator ($current) is running. Close it, then run this again." }
} else {
  Write-Host "Starting $name ..."
  Start-Process "$sdk\emulator\emulator.exe" -ArgumentList '-avd', $name, '-memory', '2048', '-no-snapshot-load'
  & $adb wait-for-device
  do { Start-Sleep 3 } until ((& $adb shell getprop sys.boot_completed 2>$null) -match '1')
}

foreach ($apk in Get-ChildItem "$here\Malkkeum-*.apk") {
  Write-Host "Installing $($apk.Name) ..."
  & $adb install -r $apk.FullName
  if ($LASTEXITCODE -ne 0) { throw "Install failed: $($apk.Name)" }
}
# Same as tapping the icon: brings the app to the front even if it is already running behind the launcher.
& $adb shell monkey -p com.malkkeum.customer -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Host 'Malkkeum customer app is open. Start Demo must be running for the apps to load data.'
