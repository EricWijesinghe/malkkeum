<#
.SYNOPSIS
  Builds the complete Malkkeum hand-over package into F:\EC\targets\release-stage (one folder per audience).

.DESCRIPTION
  Each step builds its own output and copies it into the staging folder. Re-running is safe: a step
  replaces only its own folder, the upload key is reused, and heavy builds are incremental. Every
  step logs to F:\EC\targets\release-logs\build-all-<time>.log and the run stops at the first failure.

  Server addresses are checked before they are baked into a build, and read back out of the built
  file afterwards: demo builds need a private LAN IPv4, store builds need https://<domain>.

  Store builds (AAB, APK, MSIX) all take their build number from scripts/ci/build-number.py, the same
  source Codemagic uses: it only rises, so a second upload is never rejected for a reused number.
  Android store builds are obfuscated; their Dart symbol files go to F:\EC\targets\release-symbols
  (kept on this PC to read crash reports with "flutter symbolize", never staged or shipped).
  The console is web-only: MSIX packages are built for the customer and partner apps.

  -Publish swaps the staged demo kit (1-Demo) in as the Desktop folder "Malkkeum Demo". The old folder
  is renamed "Malkkeum Demo (previous <time>)"; nothing on the Desktop is ever deleted or overwritten.
  Publish refuses unless the verify step passed on the same commit.

.PARAMETER Only    Run only these steps (in pipeline order). Use it to split long builds across tool calls.
.PARAMETER Skip    Skip these steps.
.PARAMETER ApiHost Private LAN IPv4 written into the demo builds. Default: IPv4 of the "Wi-Fi" adapter.
.PARAMETER StoreApiBase  https://<domain> baked into store builds. Default: $env:MALKKEUM_API_BASE. Required.
.PARAMETER AllowPlaceholder  Build store binaries with a placeholder address when no StoreApiBase is set (not for upload).
.PARAMETER Publish Run the publish step. Publishing never happens without this switch.
.PARAMETER DryRun  Print every step and command without running anything. Addresses are still checked.

.EXAMPLE
  pwsh -File scripts/release/build-all.ps1 -DryRun                          # show the plan, change nothing
  pwsh -File scripts/release/build-all.ps1                                  # everything, stops on first failure
  pwsh -File scripts/release/build-all.ps1 -Only api,console,apk-demo-customer
  pwsh -File scripts/release/build-all.ps1 -Only apk-console               # 7-Console-Android: sideload APK for the owner phone
  pwsh -File scripts/release/build-all.ps1 -Only verify
  pwsh -File scripts/release/build-all.ps1 -Only publish -Publish          # after verify passed

  Heavy builds (cargo, flutter, docker) go through bash /f/EC/scripts/build-slot.sh in the foreground.
