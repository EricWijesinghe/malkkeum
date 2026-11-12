<#
.SYNOPSIS
  Builds the Windows MSIX packages for the customer and partner apps (the console is web-only).

.DESCRIPTION
  Test mode (default): signs with a self-signed certificate under scripts/store/.local so the
  package installs locally with Add-AppxPackage. Store mode (-Store): unsigned package for
  Partner Center, which signs it on submission.

  Partner Center values come from environment variables, or from scripts/store/msix.local.psd1
  (gitignored). The committed pubspec values are placeholders only:
    MSIX_PUBLISHER                 Publisher, e.g. CN=XXXXXXXX-XXXX-...   (Partner Center: Product identity)
    MSIX_PUBLISHER_DISPLAY_NAME    Publisher display name
    MSIX_IDENTITY_CUSTOMER         Package/Identity/Name of the customer app
    MSIX_IDENTITY_PARTNER          Package/Identity/Name of the partner app
  Test mode uses MSIX_PUBLISHER as the certificate subject, so both must match.

  Server address: -ApiBase (or MSIX_API_BASE) is baked into the app. -Store requires https://<domain>;
  a release app without it refuses to start. With -SkipBuild the existing build is checked for it.

  Package version: <pubspec major>.<n / 65536>.<n % 65536>.0, where n is the store build number from
  scripts/ci/build-number.py (minutes since 2026-01-01, so every build is higher than the last one;
  Partner Center rejects a reused version and reserves the fourth part, which must stay 0).

.PARAMETER ApiBase      Server the app talks to. Default: $env:MSIX_API_BASE.
.PARAMETER BuildNumber  Store build number to use instead of asking scripts/ci/build-number.py.
.PARAMETER Wack         Test mode only, elevated shell: run the Windows App Certification Kit on each package.

.EXAMPLE
  pwsh scripts/store/build-msix.ps1                       # test-signed, both apps (needs MSIX_API_BASE)
  pwsh scripts/store/build-msix.ps1 -Apps customer -Store -ApiBase https://example.com   # unsigned store package
  pwsh scripts/store/build-msix.ps1 -SkipBuild            # reuse existing flutter build windows output

  Heavy builds: run through scripts/build-slot.sh on this PC when other builds are running.
#>
[CmdletBinding()]
param(
  [string[]]$Apps = @('customer', 'partner'),
  [switch]$Store,
  [switch]$SkipBuild,
  [string]$ApiBase = $env:MSIX_API_BASE,
  [int]$BuildNumber,
  [switch]$Wack
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$app = Join-Path $root 'app'
$localDir = Join-Path $PSScriptRoot '.local'
$outDir = Join-Path $root 'dist\msix'

# Local overrides (gitignored): a PowerShell data file with the same keys as the env vars.
$settings = @{}
$localFile = Join-Path $PSScriptRoot 'msix.local.psd1'
if (Test-Path $localFile) { $settings = Import-PowerShellDataFile $localFile }
function Get-Setting([string]$Name, [string]$Default = '') {
  $fromEnv = [Environment]::GetEnvironmentVariable($Name)
  if ($fromEnv) { return $fromEnv }
  if ($settings.ContainsKey($Name) -and $settings[$Name]) { return [string]$settings[$Name] }
  return $Default
}

$publisher = Get-Setting 'MSIX_PUBLISHER' 'CN=Malkkeum Test'
$publisherName = Get-Setting 'MSIX_PUBLISHER_DISPLAY_NAME' 'Malkkeum Test'
$identity = @{
  customer = Get-Setting 'MSIX_IDENTITY_CUSTOMER' 'com.malkkeum.customer'
  partner  = Get-Setting 'MSIX_IDENTITY_PARTNER' 'com.malkkeum.partner'
}

# Test certificate: created once, subject = publisher, password kept next to it.
function Get-TestPfx {
  New-Item -ItemType Directory -Force -Path $localDir | Out-Null
  $pfx = Join-Path $localDir 'test-signing.pfx'
  $pwFile = Join-Path $localDir 'test-signing.password'
  if ((Test-Path $pfx) -and (Test-Path $pwFile)) { return @{ Path = $pfx; Password = (Get-Content $pwFile -Raw).Trim() } }
  $password = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(18))
  $cert = New-SelfSignedCertificate -Type Custom -Subject $publisher -KeyUsage DigitalSignature `
    -FriendlyName 'Malkkeum MSIX test' -CertStoreLocation 'Cert:\CurrentUser\My' `
    -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
  $secure = ConvertTo-SecureString $password -AsPlainText -Force
  Export-PfxCertificate -Cert $cert -FilePath $pfx -Password $secure | Out-Null
  Set-Content -Path $pwFile -Value $password -NoNewline
  Import-Certificate -FilePath $pfx -CertStoreLocation 'Cert:\CurrentUser\TrustedPeople' -Password $secure | Out-Null
  return @{ Path = $pfx; Password = $password }
}

