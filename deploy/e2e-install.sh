#!/usr/bin/env bash
# End-to-end install test. Runs the real deploy/install.sh and the `malkkeum` command it installs,
# against the two images built on this machine (pushed to a local registry on :5000).
# Used by .github/workflows/e2e.yml. Needs Docker, sudo and the registry container already running.
set -euo pipefail
cd "$(dirname "$0")/.."

REG=localhost:5000
TAG=e2e
DOMAIN=malkkeum.test
LOG=$(mktemp -d)
ENVS=(
  "MALKKEUM_DOMAIN=$DOMAIN" "MALKKEUM_EMAIL=ci@example.com" "MALKKEUM_IMAGES=$REG"
  "MALKKEUM_VERSION=$TAG" "MALKKEUM_TLS=internal" "MALKKEUM_HEALTH_WAIT=240"
)

step() { printf '\n== %s\n' "$*"; }
fail() {
  printf '::error::%s\n' "$*"
  (cd /opt/malkkeum && sudo docker compose --env-file .env ps && sudo docker compose --env-file .env logs --tail 80) || true
  exit 1
}
expect() { # expect "설명" 명령... : 명령이 성공해야 통과
  local what="$1"; shift
  "$@" || fail "$what"
  echo "ok: $what"
}
get() { curl -sk --max-time 10 --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN$1"; }
code() { curl -sk --max-time 10 -o /dev/null -w '%{http_code}' --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN$1"; }
dbq() { (cd /opt/malkkeum && sudo docker compose --env-file .env exec -T db psql -U app -d cleaning -tAc "$1"); }
malkkeum() { sudo /usr/local/bin/malkkeum "$@"; }
install_once() { sudo env "${ENVS[@]}" bash deploy/install.sh; }

api_healthy() { get /health | grep -q '"ok":true'; }
api_version_is_test() { get /health | grep -q "\"version\":\"$TAG\""; }
website_served() { [ "$(code /)" = 200 ] && get / | grep -qi '<html'; }
console_served() { [ "$(code /admin/)" = 200 ] && get /admin/ | grep -q 'base href="/admin/"'; }
csp_tight() { # CSP on the site: PortOne-only connect-src, no unsafe-eval, nothing may frame us
  local h; h="$(curl -sk --max-time 10 -D - -o /dev/null --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN/")"
  local csp; csp="$(echo "$h" | grep -i '^content-security-policy:')"
  echo "$csp" | grep -q "connect-src 'self' https://\*\.portone\.io" \
    && echo "$csp" | grep -q "frame-ancestors 'none'" \
    && ! echo "$csp" | grep -qi 'unsafe-eval'
}
needs_owner() { get /v1/setup | grep -q '"needs_admin":true'; }
owner_is_set_up() { get /v1/setup | grep -q '"needs_admin":false'; }
one_staff() { [ "$(dbq 'select count(*) from staff')" = 1 ]; }
setup_code_is() { [ "$(malkkeum setup-code)" = "$1" ]; }
cron_installed() { sudo test -f /etc/cron.d/malkkeum; }
version_shown() { malkkeum version | grep -q "$TAG"; }
backup_written() { sudo sh -c 'ls /opt/malkkeum/backups/db-*.sql.gz >/dev/null'; }
create_owner() {
  curl -sk --resolve "$DOMAIN:443:127.0.0.1" -X POST "https://$DOMAIN/v1/setup/admin" \
    -H 'Content-Type: application/json' \
    -d "{\"code\":\"$CODE\",\"email\":\"owner@example.com\",\"name\":\"Owner\",\"password\":\"e2e-owner-password\"}" \
    | grep -q '"ok":true'
}
rolled_back_to_digest() { sudo grep -q '^API_IMAGE=.*@sha256:' /opt/malkkeum/.env; }

step "1. first install with the real installer"
install_once 2>&1 | tee "$LOG/install1.txt"
expect "installer finished" grep -q '설치가 끝났어요' "$LOG/install1.txt"
CODE=$(malkkeum setup-code)
expect "setup code printed by installer" grep -q "$CODE" "$LOG/install1.txt"

step "2. services answer over HTTPS"
expect "API health" api_healthy
expect "API reports the image version" api_version_is_test
expect "website served" website_served
expect "console served at /admin/" console_served
expect "CSP limits connect-src to PortOne and forbids eval" csp_tight
expect "setup wizard waits for the owner" needs_owner
expect "malkkeum status" malkkeum status
expect "malkkeum version shows the image version" version_shown
expect "cron jobs installed" cron_installed

step "3. owner account with the setup code"
expect "owner created with the setup code" create_owner
expect "one staff row" one_staff

step "4. backup"
expect "malkkeum backup" malkkeum backup
expect "backup file written" backup_written

step "5. re-running install.sh keeps data"
install_once > "$LOG/install2.txt" 2>&1 || fail "second install failed"
expect "installer detected the existing install" grep -q '기존 설치를 찾았어요' "$LOG/install2.txt"
expect "owner row survived" one_staff
expect "setup code unchanged" setup_code_is "$CODE"
expect "API still healthy" api_healthy
expect "owner still set up" owner_is_set_up

step "6. a broken release rolls back by itself"
docker tag "$REG/malkkeum-api:$TAG" "$REG/malkkeum-api:good"
docker push -q "$REG/malkkeum-api:good" >/dev/null
mkdir -p "$LOG/broken"
printf 'FROM %s/malkkeum-api:%s\nCMD ["sh", "-c", "echo broken release; exit 1"]\n' "$REG" "$TAG" \
  | docker build -q -f - -t "$REG/malkkeum-api:$TAG" "$LOG/broken" >/dev/null
docker push -q "$REG/malkkeum-api:$TAG" >/dev/null
set +e
sudo env MALKKEUM_HEALTH_WAIT=60 /usr/local/bin/malkkeum update 2>&1 | tee "$LOG/update-broken.txt"
rc=${PIPESTATUS[0]}
set -e
expect "update exits non-zero" test "$rc" -ne 0
expect "update says it rolled back" grep -q '이전 버전으로 되돌렸어요' "$LOG/update-broken.txt"
expect "API healthy after rollback" api_healthy
expect "running the recorded digest" rolled_back_to_digest
expect "data survived the failed update" one_staff

step "7. a good release updates normally"
docker tag "$REG/malkkeum-api:good" "$REG/malkkeum-api:$TAG"
docker push -q "$REG/malkkeum-api:$TAG" >/dev/null
malkkeum update 2>&1 | tee "$LOG/update-good.txt"
expect "update succeeded" grep -q '업데이트했어요' "$LOG/update-good.txt"
expect "API healthy after update" api_healthy
expect "data survived the update" one_staff

printf '\n✔ install end-to-end test passed\n'