#>
[CmdletBinding()]
param(
  [string[]]$Only,
  [string[]]$Skip,
  [string]$ApiHost,
  [string]$StoreApiBase = $env:MALKKEUM_API_BASE,
  [switch]$AllowPlaceholder,
  [switch]$Publish,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Stage = 'F:\EC\targets\release-stage'
$Work = 'F:\EC\targets\release-work'
$KeyDir = 'F:\EC\targets\release-keys'
$LogDir = 'F:\EC\targets\release-logs'
$CargoDir = 'F:/EC/targets/release-cargo'
$SymbolsDir = 'F:/EC/targets/release-symbols'
$GitBash = 'C:\Program Files\Git\bin\bash.exe'
$BuildSlot = '/f/EC/scripts/build-slot.sh'
$Jdk = 'C:\Program Files\Java\jdk-21.0.12'
$BuildTools = "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0"
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:LogFile = Join-Path $LogDir "build-all-$Stamp.log"
$DockerFlag = Join-Path $Work 'docker-started-by-release.flag'
$ApiPort = 8080
$PlaceholderApiBase = 'https://api.example.invalid'
$KitName = 'Malkkeum Demo'
# Desktop folders that publishing must never rename, overwrite or delete.
$ProtectedKits = 'Malkkeum Demo (backup - works)', 'Malkkeum Demo (previous)'
# Top level of the verified demo kit. Anything else in 1-Demo is a mistake.
$KitLayout = 'api.exe', 'console', 'Malkkeum-Customer.apk', 'Malkkeum-Partner.apk', 'api-address.txt',
  'Start-Demo.ps1', 'Run-Server.ps1', 'Run-Emulator.ps1', 'Malkkeum Demo.cmd', 'README.txt', 'docs'
$DemoSteps = 'apk-demo-customer', 'apk-demo-partner', 'demo-kit'
$StoreSteps = 'aab-customer', 'aab-partner', 'apk-store-customer', 'apk-store-partner', 'msix-build-customer', 'msix-build-partner'
# Toolchain for every step, so a single -Only run works the same as a full run.
$env:JAVA_HOME = $Jdk
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:PATH = "F:\tools\flutter\bin;$Jdk\bin;$env:PATH"
$Demo = "$Stage\1-Demo"; $Install = "$Stage\2-Install-Server"; $Android = "$Stage\3-Store-Android"
$Msix = "$Stage\4-Store-Microsoft"; $Apple = "$Stage\5-Store-Apple"; $DocsOut = "$Stage\6-Docs"
$ConsoleOut = "$Stage\7-Console-Android"

function Log([string]$Msg) {
  $line = "[$(Get-Date -Format 'HH:mm:ss')] $Msg"
  Write-Host $line
  if (-not $DryRun) { Add-Content -LiteralPath $script:LogFile -Value $line }
}

# Runs a native command; its output goes to the log, failures print the log tail and stop the run.
# -Secret keeps the argument list (passwords) out of the log.
function Run([string]$Exe, [string[]]$ArgList, [switch]$Secret) {
  $shown = if ($Secret) { '<hidden>' } else { $ArgList -join ' ' }
  if ($DryRun) { Log "   would run: $Exe $shown   (in $((Get-Location).Path))"; return }
  Add-Content -LiteralPath $script:LogFile -Value "> $Exe $shown"
  & $Exe @ArgList 2>&1 | ForEach-Object { Add-Content -LiteralPath $script:LogFile -Value "$_" }
  if ($LASTEXITCODE -ne 0) {
    Get-Content -LiteralPath $script:LogFile -Tail 25 | ForEach-Object { Write-Host "   | $_" }
    throw "$Exe exited with code $LASTEXITCODE"
  }
}

# Everything that changes something and is not a Run goes through here, so -DryRun can print it instead.
function Act([string]$What, [scriptblock]$Do) {
  if ($DryRun) { Log "   would: $What"; return }
  & $Do
}

# Heavy commands run in the shared build slot (one at a time, waits for free memory).
function Slot([string[]]$Cmd) { Run $GitBash (@($BuildSlot) + $Cmd) }

function Reset-Dir([string]$Path) {
  if (-not $Path.StartsWith("$Stage\", [StringComparison]::OrdinalIgnoreCase) -and -not $Path.StartsWith("$Work\", [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to clear '$Path' outside the release folders"
  }
  if ($DryRun) { Log "   would: clear $Path"; return }
  if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Copy-Output([string]$From, [string]$To) {
  if ($DryRun) { Log "   would: copy $From -> $To"; return }
  if (-not (Test-Path -LiteralPath $From)) { throw "Missing build output: $From" }
  Copy-Item -LiteralPath $From -Destination $To -Force
  Log "   copied $(Split-Path $From -Leaf) -> $To"
}

# The apps only use the demo sign-in/payment flow against a private (RFC 1918) address.
function Test-LanIp([string]$Ip) {
  $a = $null
  if ($Ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$' -or -not [Net.IPAddress]::TryParse($Ip, [ref]$a)) { return $false }
  $b = $a.GetAddressBytes()
  return ($b[0] -eq 10) -or ($b[0] -eq 172 -and $b[1] -ge 16 -and $b[1] -le 31) -or ($b[0] -eq 192 -and $b[1] -eq 168)
}

# Address baked into the demo APKs. Resolved on first use (not only in preflight), so a single
# -Only step can never bake an empty host.
function Get-DemoHost {
  if ($script:DemoHost) { return $script:DemoHost }
  $ip = $ApiHost
  if (-not $ip) {
    $ip = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -EA SilentlyContinue |
      Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1 -ExpandProperty IPAddress
    if (-not $ip) { throw 'No IPv4 on the "Wi-Fi" adapter. Connect to Wi-Fi or pass -ApiHost <LAN IPv4>.' }
  }
  if (-not (Test-LanIp $ip)) { throw "Demo API host '$ip' is not a private LAN IPv4 (10.x, 172.16-31.x, 192.168.x). Pass -ApiHost <LAN IPv4>." }
  $script:DemoHost = $ip
  return $ip
}

function Get-DemoApiBase { return "http://$(Get-DemoHost):$ApiPort" }

# Address baked into store builds (Android and Windows). No silent fallback: a missing or non-https value stops the run.
function Get-StoreApiBase {
  if ($StoreApiBase -match '^https://[A-Za-z0-9][A-Za-z0-9.-]*(:\d+)?/?$') { return $StoreApiBase.TrimEnd('/') }
  if ($StoreApiBase) { throw "MALKKEUM_API_BASE '$StoreApiBase' is not https://<domain> (https only, no path)." }
  if ($AllowPlaceholder) { return $PlaceholderApiBase }
  throw 'MALKKEUM_API_BASE is not set. Set it to https://<domain> (or pass -StoreApiBase), or pass -AllowPlaceholder to build test binaries that cannot reach a server.'
}

# versionCode / MSIX version for this run. One number per run, from the same script Codemagic calls.
function Get-BuildNumber {
  if (-not $script:BuildNumber) {
    $n = [int](& python -I (Join-Path $root 'scripts\ci\build-number.py'))
    if ($LASTEXITCODE -ne 0 -or $n -lt 1) { throw 'scripts\ci\build-number.py did not return a build number' }
    $script:BuildNumber = $n
  }
  return $script:BuildNumber
}

# Reads the compiled Dart back out of a build (main.dart.js / app.so, or libapp.so / app.so inside an
# APK, AAB or MSIX) and fails when the baked address has an empty host ("http://:8080") or, when
# $Expect is given, when $Expect is not in it.
function Assert-BakedBase([string]$File, [string]$Expect) {
  if ($DryRun) { Log "   would: check the API address baked into $File$(if ($Expect) { " is $Expect" } else { ' has a host' })"; return }
  if (-not (Test-Path -LiteralPath $File)) { throw "Missing build output: $File" }
  $leaf = Split-Path $File -Leaf
  $latin1 = [Text.Encoding]::GetEncoding(28591)
  $check = {
    param([string]$Text)
    if ($Text -match 'https?://:') { throw "$leaf has an API address without a host baked in ('$($Matches[0])'). Rebuild this step." }
    if ($Expect -and -not $Text.Contains($Expect)) { throw "$leaf does not contain the expected API address $Expect. Rebuild this step." }
  }
  if ($leaf -match '\.(js|so)$') {
    & $check ([IO.File]::ReadAllText($File, $latin1))
  } else {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($File)
    try {
      $units = @($zip.Entries | Where-Object { $_.Name -in 'libapp.so', 'app.so' })
      if (-not $units) { throw "$leaf has no compiled Dart (libapp.so / app.so) to check." }
      foreach ($e in $units) {
        $ms = [IO.MemoryStream]::new()
        $s = $e.Open()
        try { $s.CopyTo($ms) } finally { $s.Dispose() }
        & $check ($latin1.GetString($ms.ToArray()))
      }
    } finally { $zip.Dispose() }
  }
  Log "   baked API address ok: $leaf$(if ($Expect) { " -> $Expect" })"
}

# Flutter prep that codemagic and web.Dockerfile also run before building.
function Prep-Flutter {
  Push-Location (Join-Path $root 'app')
  try { Run 'python' @('-I', 'tool/gen_arb.py'); Run 'flutter' @('pub', 'get') } finally { Pop-Location }
  Push-Location (Join-Path $root 'app\packages\core')
  try { Run 'flutter' @('gen-l10n') } finally { Pop-Location }
}

# Read at run time from release-keys; never stored in the repo and never logged.
function Get-KeyPassword {
  if ($DryRun) { return '<hidden>' }
  $pwFile = Join-Path $KeyDir 'PASSWORD.txt'
  if (-not (Test-Path -LiteralPath $pwFile)) { throw "Missing $pwFile. Run -Only keystore first (or restore the key backup)." }
  $line = Get-Content -LiteralPath $pwFile | Where-Object { $_ -like 'password:*' } | Select-Object -First 1
  $pw = ("$line" -replace '^password:\s*', '').Trim()
  if (-not $pw) { throw "No 'password: <value>' line in $pwFile. Refusing to sign with an empty password." }
  return $pw
}

# Sets the Gradle signing env (read by android/app/build.gradle.kts) for the scope of one script block.
function With-UploadKey([scriptblock]$Body) {
  $p12 = Join-Path $KeyDir 'malkkeum-upload.p12'
  if (-not $DryRun -and -not (Test-Path -LiteralPath $p12)) { throw "Missing upload key $p12. Run -Only keystore first." }
  $pw = Get-KeyPassword
  $names = 'CM_KEYSTORE_PATH', 'CM_KEYSTORE_PASSWORD', 'CM_KEY_ALIAS', 'CM_KEY_PASSWORD'
  $values = $p12.Replace('\', '/'), $pw, 'upload', $pw
  for ($i = 0; $i -lt 4; $i++) { Set-Item -Path "env:$($names[$i])" -Value $values[$i] }
  try { & $Body } finally { foreach ($n in $names) { Remove-Item -Path "env:$n" -EA SilentlyContinue } }
}

function Get-StagedHost { return "$(Get-Content -LiteralPath "$Demo\api-address.txt" -EA SilentlyContinue | Select-Object -First 1)".Trim() }

function Write-ApiAddress {
  $ip = Get-DemoHost
  Act "write api-address.txt ($ip)" { Set-Content -LiteralPath "$Demo\api-address.txt" -Value $ip }
}

function Assert-KitLayout {
  $have = @(Get-ChildItem -LiteralPath $Demo -Force | Select-Object -ExpandProperty Name)
  $missing = @($KitLayout | Where-Object { $have -notcontains $_ })
  $extra = @($have | Where-Object { $KitLayout -notcontains $_ })
  if ($missing -or $extra) { throw "1-Demo is not the demo kit. Missing: $($missing -join ', '). Unexpected: $($extra -join ', '). Re-run the missing steps, then demo-kit." }
  if (-not (Test-Path -LiteralPath "$Demo\console\main.dart.js")) { throw '1-Demo\console has no main.dart.js. Re-run -Only console.' }
  if (-not (Get-ChildItem -LiteralPath "$Demo\docs\demo" -Filter '*.md' -EA SilentlyContinue)) { throw '1-Demo\docs\demo has no .md files. Re-run -Only demo-kit.' }
  if (-not (Test-LanIp (Get-StagedHost))) { throw "1-Demo\api-address.txt ('$(Get-StagedHost)') is not a LAN IPv4. Re-run the demo steps." }
}

function Build-Info {
  $sha = (& git -C $root rev-parse --short HEAD 2>$null)
  $dirty = (& git -C $root status --porcelain 2>$null | Measure-Object).Count
  $fv = (& flutter --version 2>$null | Select-Object -First 1)
  $staged = Get-StagedHost
  return @(
    "- 빌드 / Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
    "- 커밋 / Commit: $sha$(if ($dirty) { " (uncommitted changes: $dirty files)" })",
    "- 체험 서버 주소 / Demo server address: $(if ($staged) { "http://${staged}:$ApiPort" } else { '(demo kit not built)' })",
    "- Flutter: $fv",
    "- Docker 이미지 태그 / image tag: demo (malkkeum-api:demo, malkkeum-web:demo)",
    "- 로그 / Log: $($script:LogFile)"
  ) -join "`n"
}

# ---------------------------------------------------------------- steps

function Step-Preflight {
  $free = (Get-PSDrive F).Free / 1GB
  Log ('   free space on F: {0:N1} GB' -f $free)
  if ($free -lt 15) { throw 'Less than 15 GB free on F:. Free space, then re-run.' }
  if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is not set; the Android SDK path cannot be resolved.' }
  foreach ($p in $GitBash, "$Jdk\bin\keytool.exe", "$Jdk\bin\jarsigner.exe", "$BuildTools\aapt2.exe", "$BuildTools\apksigner.bat", 'F:\tools\flutter\bin\flutter.bat', "$env:USERPROFILE\.cargo\bin\cargo.exe", $BuildSlot.Replace('/f/', 'F:\').Replace('/', '\')) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Missing tool: $p" }
  }
  # Fail now, not twenty minutes into the builds.
  if ($names | Where-Object { $DemoSteps -contains $_ }) { Log "   API address for demo builds: $(Get-DemoApiBase)" }
  if ($names | Where-Object { $StoreSteps -contains $_ }) {
    $api = Get-StoreApiBase
    Log "   API address for store builds: $api"
    Log "   build number for store builds: $(Get-BuildNumber)"
    if ($api -eq $PlaceholderApiBase) { Log '   WARNING: -AllowPlaceholder: store binaries cannot reach a server. Do not upload them.' }
  }
  Act "create the staging folders under $Stage, $Work, $KeyDir; remove the old .verified marker" {
    foreach ($d in $Demo, $Install, $Android, $Msix, $Apple, $DocsOut, $ConsoleOut, $Work, $KeyDir) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    Remove-Item -LiteralPath "$Stage\.verified" -Force -EA SilentlyContinue
  }
}

function Step-Api {
  Push-Location (Join-Path $root 'backend')
  try { Slot @('cargo', 'build', '--release', '-p', 'api', '--target-dir', $CargoDir) } finally { Pop-Location }
  Copy-Output "$CargoDir\release\api.exe" "$Demo\api.exe"
}

function Step-Console {
  Prep-Flutter
  $web = Join-Path $root 'app\apps\console\build\web'
  Push-Location (Join-Path $root 'app\apps\console')
  # No API_BASE: served on localhost, the console calls 127.0.0.1:8080 by itself (an empty host once baked http://:8080).
  try { Slot @('flutter', 'build', 'web', '--release') } finally { Pop-Location }
  Assert-BakedBase "$web\main.dart.js"
  Reset-Dir "$Demo\console"
  Act "copy $web\* -> $Demo\console" { Copy-Item -Path "$web\*" -Destination "$Demo\console" -Recurse -Force }
}

function Step-DemoApk([string]$App, [string]$Name) {
  $api = Get-DemoApiBase
  Prep-Flutter
  Push-Location (Join-Path $root "app\apps\$App")
  try { Slot @('flutter', 'build', 'apk', '--profile', "--dart-define=API_BASE=$api") } finally { Pop-Location }
  $apk = Join-Path $root "app\apps\$App\build\app\outputs\flutter-apk\app-profile.apk"
  Assert-BakedBase $apk $api
  Copy-Output $apk "$Demo\$Name"
  Write-ApiAddress
}

function Step-DemoKit {
  $kit = Join-Path $root 'scripts\demo'
  $docs = @(Get-ChildItem (Join-Path $root 'docs\demo') -Filter '*.md' -EA SilentlyContinue)
  if (-not $docs) { throw "No demo docs in $root\docs\demo (merge master first)." }
  Act "copy Start-Demo.ps1, Run-Server.ps1, Run-Emulator.ps1 and README.txt into $Demo; write 'Malkkeum Demo.cmd'" {
    foreach ($f in 'Start-Demo.ps1', 'Run-Server.ps1', 'Run-Emulator.ps1') { Copy-Item -LiteralPath "$kit\$f" -Destination $Demo -Force }
    $cmd = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0Start-Demo.ps1`"`r`npause`r`n"
    [IO.File]::WriteAllText("$Demo\$KitName.cmd", $cmd, [Text.Encoding]::ASCII)
    Copy-Item -LiteralPath (Join-Path $root 'scripts\release\kit\demo-README.txt') -Destination "$Demo\README.txt" -Force
  }
  Write-ApiAddress
  # Presenter material: the markdown as-is plus a rendered HTML copy next to it.
  Reset-Dir "$Demo\docs"
  Act "copy docs\demo\*.md ($($docs.Count) files) -> $Demo\docs\demo" {
    New-Item -ItemType Directory -Force -Path "$Demo\docs\demo" | Out-Null
    $docs | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination "$Demo\docs\demo" -Force }
  }
  foreach ($d in $docs) { Render-Md $d.FullName "$Demo\docs\demo\$($d.BaseName).html" $d.BaseName }
  # Earlier runs left docs and an uploads folder at the top level; the api creates uploads itself.
  Act "remove anything in $Demo that is not part of the kit layout" {
    Get-ChildItem -LiteralPath $Demo -Force | Where-Object { $KitLayout -notcontains $_.Name } | ForEach-Object {
      Remove-Item -LiteralPath $_.FullName -Recurse -Force
      Log "   removed stale $($_.Name)"
    }
  }
}

function Step-Keystore {
  $p12 = Join-Path $KeyDir 'malkkeum-upload.p12'
  if (-not (Test-Path -LiteralPath $p12)) {
    $chars = (48..57) + (65..90) + (97..122)
    $pw = -join (1..24 | ForEach-Object { [char]($chars | Get-Random) })
    Run "$Jdk\bin\keytool.exe" @('-genkeypair', '-v', '-keystore', $p12, '-storetype', 'PKCS12', '-storepass', $pw,
      '-alias', 'upload', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000', '-keypass', $pw,
      '-dname', 'CN=Malkkeum Upload, O=Malkkeum, C=KR', '-noprompt') -Secret
    Act "write the generated password to $KeyDir\PASSWORD.txt" {
      Set-Content -LiteralPath (Join-Path $KeyDir 'PASSWORD.txt') -Value @(
        "password: $pw", 'alias: upload', 'store type: PKCS12', 'Play App Signing UPLOAD key. Keep private; never commit.')
      Log '   created upload keystore (master copy in release-keys)'
    }
  }
  Run "$Jdk\bin\keytool.exe" @('-list', '-keystore', $p12, '-storepass', (Get-KeyPassword)) -Secret
  Reset-Dir "$Android\signing"
  Act "copy the upload key, PASSWORD.txt and README.md -> $Android\signing" {
    Copy-Item -LiteralPath $p12 -Destination "$Android\signing\malkkeum-upload.p12"
    Copy-Item -LiteralPath (Join-Path $KeyDir 'PASSWORD.txt') -Destination "$Android\signing\PASSWORD.txt"
    Copy-Item -LiteralPath (Join-Path $root 'scripts\release\kit\signing-README.md') -Destination "$Android\signing\README.md"
  }
}

function Step-AndroidBuild([string]$App, [string]$Kind) {
  $api = Get-StoreApiBase
  Prep-Flutter
  $isBundle = $Kind -eq 'aab'
  $target = if ($isBundle) { 'appbundle' } else { 'apk' }
  Push-Location (Join-Path $root "app\apps\$App")
  $n = Get-BuildNumber
  # The symbols folder is the only way to read an obfuscated crash trace: one per build, outside the stage.
  $flags = "--build-number=$n", '--obfuscate', "--split-debug-info=$SymbolsDir/$App-$Kind-$n", "--dart-define=API_BASE=$api"
  try { With-UploadKey { Slot (@('flutter', 'build', $target, '--release') + $flags) } } finally { Pop-Location }
  $outputs = Join-Path $root "app\apps\$App\build\app\outputs"
  $built = if ($isBundle) { "$outputs\bundle\release\app-release.aab" } else { "$outputs\flutter-apk\app-release.apk" }
  Assert-BakedBase $built $api
  Copy-Output $built $(if ($isBundle) { "$Android\$App-release.aab" } else { "$Android\$App-universal.apk" })
}

# Owner console as a sideloaded APK (not on any store). No API_BASE: the owner types the server address on first launch.
# Signed with the upload key when it exists (run -Only keystore once), otherwise with the debug key: fine for sideloading.
function Step-ConsoleApk {
  Prep-Flutter
  Push-Location (Join-Path $root 'app\apps\console')
  $n = Get-BuildNumber
  $flags = "--build-number=$n", '--obfuscate', "--split-debug-info=$SymbolsDir/console-apk-$n"
  $build = { Slot (@('flutter', 'build', 'apk', '--release') + $flags) }
  try {
    if ($DryRun -or (Test-Path -LiteralPath (Join-Path $KeyDir 'malkkeum-upload.p12'))) { With-UploadKey $build }
    else { Log '   WARNING: no upload key yet (-Only keystore): the console APK is debug-signed'; & $build }
  } finally { Pop-Location }
  Act "copy console APK and README into $ConsoleOut" {
    Copy-Item -LiteralPath (Join-Path $root 'app\apps\console\build\app\outputs\flutter-apk\app-release.apk') -Destination "$ConsoleOut\Dahae-Console.apk" -Force
    Copy-Item -LiteralPath (Join-Path $root 'scripts\release\kit\console-android-README.txt') -Destination "$ConsoleOut\README.txt" -Force
    Log "   copied Dahae-Console.apk and README.txt -> $ConsoleOut"
  }
}

function Step-MsixBuild([string]$App) {
  # Without API_BASE a Windows build falls back to http://127.0.0.1:8080, which is useless in a store package.
  $api = Get-StoreApiBase
  Prep-Flutter
  Push-Location (Join-Path $root "app\apps\$App")
  try { Slot @('flutter', 'build', 'windows', '--release', "--dart-define=API_BASE=$api") } finally { Pop-Location }
  Assert-BakedBase (Join-Path $root "app\apps\$App\build\windows\x64\runner\Release\data\app.so") $api
}

function Step-MsixPack {
  $msixScript = Join-Path $root 'scripts\store\build-msix.ps1'
  $dist = Join-Path $root 'dist\msix'
  Reset-Dir "$Msix\test-signed"; Reset-Dir "$Msix\store"
  # Both passes get the same version and the address the msix-build steps baked in (the script checks it).
  $common = '-NoProfile', '-File', $msixScript, '-SkipBuild', '-ApiBase', (Get-StoreApiBase), '-BuildNumber', "$(Get-BuildNumber)"
  Run 'pwsh' $common
  foreach ($app in 'customer', 'partner') { Copy-Output "$dist\malkkeum-$app.msix" "$Msix\test-signed\malkkeum-$app.msix" }
  Act "export the public test-signing certificate -> $Msix\malkkeum-test-signing.cer" {
    $cer = Join-Path $root 'scripts\store\.local\test-signing.pfx'
    $pw = (Get-Content -Raw (Join-Path $root 'scripts\store\.local\test-signing.password')).Trim()
    $pfx = [Security.Cryptography.X509Certificates.X509Certificate2]::new($cer, $pw, 'Exportable')
    [IO.File]::WriteAllBytes("$Msix\malkkeum-test-signing.cer", $pfx.Export('Cert'))
  }
  Run 'pwsh' ($common + '-Store')
  foreach ($app in 'customer', 'partner') { Copy-Output "$dist\malkkeum-$app.msix" "$Msix\store\malkkeum-$app.msix" }
}

function Step-DockerStart {
  Act 'start Docker Desktop if "docker info" fails, and wait up to 5 minutes for it' {
    $exe = Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\Docker Desktop.exe'
    & docker info *> $null
    if ($LASTEXITCODE -ne 0) {
      if (-not (Test-Path -LiteralPath $exe)) { throw "Docker is not running and Docker Desktop was not found at $exe" }
      Log '   starting Docker Desktop'
      Start-Process -FilePath $exe
      $t = 0
      do { Start-Sleep 5; $t += 5; & docker info *> $null } until (($LASTEXITCODE -eq 0) -or ($t -ge 300))
      if ($LASTEXITCODE -ne 0) { throw 'Docker did not start within 5 minutes' }
      Set-Content -LiteralPath $DockerFlag -Value 'yes'
    }
  }
}

function Step-DockerApi {
  Run 'docker' @('build', '-f', 'backend/Dockerfile', '--build-arg', 'APP_VERSION=demo', '-t', 'ghcr.io/ericwijesinghe/malkkeum-api:demo', (Join-Path $root 'backend'))
}

function Step-DockerWeb {
  Push-Location $root
  try { Run 'docker' @('build', '-f', 'deploy/web.Dockerfile', '--build-arg', 'APP_VERSION=demo', '-t', 'ghcr.io/ericwijesinghe/malkkeum-web:demo', '.') } finally { Pop-Location }
}

function Step-DockerSave {
  Run 'docker' @('pull', 'postgres:17')
  $tar = "$Install\malkkeum-demo.tar"
  Run 'docker' @('save', '-o', $tar, 'ghcr.io/ericwijesinghe/malkkeum-api:demo', 'ghcr.io/ericwijesinghe/malkkeum-web:demo', 'postgres:17')
  Act "copy deploy\install.sh -> $Install; docker rmi the two :demo images; stop Docker Desktop if this release started it" {
    Copy-Item -LiteralPath (Join-Path $root 'deploy\install.sh') -Destination "$Install\install.sh" -Force
    Log "   image bundle: $([math]::Round((Get-Item $tar).Length / 1MB)) MB"
    # Remove only the two images this release built (postgres stays). Stop Docker only if this release started it.
    & docker rmi ghcr.io/ericwijesinghe/malkkeum-api:demo ghcr.io/ericwijesinghe/malkkeum-web:demo *> $null
    if (Test-Path -LiteralPath $DockerFlag) {
      & docker desktop stop *> $null
      Remove-Item -LiteralPath $DockerFlag -Force
      Log '   Docker Desktop stopped (it was started by this release)'
    }
  }
}

function Render-Md([string]$Src, [string]$Dst, [string]$Title) {
  if (-not (Test-Path -LiteralPath $Src)) { throw "Missing document: $Src" }
  Run 'python' @('-I', (Join-Path $root 'scripts\release\md2html.py'), $Src, $Dst, $Title)
}

function Step-Docs {
  $guides = @(Get-ChildItem (Join-Path $root 'docs\guide') -Filter '*.md' -EA SilentlyContinue)
  if (-not $guides) { throw "No guides in $root\docs\guide" }
  Reset-Dir "$Install\guides"
  foreach ($g in $guides) {
    $name = [IO.Path]::GetFileNameWithoutExtension($g.Name)
    Render-Md $g.FullName "$Install\guides\$name.html" $name
  }
  Render-Md (Join-Path $root 'scripts\release\kit\vps-deploy.md') "$Install\VPS-deploy-guide.html" 'VPS deploy guide'
  Render-Md (Join-Path $root 'docs\guide\04-사장님-가이드.md') "$DocsOut\owner-guide.html" 'Owner guide'
  Render-Md (Join-Path $root 'docs\finance-tax.md') "$DocsOut\finance-tax.html" 'Finance and tax'
  Render-Md (Join-Path $root 'docs\privacy-retention.md') "$DocsOut\privacy-retention.html" 'Privacy and retention'
  Render-Md (Join-Path $root 'docs\DEPLOY.md') "$DocsOut\DEPLOY.html" 'Deploy runbook'
}

function Step-StoreDocs {
  $store = Join-Path $root 'docs\store'
  Act "copy store listings, data-safety, review notes, READMEs and codemagic.yaml from $store and scripts\release\kit -> $Android, $Msix, $Apple" {
    Get-ChildItem $store -Filter 'listing-*.md' | ForEach-Object { Copy-Item $_.FullName $Android -Force }
    Copy-Item "$store\data-safety.md", "$store\review-notes.md" $Android -Force
    Copy-Item (Join-Path $root 'scripts\release\kit\store-android-README.md') "$Android\README.md" -Force
    Copy-Item (Join-Path $root 'scripts\release\kit\content-rating-draft.md') $Android -Force
    if (Get-ChildItem "$store\screenshots" -Recurse -File -EA SilentlyContinue) {
      Reset-Dir "$Android\screenshots"; Copy-Item "$store\screenshots\*" "$Android\screenshots" -Recurse -Force
    }
    Copy-Item "$store\microsoft-store.md" $Msix -Force
    Copy-Item (Join-Path $root 'scripts\release\kit\store-microsoft-README.md') "$Msix\README.md" -Force
    Copy-Item (Join-Path $root 'codemagic.yaml') $Apple -Force
    Copy-Item "$store\app-privacy.md", "$store\review-notes.md" $Apple -Force
    Copy-Item (Join-Path $root 'scripts\release\kit\store-apple-README.md') "$Apple\README.md" -Force
  }
}

function Step-Root {
  $tmp = Join-Path $Work 'README-root.md'
  Act "write $tmp from scripts\release\kit\README-root.md with the build info" {
    $md = Get-Content -Raw -Encoding utf8 (Join-Path $root 'scripts\release\kit\README-root.md')
    Set-Content -LiteralPath $tmp -Value $md.Replace('BUILD_INFO_PLACEHOLDER', (Build-Info)) -Encoding utf8
  }
  if ($DryRun) { Log "   would run: python -I scripts\release\md2html.py $tmp $Stage\README.html"; return }
  Render-Md $tmp "$Stage\README.html" 'Malkkeum release package'
}

# Checks run before anything is published. Results are written to the log; any failure stops the run.
function Step-Verify {
  Push-Location $root
  try { Run 'python' @('-I', 'scripts\ci\check-native.py') } finally { Pop-Location }
  $bt = $BuildTools
  Act "check $Demo is exactly the kit layout: $($KitLayout -join ', ')" { Assert-KitLayout; Log '   demo kit layout ok' }
  # Every binary that carries a server address: none may have an empty host, demo APKs must match api-address.txt.
  Assert-BakedBase "$Demo\console\main.dart.js"
  $demoApi = if ($DryRun) { 'http://<api-address.txt>:' + $ApiPort } else { "http://$(Get-StagedHost):$ApiPort" }
  foreach ($f in "$Demo\Malkkeum-Customer.apk", "$Demo\Malkkeum-Partner.apk") { Assert-BakedBase $f $demoApi }
  $storeFiles = "$Android\customer-release.aab", "$Android\partner-release.aab", "$Android\customer-universal.apk", "$Android\partner-universal.apk"
  $msixFiles = foreach ($app in 'customer', 'partner') { "$Msix\test-signed\malkkeum-$app.msix"; "$Msix\store\malkkeum-$app.msix" }
  foreach ($f in $storeFiles + $msixFiles) { Assert-BakedBase $f }
  foreach ($f in "$Android\customer-release.aab", "$Android\partner-release.aab") {
    Act "jarsigner -verify $f" {
      $out = (& "$Jdk\bin\jarsigner.exe" -verify $f 2>&1 | Out-String)
      if ($out -notmatch 'jar verified') { throw "Not a verified signed bundle: $f" }
      Log "   jar verified: $(Split-Path $f -Leaf)"
    }
  }
  foreach ($f in "$Android\customer-universal.apk", "$Android\partner-universal.apk", "$Demo\Malkkeum-Customer.apk", "$Demo\Malkkeum-Partner.apk") {
    Act "aapt2 dump badging $f" {
      $badging = (& "$bt\aapt2.exe" dump badging $f 2>&1 | Select-String '^package:' | Select-Object -First 1)
      Log "   $(Split-Path $f -Leaf): $badging"
      if ($LASTEXITCODE -ne 0 -or -not $badging) { throw "aapt2 cannot read $f" }
    }
  }
  foreach ($f in "$Android\customer-universal.apk", "$Android\partner-universal.apk") {
    Act "apksigner verify --print-certs $f" {
      $out = (& "$bt\apksigner.bat" verify --print-certs $f 2>&1 | Out-String)
      if ($LASTEXITCODE -ne 0) { throw "apksigner verify failed: $f" }
      Log "   apksigner ok: $(Split-Path $f -Leaf)"
    }
  }
  $consoleApk = "$ConsoleOut\Dahae-Console.apk"
  if ($DryRun -or (Test-Path -LiteralPath $consoleApk)) {
    Act "aapt2 + apksigner on $consoleApk" {
      $badging = (& "$bt\aapt2.exe" dump badging $consoleApk 2>&1 | Select-String '^package:' | Select-Object -First 1)
      if ($LASTEXITCODE -ne 0 -or -not $badging -or "$badging" -notmatch "name='com\.malkkeum\.console'") { throw "Console APK is not com.malkkeum.console: $badging" }
      & "$bt\apksigner.bat" verify $consoleApk 2>&1 | Out-Null
      if ($LASTEXITCODE -ne 0) { throw "apksigner verify failed: $consoleApk" }
      Log "   console APK ok: $badging"
    }
  }
  foreach ($f in $msixFiles) {
    Act "check AppxManifest.xml is in $f" {
      Add-Type -AssemblyName System.IO.Compression.FileSystem
      $z = [IO.Compression.ZipFile]::OpenRead($f)
      $has = $z.Entries.Name -contains 'AppxManifest.xml'
      $z.Dispose()
      if (-not $has) { throw "MSIX without AppxManifest.xml: $f" }
      Log "   MSIX manifest ok: $(Split-Path $f -Leaf)"
    }
  }
  Act 'start the staged server from a copy of 1-Demo on port 18080 with database malkkeum_release_check, GET /health, stop it by PID, drop that database' { Verify-DemoServer }
  Act "write $Stage\.verified (HEAD commit)" {
    Set-Content -LiteralPath "$Stage\.verified" -Value (git -C $root rev-parse HEAD)
    Log '   verify passed; .verified written'
  }
}

# Starts the staged server the way Start-Demo does (WMI, own process), on port 18080 and a separate
# database, so the live demo on 8080 is never touched. Stops the api by PID afterwards.
function Verify-DemoServer {
  $kit = Join-Path $Work 'verify-kit'
  $checkDb = 'malkkeum_release_check'
  Reset-Dir $kit
  Copy-Item "$Demo\*" $kit -Recurse -Force
  $run = Get-Content -Raw "$Demo\Run-Server.ps1"
  $run = ($run -replace "(?m)^\`$db = '[^']+'", "`$db = '$checkDb'").Replace(":$ApiPort", ':18080')
  # If Run-Server.ps1 changes shape, stop here instead of starting against the live demo database or port.
  if (-not $run.Contains("`$db = '$checkDb'") -or -not $run.Contains('0.0.0.0:18080')) { throw 'Run-Server.ps1 no longer has the $db / BIND_ADDR lines the verify step rewrites.' }
  Set-Content -LiteralPath "$kit\Run-Server.ps1" -Value $run
  $health = 'http://127.0.0.1:18080/health'
  $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$kit\Run-Server.ps1`""
  $r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd; CurrentDirectory = $kit }
  if ($r.ReturnValue -ne 0) { throw "WMI could not start the server (code $($r.ReturnValue))" }
  $ok = $false
  for ($t = 0; $t -lt 150 -and -not $ok; $t += 2) {
    Start-Sleep 2
    try { $ok = (Invoke-WebRequest $health -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 } catch { $ok = $false }
  }
  $apiProc = Get-CimInstance Win32_Process -Filter "Name='api.exe'" | Where-Object { $_.ExecutablePath -like "$kit\*" }
  try {
    if (-not $ok) { throw 'staged server did not become healthy on :18080' }
    Log '   staged server healthy: GET /health 200'
  } finally {
    foreach ($p in $apiProc) { Stop-Process -Id $p.ProcessId -Force; Log "   stopped staged api PID $($p.ProcessId)" }
  }
  $env:PGPASSWORD = 'localdev'
  & 'F:\tools\pgsql\bin\dropdb.exe' -h localhost -p 5433 -U postgres $checkDb *> $null
}

# Swaps the staged kit in as Desktop\"Malkkeum Demo". Copies first and renames second, so a failed
# copy leaves the Desktop as it was. Nothing on the Desktop is deleted or overwritten.
function Step-Publish {
  $desktop = [Environment]::GetFolderPath('Desktop')
  if (-not $desktop -or -not (Test-Path -LiteralPath $desktop)) { throw 'Desktop folder not found.' }
  $final = Join-Path $desktop $KitName
  $oldName = "$KitName (previous $Stamp)"
  $newName = "$KitName (incoming $Stamp)"
  $incoming = Join-Path $desktop $newName
  foreach ($n in $oldName, $newName) {
    if ($ProtectedKits -contains $n) { throw "Refusing to touch protected folder '$n'." }
    if (Test-Path -LiteralPath (Join-Path $desktop $n)) { throw "'$n' already exists on the Desktop. Nothing was changed; run publish again." }
  }
  Act "check $Stage\.verified is the HEAD commit and $Demo is exactly the kit layout" {
    if (-not (Test-Path "$Stage\.verified")) { throw 'Not verified: run -Only verify first.' }
    $verifiedAt = (Get-Content "$Stage\.verified" -Raw).Trim()
    $head = (git -C $root rev-parse HEAD).Trim()
    if ($verifiedAt -ne $head) { throw "Verified commit $verifiedAt differs from HEAD $head. Re-run verify." }
    Assert-KitLayout
  }
  Act "copy $Demo -> $incoming" { Copy-Item -LiteralPath $Demo -Destination $incoming -Recurse }
  Act "rename '$final' -> '$oldName' (kept), then '$incoming' -> '$KitName'" {
    try {
      if (Test-Path -LiteralPath $final) {
        Rename-Item -LiteralPath $final -NewName $oldName
        Log "   renamed existing folder (kept) -> $oldName"
      }
      Rename-Item -LiteralPath $incoming -NewName $KitName
    } catch {
      throw "Could not swap the Desktop folder (close the 'Malkkeum Server' window and any open file in it, then re-run). The new kit is in '$incoming'. $($_.Exception.Message)"
    }
    Log "   published to $final"
  }
}

$Steps = [ordered]@{
  'preflight' = { Step-Preflight }
  'api' = { Step-Api }
  'console' = { Step-Console }
  'apk-demo-customer' = { Step-DemoApk 'customer' 'Malkkeum-Customer.apk' }
  'apk-demo-partner' = { Step-DemoApk 'partner' 'Malkkeum-Partner.apk' }
  'demo-kit' = { Step-DemoKit }
  'keystore' = { Step-Keystore }
  'aab-customer' = { Step-AndroidBuild 'customer' 'aab' }
  'aab-partner' = { Step-AndroidBuild 'partner' 'aab' }
  'apk-store-customer' = { Step-AndroidBuild 'customer' 'apk' }
  'apk-store-partner' = { Step-AndroidBuild 'partner' 'apk' }
  'apk-console' = { Step-ConsoleApk }
  'msix-build-customer' = { Step-MsixBuild 'customer' }
  'msix-build-partner' = { Step-MsixBuild 'partner' }
  'msix-pack' = { Step-MsixPack }
  'docker-start' = { Step-DockerStart }
  'docker-api' = { Step-DockerApi }
  'docker-web' = { Step-DockerWeb }
  'docker-save' = { Step-DockerSave }
  'docs' = { Step-Docs }
  'store-docs' = { Step-StoreDocs }
  'root' = { Step-Root }
  'verify' = { Step-Verify }
  'publish' = { Step-Publish }
}

# Self-check of the address rules; a wrong rule here would bake a wrong address into every build.
$lanCases = @{ '192.168.0.5' = $true; '172.25.243.168' = $true; '10.0.0.7' = $true; '' = $false; '8.8.8.8' = $false; '169.254.1.1' = $false; '172.32.0.1' = $false; 'localhost' = $false }
foreach ($c in $lanCases.GetEnumerator()) { if ((Test-LanIp $c.Key) -ne $c.Value) { throw "Self-check failed: Test-LanIp '$($c.Key)'" } }

if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
Set-Location $root
# "-Only a,b" also works when started with pwsh -File (which passes one string).
$Only = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$Skip = @($Skip | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$unknown = @($Only + $Skip | Where-Object { -not $Steps.Contains($_) })
if ($unknown) { throw "Unknown step(s): $($unknown -join ', '). Steps: $($Steps.Keys -join ', ')" }
if (($Only -contains 'publish') -and -not $Publish) { throw 'The publish step changes the Desktop and only runs with the -Publish switch: -Only publish -Publish' }
Log "build-all $(if ($DryRun) { 'DRY RUN (nothing is run or written)' } else { 'start' }): commit $(git -C $root rev-parse --short HEAD), stage $Stage"
$names = @($Steps.Keys | Where-Object { (-not $Only -or $Only -contains $_) -and ($_ -ne 'publish' -or $Publish) -and ($Skip -notcontains $_) })
$wouldFail = 0
foreach ($name in $names) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  Log "== [$name]"
  try { & $Steps[$name] } catch {
    if ($DryRun) { $wouldFail++; Log "!! [$name] WOULD FAIL: $($_.Exception.Message)"; continue }
    Log "!! [$name] FAILED: $($_.Exception.Message)"
    Log "   fix the cause, then re-run: build-all.ps1 -Only $name  (log: $script:LogFile)"
    exit 1
  }
  if (-not $DryRun) { Log ("== [$name] ok ({0:N0}s)" -f $sw.Elapsed.TotalSeconds) }
}
if ($DryRun) { Log "dry run done: $($names.Count) steps, $wouldFail would fail."; exit $(if ($wouldFail) { 1 } else { 0 }) }
Log "build-all done. Log: $script:LogFile"
