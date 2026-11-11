<#
.SYNOPSIS
  Builds the complete Malkkeum hand-over package into F:\EC\targets\release-stage (one folder per audience).

.DESCRIPTION
  Each step builds its own output and copies it into the staging folder. Re-running is safe: a step
  replaces only its own folder, the upload key is reused, and heavy builds are incremental. Every
  step logs to F:\EC\targets\release-logs\build-all-<time>.log and the run stops at the first failure.
  -Publish copies the verified staging folder to the Desktop "Malkkeum Demo" (the old folder is renamed,
  never deleted). Publish refuses unless the verify step passed on the same commit.

.PARAMETER Only    Run only these steps (in pipeline order). Use it to split long builds across tool calls.
.PARAMETER Skip    Skip these steps.
.PARAMETER ApiHost Address written into the demo builds. Default: IPv4 of the "Wi-Fi" adapter.
.PARAMETER StoreApiBase  https://<domain> baked into store builds (MALKKEUM_API_BASE). Unset = placeholder.
.PARAMETER Publish Run the publish step (copy staging to the Desktop). Same as -Only publish.

.EXAMPLE
  pwsh -File scripts/release/build-all.ps1                                  # everything, stops on first failure
  pwsh -File scripts/release/build-all.ps1 -Only api,console,apk-demo-customer
  pwsh -File scripts/release/build-all.ps1 -Only verify
  pwsh -File scripts/release/build-all.ps1 -Only publish                   # after verify passed

  Heavy builds (cargo, flutter, docker) go through bash /f/EC/scripts/build-slot.sh in the foreground.
