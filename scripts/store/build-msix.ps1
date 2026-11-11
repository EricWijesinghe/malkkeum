<#
.SYNOPSIS
  Builds the Windows MSIX packages for the customer, console and partner apps.

.DESCRIPTION
  Test mode (default): signs with a self-signed certificate under scripts/store/.local so the
  package installs locally with Add-AppxPackage. Store mode (-Store): unsigned package for
  Partner Center, which signs it on submission.

  Partner Center values come from environment variables, or from scripts/store/msix.local.psd1
  (gitignored). The committed pubspec values are placeholders only:
    MSIX_PUBLISHER                 Publisher, e.g. CN=XXXXXXXX-XXXX-...   (Partner Center: Product identity)
    MSIX_PUBLISHER_DISPLAY_NAME    Publisher display name
    MSIX_IDENTITY_CUSTOMER         Package/Identity/Name of the customer app
    MSIX_IDENTITY_CONSOLE          Package/Identity/Name of the console app
    MSIX_IDENTITY_PARTNER          Package/Identity/Name of the partner app
  Test mode uses MSIX_PUBLISHER as the certificate subject, so both must match.

.EXAMPLE
  pwsh scripts/store/build-msix.ps1                       # test-signed, all three apps
  pwsh scripts/store/build-msix.ps1 -Apps customer -Store # unsigned store package, customer only
  pwsh scripts/store/build-msix.ps1 -SkipBuild            # reuse existing flutter build windows output

  Heavy builds: run through scripts/build-slot.sh on this PC when other builds are running.
#>
[CmdletBinding()]
param(
  [string[]]$Apps = @('customer', 'console', 'partner'),
  [switch]$Store,
  [switch]$SkipBuild
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
  console  = Get-Setting 'MSIX_IDENTITY_CONSOLE' 'com.malkkeum.console'
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

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$pfx = if ($Store) { $null } else { Get-TestPfx }

# msix is used as a global tool, not a dependency: every msix release depends on the pub
# package 'console', which clashes with this workspace's own 'console' app package.
$msixVersion = '3.18.0'
& dart pub global activate msix $msixVersion
if ($LASTEXITCODE -ne 0) { throw "dart pub global activate msix $msixVersion failed" }

foreach ($name in $Apps) {
  if (-not $identity.ContainsKey($name)) { throw "Unknown app '$name'. Use customer, console or partner." }
  $appDir = Join-Path $app "apps\$name"
  Push-Location $appDir
  try {
    if (-not $SkipBuild) {
      & flutter build windows --release
      if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed for $name" }
    }
    $msixArgs = @(
      'pub', 'global', 'run', 'msix:create', '--build-windows', 'false',
      '--identity-name', $identity[$name],
      '--publisher', $publisher,
      '--publisher-display-name', $publisherName,
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
  } finally {
    Pop-Location
  }
}

Write-Host "MSIX output: $outDir"
