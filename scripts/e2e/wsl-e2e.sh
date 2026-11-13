#!/usr/bin/env bash
# Inside a throwaway WSL distro (scripts/e2e/wsl-e2e.ps1 creates it), as root: check the distro is clean,
# then run the real install end to end from an offline image tar (deploy/e2e-install.sh).
# With an old install.sh as third argument it tests the upgrade instead: old install → data + backup → new install.sh.
# Usage: wsl-e2e.sh <images.tar> <log dir> [old install.sh]
set -euo pipefail
TAR=${1:?images.tar}; LOGS=${2:?log dir}; OLD=${3:-}
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

INSTALL_ENV=("MALKKEUM_IMAGES_TAR=$TAR" MALKKEUM_DOMAIN=dahae.test MALKKEUM_EMAIL=ci@example.com MALKKEUM_VERSION=e2e
  MALKKEUM_TLS=internal MALKKEUM_HEALTH_WAIT=240)
dbq() { (cd /opt/malkkeum && docker compose --env-file .env exec -T db psql -U app -d cleaning -tAc "$1"); }
expect() { local what="$1"; shift; "$@" || fail "upgrade: $what"; echo "ok: upgrade: $what"; }
app_role_ok() { # same check as deploy/e2e-install.sh: the API signs in as dahae_api, which is not a superuser
  [ "$(dbq "select rolsuper from pg_roles where rolname = 'dahae_api'")" = f ]     && [ "$(dbq "select count(*) > 0 from pg_stat_activity where usename = 'dahae_api'")" = t ]     && [ "$(dbq "select pg_get_userbyid(datdba) from pg_database where datname = 'cleaning'")" = dahae_api ]
}
customer_rows() { dbq "select count(*) from users where phone = '01099990001'"; }
upgrade() {
  env "${INSTALL_ENV[@]}" bash "$OLD" > "$LOGS/upgrade-old.txt" 2>&1 || { tail -n 40 "$LOGS/upgrade-old.txt"; fail "old installer failed"; }
  expect "old install runs the API as the superuser" test "$(dbq "select count(*) from pg_roles where rolname = 'dahae_api'")" = 0
  dbq "insert into users (phone, name) values ('01099990001', 'e2e upgrade customer')" >/dev/null
  /usr/local/bin/dahae backup
  local backup; backup=$(ls -t /opt/malkkeum/backups/db-*.sql.gz | head -n1)
  chmod 644 /opt/malkkeum/.env # an old server whose .env got wider permissions
  env "${INSTALL_ENV[@]}" bash deploy/install.sh > "$LOGS/upgrade-new.txt" 2>&1 || { tail -n 40 "$LOGS/upgrade-new.txt"; fail "new installer failed"; }
  expect "re-run took the upgrade path" grep -q '기존 설치를 찾았어요' "$LOGS/upgrade-new.txt"
  expect "API uses the non-superuser DB role" app_role_ok
  expect "customer row survived" test "$(customer_rows)" = 1
  expect ".env is 600" test "$(stat -c %a /opt/malkkeum/.env)" = 600
  dbq "delete from users where phone = '01099990001'" >/dev/null
  /usr/local/bin/dahae restore "$backup" --yes 2>&1 | tee "$LOGS/upgrade-restore.txt"
  [ "${PIPESTATUS[0]}" = 0 ] || fail "restore of the pre-upgrade backup failed"
  expect "pre-upgrade backup restores the customer" test "$(customer_rows)" = 1
  expect "restore kept the DB owned by the app role" app_role_ok
  /usr/local/bin/dahae uninstall --purge --confirm dahae.test >/dev/null
}

if [ -n "$OLD" ]; then upgrade; echo "E2E UPGRADE PASS"; exit 0; fi
E2E_IMAGES_TAR=$TAR E2E_LOG_DIR=$LOGS E2E_DOMAIN=dahae.test bash deploy/e2e-install.sh
echo "E2E PASS"
