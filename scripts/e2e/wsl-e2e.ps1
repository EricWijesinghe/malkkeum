# One-click install, tested for real in a throwaway WSL distro (never the CI runner distro, never `wsl --shutdown`).
#   1. Build the images once and save them (no registry), e.g. in the CI distro through the build slot:
#        docker build --build-arg APP_VERSION=e2e --build-arg CARGO_BUILD_JOBS=4 -t ghcr.io/ericwijesinghe/malkkeum-api:e2e backend
#        docker build --build-arg APP_VERSION=e2e -f deploy/web.Dockerfile -t ghcr.io/ericwijesinghe/malkkeum-web:e2e .
#        docker pull postgres:17
#        docker save -o <Root>/images.tar ghcr.io/ericwijesinghe/malkkeum-{api,web}:e2e postgres:17
#   2. powershell -File scripts/e2e/wsl-e2e.ps1 [-Root <dir>] [-LogDir <dir>] [-Keep] [-UpgradeFrom <git rev>]
#      -Root defaults to DAHAE_E2E_ROOT (env or scripts/local.env), else %LOCALAPPDATA%\dahae-e2e.
#      -UpgradeFrom: install with that revision's deploy/install.sh first, then upgrade with this checkout's.
# Downloads the official Ubuntu 24.04 WSL rootfs (checked against SHA256SUMS), imports it as `dahae-e2e`, runs
# scripts/e2e/wsl-e2e.sh as root and unregisters the distro after a pass (kept after a failure for debugging).
param(
  [string]$Root = '',
  [string]$ImagesTar = '',
  [string]$LogDir = '',
  [string]$Distro = 'dahae-e2e',
  [switch]$Keep,
  [string]$UpgradeFrom = ''
)
$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path "$PSScriptRoot\..\..").Path
. (Join-Path $Repo 'scripts\local-env.ps1')
if (-not $Root) { $Root = if ($env:DAHAE_E2E_ROOT) { $env:DAHAE_E2E_ROOT } else { Join-Path $env:LOCALAPPDATA 'dahae-e2e' } }
if (-not $ImagesTar) { $ImagesTar = Join-Path $Root 'images.tar' }
if (-not $LogDir) { $LogDir = Join-Path $Root 'logs' }
$Base = 'https://cloud-images.ubuntu.com/wsl/releases/24.04/current'
$Rootfs = 'ubuntu-noble-wsl-amd64-24.04lts.rootfs.tar.gz'
$Dl = Join-Path $Root 'dl'
if ($Distro -in @('Ubuntu-24.04', 'docker-desktop')) { throw "refusing to use $Distro" }
if (-not (Test-Path $ImagesTar)) { throw "no image tar at $ImagesTar (see step 1 at the top of this script)" }
New-Item -ItemType Directory -Force $Dl, $LogDir | Out-Null

# Rootfs, verified against the folder's SHA256SUMS
curl.exe -fsSL -o "$Dl\SHA256SUMS" "$Base/SHA256SUMS"
if ($LASTEXITCODE) { throw 'SHA256SUMS download failed' }
$want = ((Get-Content "$Dl\SHA256SUMS" | Where-Object { $_ -match "\s$([regex]::Escape($Rootfs))$" }) -split '\s+')[0]
if (-not $want) { throw "$Rootfs not listed in SHA256SUMS" }
if (-not (Test-Path "$Dl\$Rootfs") -or (Get-FileHash "$Dl\$Rootfs" -Algorithm SHA256).Hash -ne $want.ToUpper()) {
  curl.exe -fL -o "$Dl\$Rootfs" "$Base/$Rootfs"
  if ($LASTEXITCODE) { throw 'rootfs download failed' }
  if ((Get-FileHash "$Dl\$Rootfs" -Algorithm SHA256).Hash -ne $want.ToUpper()) { throw 'rootfs checksum mismatch' }
}

# Fresh distro: systemd on, root by default, no Windows PATH (Docker Desktop's docker shim would hide the missing engine)
if ((wsl.exe -l -q) -replace "`0", '' -contains $Distro) { throw "$Distro already exists: wsl --unregister $Distro first" }
wsl.exe --import $Distro "$Root\disk" "$Dl\$Rootfs" --version 2
if ($LASTEXITCODE) { throw 'wsl --import failed' }
wsl.exe -d $Distro -u root --exec sh -c "printf '[boot]\nsystemd=true\n[user]\ndefault=root\n[interop]\nappendWindowsPath=false\n' > /etc/wsl.conf"
wsl.exe --terminate $Distro

$src = (wsl.exe -d $Distro -u root --exec wslpath -a $Repo).Trim()
$tar = (wsl.exe -d $Distro -u root --exec wslpath -a $ImagesTar).Trim()
$logs = (wsl.exe -d $Distro -u root --exec wslpath -a $LogDir).Trim()
$old = ''
if ($UpgradeFrom) { # git archive writes the file itself (a PowerShell redirect would re-encode it)
  git -C $Repo archive -o "$LogDir\old-installer.tar" $UpgradeFrom deploy/install.sh
  if ($LASTEXITCODE) { throw "no deploy/install.sh at $UpgradeFrom" }
  $old = '/root/old/deploy/install.sh'
}
wsl.exe -d $Distro -u root --exec bash -c "rm -rf /root/src /root/old && mkdir -p /root/src /root/old && tar -C '$src' -cf - deploy scripts | tar -C /root/src -xf - && { [ -z '$old' ] || tar -C /root/old -xf '$logs/old-installer.tar'; } && bash /root/src/scripts/e2e/wsl-e2e.sh '$tar' '$logs' $old 2>&1 | tee '$logs/run.log'; exit `${PIPESTATUS[0]}"
$rc = $LASTEXITCODE
wsl.exe --terminate $Distro
if ($rc -eq 0 -and -not $Keep) { wsl.exe --unregister $Distro; Remove-Item -Recurse -Force "$Root\disk" -ErrorAction SilentlyContinue }
elseif ($rc -ne 0) { Write-Host "E2E failed (rc=$rc); distro $Distro kept. Logs: $LogDir. Remove with: wsl --unregister $Distro" }
exit $rc
