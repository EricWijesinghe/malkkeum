# Starts the Android emulator (first AVD found) and installs both demo apps.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }
$adb = "$sdk\platform-tools\adb.exe"
$avd = (& "$sdk\emulator\emulator.exe" -list-avds | Select-Object -First 1)
if (-not $avd) { throw 'No Android emulator found. Create one in Android Studio > Device Manager.' }

if (-not ((& $adb devices) -match 'emulator-\d+\s+device')) {
  Write-Host "Starting emulator $avd ..."
  Start-Process "$sdk\emulator\emulator.exe" -ArgumentList '-avd', $avd, '-memory', '2048'
  & $adb wait-for-device
  do { Start-Sleep 3 } until ((& $adb shell getprop sys.boot_completed 2>$null) -match '1')
}
foreach ($apk in Get-ChildItem "$here\*.apk") {
  Write-Host "Installing $($apk.Name) ..."
  & $adb install -r $apk.FullName
}
& $adb shell monkey -p com.malkkeum.customer -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Host 'Done. Start Demo must be running for the apps to load data.'