#>
[CmdletBinding()]
param(
  [string[]]$Only,
  [string[]]$Skip,
  [string]$ApiHost,
  [string]$StoreApiBase = $env:MALKKEUM_API_BASE,
  [switch]$Publish
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Stage = 'F:\EC\targets\release-stage'
$Work = 'F:\EC\targets\release-work'
$KeyDir = 'F:\EC\targets\release-keys'
$LogDir = 'F:\EC\targets\release-logs'
$CargoDir = 'F:/EC/targets/release-cargo'
$GitBash = 'C:\Program Files\Git\bin\bash.exe'
$BuildSlot = '/f/EC/scripts/build-slot.sh'
$Jdk = 'C:\Program Files\Java\jdk-21.0.12'
$BuildTools = "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0"
$Desktop = [Environment]::GetFolderPath('Desktop')
$FinalDir = Join-Path $Desktop 'Malkkeum Demo'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:LogFile = Join-Path $LogDir "build-all-$Stamp.log"
$DockerFlag = Join-Path $Work 'docker-started-by-release.flag'
# Toolchain for every step, so a single -Only run works the same as a full run.
$env:JAVA_HOME = $Jdk
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:PATH = "F:\tools\flutter\bin;$Jdk\bin;$env:PATH"
$Demo = "$Stage\1-Demo"; $Install = "$Stage\2-Install-Server"; $Android = "$Stage\3-Store-Android"
$Msix = "$Stage\4-Store-Microsoft"; $Apple = "$Stage\5-Store-Apple"; $DocsOut = "$Stage\6-Docs"

function Log([string]$Msg) {
  $line = "[$(Get-Date -Format 'HH:mm:ss')] $Msg"
  Write-Host $line
  Add-Content -LiteralPath $script:LogFile -Value $line
}

# Runs a native command; its output goes to the log, failures print the log tail and stop the run.
# -Secret keeps the argument list (passwords) out of the log.
function Run([string]$Exe, [string[]]$ArgList, [switch]$Secret) {
  $shown = if ($Secret) { '<hidden>' } else { $ArgList -join ' ' }
  Add-Content -LiteralPath $script:LogFile -Value "> $Exe $shown"
  & $Exe @ArgList 2>&1 | ForEach-Object { Add-Content -LiteralPath $script:LogFile -Value "$_" }
  if ($LASTEXITCODE -ne 0) {
    Get-Content -LiteralPath $script:LogFile -Tail 25 | ForEach-Object { Write-Host "   | $_" }
    throw "$Exe exited with code $LASTEXITCODE"
  }
}

# Heavy commands run in the shared build slot (one at a time, waits for free memory).
function Slot([string[]]$Cmd) { Run $GitBash (@($BuildSlot) + $Cmd) }

function Reset-Dir([string]$Path) {
  if (-not $Path.StartsWith($Stage, [StringComparison]::OrdinalIgnoreCase) -and -not $Path.StartsWith($Work, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to clear '$Path' outside the release folders"
  }
  if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Copy-Output([string]$From, [string]$To) {
  if (-not (Test-Path -LiteralPath $From)) { throw "Missing build output: $From" }
  Copy-Item -LiteralPath $From -Destination $To -Force
  Log "   copied $(Split-Path $From -Leaf) -> $To"
}

function Get-WifiIp {
  if ($ApiHost) { return $ApiHost }
  $ip = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -EA SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1 -ExpandProperty IPAddress
  if (-not $ip) { throw 'No IPv4 on the "Wi-Fi" adapter. Connect to Wi-Fi or pass -ApiHost.' }
  return $ip
}

# Flutter prep that codemagic and web.Dockerfile also run before building.
function Prep-Flutter {
  Push-Location (Join-Path $root 'app')
  try { Run 'python' @('-I', 'tool/gen_arb.py'); Run 'flutter' @('pub', 'get') } finally { Pop-Location }
  Push-Location (Join-Path $root 'app\packages\core')
  try { Run 'flutter' @('gen-l10n') } finally { Pop-Location }
}

function Get-KeyPassword {
  $pwFile = Join-Path $KeyDir 'PASSWORD.txt'
  return ((Get-Content -LiteralPath $pwFile | Where-Object { $_ -like 'password:*' }) -replace '^password:\s*', '').Trim()
}

# Sets the Gradle signing env (read by android/app/build.gradle.kts) for the scope of one script block.
function With-UploadKey([scriptblock]$Body) {
  $pw = Get-KeyPassword
  $names = 'CM_KEYSTORE_PATH', 'CM_KEYSTORE_PASSWORD', 'CM_KEY_ALIAS', 'CM_KEY_PASSWORD'
  $values = (Join-Path $KeyDir 'malkkeum-upload.p12').Replace('\', '/'), $pw, 'upload', $pw
  for ($i = 0; $i -lt 4; $i++) { Set-Item -Path "env:$($names[$i])" -Value $values[$i] }
  try { & $Body } finally { foreach ($n in $names) { Remove-Item -Path "env:$n" -EA SilentlyContinue } }
}

function Build-Info {
  $sha = (& git -C $root rev-parse --short HEAD 2>$null)
  $dirty = (& git -C $root status --porcelain 2>$null | Measure-Object).Count
  $fv = (& flutter --version 2>$null | Select-Object -First 1)
  return @(
    "- 빌드 / Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
    "- 커밋 / Commit: $sha$(if ($dirty) { " (uncommitted changes: $dirty files)" })",
    "- 체험 서버 주소 / Demo server address: http://$($script:ApiHost):8080",
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
  foreach ($p in $GitBash, "$Jdk\bin\keytool.exe", "$Jdk\bin\jarsigner.exe", "$BuildTools\aapt2.exe", "$BuildTools\apksigner.bat", 'F:\tools\flutter\bin\flutter.bat', "$env:USERPROFILE\.cargo\bin\cargo.exe", $BuildSlot.Replace('/f/', 'F:\').Replace('/', '\')) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Missing tool: $p" }
  }
  $script:ApiHost = Get-WifiIp
  $script:FlutterInfo = (& flutter --version 2>$null | Select-Object -First 1)
  Log "   API address for demo builds: $($script:ApiHost)"
  if (-not $StoreApiBase) { Log '   WARNING: MALKKEUM_API_BASE not set; store binaries will use a placeholder server address.' }
  foreach ($d in $Demo, $Install, $Android, $Msix, $Apple, $DocsOut, $Work, $KeyDir) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
  Remove-Item -LiteralPath "$Stage\.verified" -Force -EA SilentlyContinue
}

function Step-Api {
  Push-Location (Join-Path $root 'backend')
  try { Slot @('cargo', 'build', '--release', '-p', 'api', '--target-dir', $CargoDir) } finally { Pop-Location }
  Copy-Output "$CargoDir\release\api.exe" "$Demo\api.exe"
}

function Step-Console {
  Prep-Flutter
  Push-Location (Join-Path $root 'app\apps\console')
  # No API_BASE: served on localhost, the console calls 127.0.0.1:8080 by itself (an empty host once baked http://:8080).
  try { Slot @('flutter', 'build', 'web', '--release') } finally { Pop-Location }
  Reset-Dir "$Demo\console"
  Copy-Item -Path (Join-Path $root 'app\apps\console\build\web\*') -Destination "$Demo\console" -Recurse -Force
  Set-Content -LiteralPath "$Demo\api-address.txt" -Value $script:ApiHost
}

function Step-DemoApk([string]$App, [string]$Name) {
  Prep-Flutter
  Push-Location (Join-Path $root "app\apps\$App")
  try { Slot @('flutter', 'build', 'apk', '--profile', "--dart-define=API_BASE=http://$($script:ApiHost):8080") } finally { Pop-Location }
  Copy-Output (Join-Path $root "app\apps\$App\build\app\outputs\flutter-apk\app-profile.apk") "$Demo\$Name"
}

function Step-DemoKit {
  $kit = Join-Path $root 'scripts\demo'
  foreach ($f in 'Start-Demo.ps1', 'Run-Server.ps1', 'Run-Emulator.ps1') { Copy-Item -LiteralPath "$kit\$f" -Destination $Demo -Force }
  $cmd = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0Start-Demo.ps1`"`r`npause`r`n"
  [IO.File]::WriteAllText("$Demo\Malkkeum Demo.cmd", $cmd, [Text.Encoding]::ASCII)
  Copy-Item -LiteralPath (Join-Path $root 'scripts\release\kit\demo-README.txt') -Destination "$Demo\README.txt" -Force
  New-Item -ItemType Directory -Force -Path "$Demo\uploads" | Out-Null
  # Presenter material: the markdown as-is plus a rendered HTML copy. A missing file fails the step.
  foreach ($doc in 'DEMO-SCRIPT', 'PITCH', 'FAQ-AUDIENCE') {
    $src = Join-Path $root "docs\demo\$doc.md"
    if (-not (Test-Path -LiteralPath $src)) { throw "Missing demo doc: $src (merge master first)" }
    Copy-Item -LiteralPath $src -Destination $Demo -Force
    Render-Md $src "$Demo\$doc.html" $doc
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
    Set-Content -LiteralPath (Join-Path $KeyDir 'PASSWORD.txt') -Value @(
      "password: $pw", 'alias: upload', 'store type: PKCS12', 'Play App Signing UPLOAD key. Keep private; never commit.')
    Log '   created upload keystore (master copy in release-keys)'
  }
  Run "$Jdk\bin\keytool.exe" @('-list', '-keystore', $p12, '-storepass', (Get-KeyPassword)) -Secret
  Reset-Dir "$Android\signing"
  Copy-Item -LiteralPath $p12 -Destination "$Android\signing\malkkeum-upload.p12"
  Copy-Item -LiteralPath (Join-Path $KeyDir 'PASSWORD.txt') -Destination "$Android\signing\PASSWORD.txt"
  Copy-Item -LiteralPath (Join-Path $root 'scripts\release\kit\signing-README.md') -Destination "$Android\signing\README.md"
}

function Step-AndroidBuild([string]$App, [string]$Kind) {
  Prep-Flutter
  $api = if ($StoreApiBase) { $StoreApiBase } else { 'https://api.example.invalid' }
  $isBundle = $Kind -eq 'aab'
  $target = if ($isBundle) { 'appbundle' } else { 'apk' }
  Push-Location (Join-Path $root "app\apps\$App")
  try { With-UploadKey { Slot @('flutter', 'build', $target, '--release', "--dart-define=API_BASE=$api") } } finally { Pop-Location }
  $outputs = Join-Path $root "app\apps\$App\build\app\outputs"
  if ($isBundle) {
    Copy-Output "$outputs\bundle\release\app-release.aab" "$Android\$App-release.aab"
  } else {
    Copy-Output "$outputs\flutter-apk\app-release.apk" "$Android\$App-universal.apk"
  }
}

function Step-MsixBuild([string]$App) {
  Prep-Flutter
  Push-Location (Join-Path $root "app\apps\$App")
  try { Slot @('flutter', 'build', 'windows', '--release') } finally { Pop-Location }
}

function Step-MsixPack {
  $msixScript = Join-Path $root 'scripts\store\build-msix.ps1'
  $dist = Join-Path $root 'dist\msix'
  Reset-Dir "$Msix\test-signed"; Reset-Dir "$Msix\store"
  & pwsh -NoProfile -File $msixScript -SkipBuild
  if ($LASTEXITCODE -ne 0) { throw 'build-msix.ps1 (test signed) failed' }
  foreach ($app in 'customer', 'console', 'partner') { Copy-Output "$dist\malkkeum-$app.msix" "$Msix\test-signed\malkkeum-$app.msix" }
  $cer = Join-Path $root 'scripts\store\.local\test-signing.pfx'
  $pw = (Get-Content -Raw (Join-Path $root 'scripts\store\.local\test-signing.password')).Trim()
  $pfx = [Security.Cryptography.X509Certificates.X509Certificate2]::new($cer, $pw, 'Exportable')
  [IO.File]::WriteAllBytes("$Msix\malkkeum-test-signing.cer", $pfx.Export('Cert'))
  & pwsh -NoProfile -File $msixScript -SkipBuild -Store
  if ($LASTEXITCODE -ne 0) { throw 'build-msix.ps1 (store) failed' }
  foreach ($app in 'customer', 'console', 'partner') { Copy-Output "$dist\malkkeum-$app.msix" "$Msix\store\malkkeum-$app.msix" }
}

function Step-DockerStart {
  $exe = 'C:\Users\EricW\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe'
  & docker info *> $null
  if ($LASTEXITCODE -ne 0) {
    Log '   starting Docker Desktop'
    Start-Process -FilePath $exe
    $t = 0
    do { Start-Sleep 5; $t += 5; & docker info *> $null } until (($LASTEXITCODE -eq 0) -or ($t -ge 300))
    if ($LASTEXITCODE -ne 0) { throw 'Docker did not start within 5 minutes' }
    Set-Content -LiteralPath $DockerFlag -Value 'yes'
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

function Render-Md([string]$Src, [string]$Dst, [string]$Title) {
  Run 'python' @('-I', (Join-Path $root 'scripts\release\md2html.py'), $Src, $Dst, $Title)
}

function Step-Docs {
  Reset-Dir "$Install\guides"
  $guides = Get-ChildItem (Join-Path $root 'docs\guide') -Filter '*.md'
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

function Step-Root {
  $md = Get-Content -Raw -Encoding utf8 (Join-Path $root 'scripts\release\kit\README-root.md')
  $tmp = Join-Path $Work 'README-root.md'
  Set-Content -LiteralPath $tmp -Value $md.Replace('BUILD_INFO_PLACEHOLDER', (Build-Info)) -Encoding utf8
  Render-Md $tmp "$Stage\README.html" 'Malkkeum release package'
}

# Checks run before anything is published. Results are written to the log; any failure stops the run.
function Step-Verify {
  Push-Location $root
  try { Run 'python' @('-I', 'scripts\ci\check-native.py') } finally { Pop-Location }
  Log '   check-native.py passed'
  $bt = $BuildTools
  foreach ($f in "$Android\customer-release.aab", "$Android\partner-release.aab") {
    $out = (& "$Jdk\bin\jarsigner.exe" -verify $f 2>&1 | Out-String)
    if ($out -notmatch 'jar verified') { throw "Not a verified signed bundle: $f" }
    Log "   jar verified: $(Split-Path $f -Leaf)"
  }
  foreach ($f in "$Android\customer-universal.apk", "$Android\partner-universal.apk", "$Demo\Malkkeum-Customer.apk", "$Demo\Malkkeum-Partner.apk") {
    $badging = (& "$bt\aapt2.exe" dump badging $f 2>&1 | Select-String '^package:' | Select-Object -First 1)
    Log "   $(Split-Path $f -Leaf): $badging"
    if ($LASTEXITCODE -ne 0 -or -not $badging) { throw "aapt2 cannot read $f" }
  }
  foreach ($f in "$Android\customer-universal.apk", "$Android\partner-universal.apk") {
    $out = (& "$bt\apksigner.bat" verify --print-certs $f 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { throw "apksigner verify failed: $f" }
    Log "   apksigner ok: $(Split-Path $f -Leaf)"
  }
  foreach ($f in "$Msix\test-signed\malkkeum-customer.msix", "$Msix\store\malkkeum-partner.msix") {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $z = [IO.Compression.ZipFile]::OpenRead($f)
    $has = $z.Entries.Name -contains 'AppxManifest.xml'
    $z.Dispose()
    if (-not $has) { throw "MSIX without AppxManifest.xml: $f" }
    Log "   MSIX manifest ok: $(Split-Path $f -Leaf)"
  }
  Verify-DemoServer
  Set-Content -LiteralPath "$Stage\.verified" -Value (git -C $root rev-parse HEAD)
  Log '   verify passed; .verified written'
}

# Starts the staged server the way Start-Demo does (WMI, own process), on port 18080 and a separate
# database, so the live demo on 8080 is never touched. Stops the api by PID afterwards.
function Verify-DemoServer {
  $kit = Join-Path $Work 'verify-kit'
  Reset-Dir $kit
  Copy-Item "$Demo\*" $kit -Recurse -Force
  $run = Get-Content -Raw (Join-Path $root 'scripts\demo\Run-Server.ps1')
  $run = $run.Replace('malkkeum_demo', 'malkkeum_release_check').Replace('8080', '18080')
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
  & 'F:\tools\pgsql\bin\dropdb.exe' -h localhost -p 5433 -U postgres malkkeum_release_check *> $null
}

function Step-Publish {
  if (-not (Test-Path "$Stage\.verified")) { throw 'Not verified: run -Only verify first.' }
  $verifiedAt = (Get-Content "$Stage\.verified" -Raw).Trim()
  $head = (git -C $root rev-parse HEAD).Trim()
  if ($verifiedAt -ne $head) { throw "Verified commit $verifiedAt differs from HEAD $head. Re-run verify." }
  if (Test-Path -LiteralPath $FinalDir) {
    $old = "$FinalDir (previous $Stamp)"
    Rename-Item -LiteralPath $FinalDir -NewName (Split-Path $old -Leaf)
    Log "   renamed existing folder (kept) -> $old"
  }
  Copy-Item -LiteralPath $Stage -Destination $FinalDir -Recurse
  Remove-Item -LiteralPath "$FinalDir\.verified" -Force
  Log "   published to $FinalDir"
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
  'msix-build-customer' = { Step-MsixBuild 'customer' }
  'msix-build-console' = { Step-MsixBuild 'console' }
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

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Set-Location $root
# "-Only a,b" also works when started with pwsh -File (which passes one string).
$Only = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$Skip = @($Skip | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$unknown = @($Only + $Skip | Where-Object { -not $Steps.Contains($_) })
if ($unknown) { throw "Unknown step(s): $($unknown -join ', '). Steps: $($Steps.Keys -join ', ')" }
Log "build-all start: commit $(git -C $root rev-parse --short HEAD), stage $Stage"
$names = @($Steps.Keys | Where-Object { (-not $Only -or $Only -contains $_) -and ($_ -ne 'publish' -or $Publish -or ($Only -contains 'publish')) -and ($Skip -notcontains $_) })
foreach ($name in $names) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  Log "== [$name]"
  try { & $Steps[$name] } catch {
    Log "!! [$name] FAILED: $($_.Exception.Message)"
    Log "   fix the cause, then re-run: build-all.ps1 -Only $name  (log: $script:LogFile)"
    exit 1
  }
  Log ("== [$name] ok ({0:N0}s)" -f $sw.Elapsed.TotalSeconds)
}
Log "build-all done. Log: $script:LogFile"