# Checked before anything is built or written. Test packages may point at a LAN server over http.
$ApiBase = "$ApiBase".TrimEnd('/')
$scheme = if ($Store) { 'https' } else { 'https?' }
if (($Store -or -not $SkipBuild -or $ApiBase) -and $ApiBase -notmatch "^${scheme}://[A-Za-z0-9][A-Za-z0-9.-]*(:\d+)?$") {
  throw "API base '$ApiBase' is not $(if ($Store) { 'https://<domain>' } else { 'http(s)://<host>' }). Pass -ApiBase or set MSIX_API_BASE."
}
if ($Wack -and $Store) { throw '-Wack needs an installable (test-signed) package; run it without -Store.' }
$appcert = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\App Certification Kit\appcert.exe'
if ($Wack -and -not (Test-Path -LiteralPath $appcert)) { throw "Windows App Certification Kit not found at $appcert (install it with the Windows SDK)." }

if (-not $BuildNumber) {
  $BuildNumber = [int](& python -I (Join-Path $root 'scripts\ci\build-number.py'))
  if ($LASTEXITCODE -ne 0 -or $BuildNumber -lt 1) { throw 'scripts/ci/build-number.py did not return a build number' }
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$pfx = if ($Store) { $null } else { Get-TestPfx }

# msix is used as a global tool, not a dependency: every msix release depends on the pub
# package 'console', which clashes with this workspace's own 'console' app package.
$msixVersion = '3.18.0'
& dart pub global activate msix $msixVersion
if ($LASTEXITCODE -ne 0) { throw "dart pub global activate msix $msixVersion failed" }

foreach ($name in $Apps) {
  if (-not $identity.ContainsKey($name)) { throw "Unknown app '$name'. Use customer or partner (the console is web-only)." }
  $appDir = Join-Path $app "apps\$name"
  Push-Location $appDir
  try {
    $pubspecVersion = Select-String -LiteralPath 'pubspec.yaml' -Pattern '^version:\s*(\d+)\.' | Select-Object -First 1
    $major = if ($pubspecVersion) { [int]$pubspecVersion.Matches[0].Groups[1].Value } else { 0 }
    if ($major -lt 1 -or $major -gt 65535) { throw "$name pubspec.yaml needs 'version: <major>.<minor>.<patch>' with major 1-65535 (an MSIX version cannot start with 0)." }
    $version = "$major.$($BuildNumber -shr 16).$($BuildNumber -band 0xFFFF).0"
    if (-not $SkipBuild) {
      & flutter build windows --release "--dart-define=API_BASE=$ApiBase"
      if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed for $name" }
    }
    if ($ApiBase) {
      $compiled = Join-Path $appDir 'build\windows\x64\runner\Release\data\app.so'
      if (-not (Test-Path -LiteralPath $compiled)) { throw "No Windows build for $name ($compiled). Run without -SkipBuild." }
      if (-not [IO.File]::ReadAllText($compiled, [Text.Encoding]::GetEncoding(28591)).Contains($ApiBase)) {
        throw "The Windows build of $name was not built for $ApiBase. Rebuild it without -SkipBuild."
      }
    }
    $msixArgs = @(
      'pub', 'global', 'run', 'msix:create', '--build-windows', 'false',
      '--identity-name', $identity[$name],
      '--publisher', $publisher,
      '--publisher-display-name', $publisherName,
      '--version', $version,
      '--output-path', $outDir,
      '--output-name', "malkkeum-$name"
    )
    if ($Store) {
      $msixArgs += '--store'
    } else {
      $msixArgs += @('--certificate-path', $pfx.Path, '--certificate-password', $pfx.Password, '--install-certificate', 'false')
    }
    & dart @msixArgs
    if ($LASTEXITCODE -ne 0) { throw "msix:create failed for $name" }
    Write-Host "malkkeum-$name.msix version $version"
    if ($Wack) {
      $report = Join-Path $outDir "wack-$name.xml"
      Remove-Item -LiteralPath $report -Force -ErrorAction SilentlyContinue  # appcert refuses to overwrite a report
      & $appcert reset
      & $appcert test -appxpackagepath (Join-Path $outDir "malkkeum-$name.msix") -reportoutputpath $report
      if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $report)) { throw "appcert.exe failed for $name (it needs an elevated shell)" }
      if (([xml](Get-Content -LiteralPath $report -Raw)).REPORT.OVERALL_RESULT -ne 'PASS') { throw "WACK did not pass for $name. Report: $report" }
      Write-Host "WACK passed: $report"
    }
  } finally {
    Pop-Location
  }
}

Write-Host "MSIX output: $outDir"
