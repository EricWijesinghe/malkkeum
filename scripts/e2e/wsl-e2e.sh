#!/usr/bin/env bash
# Inside a throwaway WSL distro (scripts/e2e/wsl-e2e.ps1 creates it), as root: check the distro is clean,
# then run the real install end to end from an offline image tar (deploy/e2e-install.sh).
# Usage: wsl-e2e.sh <images.tar> <log dir>
set -euo pipefail
TAR=${1:?images.tar}; LOGS=${2:?log dir}
cd "$(dirname "$0")/../.."
fail() { printf '✘ %s\n' "$*" >&2; exit 1; }
mkdir -p "$LOGS"

[ "$(id -u)" = 0 ] || fail "run as root"
# Docker Desktop's Windows shim on PATH would make install.sh skip installing the engine.
! command -v docker >/dev/null || fail "docker already on PATH (set appendWindowsPath=false in /etc/wsl.conf)"
systemctl is-system-running --wait 2>/dev/null | grep -Eq 'running|degraded' || fail "systemd is not running (wsl.conf [boot] systemd=true)"
# All WSL2 distros share one network namespace: another distro holding these ports would break the install.
[ -z "$(ss -ltnH '( sport = :80 or sport = :443 or sport = :18080 )')" ] || fail "80/443/18080 already in use in the WSL VM"
awk '/MemAvailable/ { exit !($2 > 3000000) }' /proc/meminfo || fail "less than 3 GB free in the WSL VM"
[ -f "$TAR" ] || fail "no image tar at $TAR"
grep -q ' dahae.test$' /etc/hosts || echo '127.0.0.1 dahae.test' >> /etc/hosts
command -v python3 >/dev/null || { apt-get update -qq && apt-get install -y -qq python3 >/dev/null; }

E2E_IMAGES_TAR=$TAR E2E_LOG_DIR=$LOGS E2E_DOMAIN=dahae.test bash deploy/e2e-install.sh
echo "E2E PASS"
