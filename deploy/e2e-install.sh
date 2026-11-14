#!/usr/bin/env bash
# End-to-end install test. Runs the real deploy/install.sh and the `dahae` command it installs against the two
# server images built on this machine, then uses the stack the way an owner would.
#
# Two image sources:
#   registry (default)       images pushed to a local registry on :5000 (.github/workflows/e2e.yml)
#   E2E_IMAGES_TAR=<f.tar>   `docker save` of api + web (+ postgres:17), installed offline (scripts/e2e/wsl-e2e.sh)
# Other knobs: E2E_LOG_DIR (default: a temp dir), E2E_DOMAIN (default dahae.test).
# Needs Docker (or lets install.sh install it), root or sudo, python3 and curl. Leaves nothing behind: the last
# step runs `dahae uninstall --purge`.
set -euo pipefail
cd "$(dirname "$0")/.."

TAG=e2e
DOMAIN=${E2E_DOMAIN:-dahae.test}
TAR=${E2E_IMAGES_TAR:-}
LOG=${E2E_LOG_DIR:-$(mktemp -d)}
SUDO=; [ "$(id -u)" = 0 ] || SUDO=sudo
OWNER_EMAIL=owner@example.com
OWNER_PASSWORD=e2e-owner-password
FINGERPRINT=$(printf 'AB:%.0s' $(seq 31))AB
TEAM_ID=ABCDE12345
HEARTBEAT=https://example.com/e2e-heartbeat
PROJECT=malkkeum # compose project = basename of /opt/malkkeum
if [ -n "$TAR" ]; then
  REG=ghcr.io/ericwijesinghe
  ENVS=("MALKKEUM_IMAGES_TAR=$TAR")
else
  REG=localhost:5000
  ENVS=("MALKKEUM_IMAGES=$REG" "MALKKEUM_SKIP_SIGNATURE=1") # locally built images carry no release signature
fi
ENVS+=("MALKKEUM_DOMAIN=$DOMAIN" "MALKKEUM_EMAIL=ci@example.com" "MALKKEUM_VERSION=$TAG" "MALKKEUM_TLS=internal"
  "MALKKEUM_HEALTH_WAIT=240" "MALKKEUM_AGENT_FILE=$(pwd)/deploy/agent.sh")
mkdir -p "$LOG"

step() { printf '\n== %s  (%s)\n' "$*" "$(date +%T)"; }
fail() {
  printf '::error::%s\n' "$*"
  (cd /opt/malkkeum && $SUDO docker compose --env-file .env ps && $SUDO docker compose --env-file .env logs --tail 80) || true
  exit 1
}
expect() { # expect "설명" 명령... : 명령이 성공해야 통과
  local what="$1"; shift
  "$@" || fail "$what"
  echo "ok: $what"
}
curl_d() { curl -sk --max-time 20 --resolve "$DOMAIN:443:127.0.0.1" "$@"; }
get() { curl_d "https://$DOMAIN$1"; }
code() { curl_d -o /dev/null -w '%{http_code}' "https://$DOMAIN$1"; }
post() { curl_d -H 'Content-Type: application/json' -X POST "https://$DOMAIN$1" -d "$2"; }
get_auth() { curl_d -H "Authorization: Bearer $2" "https://$DOMAIN$1"; }
dc() { (cd /opt/malkkeum && $SUDO docker compose --env-file .env "$@"); }
dbq() { dc exec -T db psql -U app -d cleaning -tAc "$1"; }
dahae() { $SUDO /usr/local/bin/dahae "$@"; }
install_once() { $SUDO env "${ENVS[@]}" bash deploy/install.sh; }
publish() { [ -n "$TAR" ] || docker push -q "$1" >/dev/null; } # tar mode: the stack uses this engine's images
json() { python3 -I -c 'import json, sys
v = json.load(sys.stdin)
for k in sys.argv[1:]: v = v[k]
print(v if not isinstance(v, (dict, list)) else json.dumps(v))' "$@"; }
totp() { python3 -I -c 'import base64, hashlib, hmac, struct, sys, time
s = sys.argv[1]; key = base64.b32decode(s + "=" * (-len(s) % 8))
h = hmac.new(key, struct.pack(">Q", int(time.time()) // 30), hashlib.sha1).digest(); o = h[-1] & 15
print("%06d" % ((struct.unpack(">I", h[o:o + 4])[0] & 0x7FFFFFFF) % 1000000))' "$1"; }
fresh_totp() { # each 30 s step is accepted once: wait for one not used yet (a file, as callers run in $(...))
  while [ "$(($(date +%s) / 30))" = "$(cat "$LOG/totp-step" 2>/dev/null)" ]; do sleep 2; done
  echo "$(($(date +%s) / 30))" > "$LOG/totp-step"; totp "$SECRET"
}
memcap() { # the stack on a 2 GB VPS (compose auto-loads docker-compose.override.yml)
  printf 'services:\n  db: {mem_limit: 768m}\n  api: {mem_limit: 512m}\n  web: {mem_limit: 256m}\n' \
    | $SUDO tee /opt/malkkeum/docker-compose.override.yml >/dev/null
}
wait_until() { # wait_until 초 명령... : 명령이 성공할 때까지 기다려요
  local limit="$1" waited=0; shift
  until "$@" >/dev/null 2>&1; do [ "$waited" -ge "$limit" ] && return 1; sleep 5; waited=$((waited + 5)); done
}

api_healthy() { get /health | grep -q '"ok":true'; }
api_version_is_test() { get /health | grep -q "\"version\":\"$TAG\""; }
website_served() { [ "$(code /)" = 200 ] && get / | grep -qi '<html'; }
console_served() { [ "$(code /admin/)" = 200 ] && get /admin/ | grep -q 'base href="/admin/"'; }
csp_of() { curl_d -D - -o /dev/null "https://$DOMAIN$1" | grep -i '^content-security-policy:'; }
csp_tight() { # apps: PortOne-only connect-src, no unsafe-eval, nothing may frame us
  local csp; csp="$(csp_of /admin/)"
  echo "$csp" | grep -q "connect-src 'self' https://\*\.portone\.io" \
    && echo "$csp" | grep -q "frame-ancestors 'none'" \
    && ! echo "$csp" | grep -qi "'unsafe-eval'" # 'wasm-unsafe-eval' (Flutter --wasm) is fine
}
site_csp_strict() { # website: inline scripts by hash only, nothing but same-origin calls
  local csp; csp="$(csp_of /)"
  echo "$csp" | grep -q "script-src 'self' 'sha256-" && ! echo "$csp" | grep -q "'unsafe-inline' 'wasm" \
    && echo "$csp" | grep -q "connect-src 'self';" && echo "$csp" | grep -q "frame-ancestors 'none'"
}
hardened() { # hardened 서비스 : read-only root, every capability dropped, no privilege gain
  local id; id=$(dc ps -q "$1") && [ -n "$id" ] \
    && [ "$($SUDO docker inspect -f '{{.HostConfig.ReadonlyRootfs}} {{.HostConfig.CapDrop}} {{.HostConfig.SecurityOpt}}' "$id")" = "true [ALL] [no-new-privileges:true]" ]
}
KEYS_PASS=e2e-keys-passphrase
keys_file() { $SUDO sh -c 'ls -t /opt/malkkeum/backups/keys-*.env.enc 2>/dev/null | head -n1'; }
data_key() { $SUDO grep -E '^DATA_KEY=' /opt/malkkeum/.env | cut -d= -f2; }
needs_owner() { get /v1/setup | grep -q '"needs_admin":true'; }
owner_is_set_up() { get /v1/setup | grep -q '"needs_admin":false'; }
staff_count_is() { [ "$(dbq 'select count(*) from staff')" = "$1" ]; }
setting_count_is() { [ "$(dbq "select count(*) from settings where key = '$1'")" = "$2" ]; }
setup_code_is() { [ "$(dahae setup-code)" = "$1" ]; }
app_role_ok() { # the API signs in as dahae_api, which is not a superuser
  [ "$(dbq "select rolsuper from pg_roles where rolname = 'dahae_api'")" = f ]     && [ "$(dbq "select count(*) > 0 from pg_stat_activity where usename = 'dahae_api'")" = t ]     && [ "$(dbq "select pg_get_userbyid(datdba) from pg_database where datname = 'cleaning'")" = dahae_api ]
}
purge_needs_domain() { ! $SUDO setsid -w env DAHAE_YES=1 /usr/local/bin/dahae uninstall --purge --yes </dev/null >/dev/null 2>&1; } # no terminal
mode_is() { [ "$($SUDO stat -c %a "$1")" = "$2" ]; }
version_shown() { dahae version | grep -q "$TAG"; }
backups_count() { $SUDO sh -c 'ls /opt/malkkeum/backups/db-*.sql.gz 2>/dev/null | wc -l'; }
create_owner() {
  post /v1/setup/admin "{\"code\":\"$CODE\",\"email\":\"$OWNER_EMAIL\",\"name\":\"Owner\",\"password\":\"$OWNER_PASSWORD\"}" \
    | grep -q '"ok":true'
}
staff_login() { post /v1/auth/staff/login "{\"email\":\"$OWNER_EMAIL\",\"password\":\"$OWNER_PASSWORD\"}"; }
owner_token() { # console sign-in: password, then the TOTP second factor
  local mfa; mfa=$(staff_login | json mfa_token)
  post /v1/auth/staff/mfa/verify "{\"mfa_token\":\"$mfa\",\"code\":\"$(fresh_totp)\"}" | json access_token
}
wizard_has_sections() { local o; o=$(get_auth /v1/admin/setup "$TOKEN"); for s in portone solapi backup business; do echo "$o" | grep -q "\"$s\"" || return 1; done; }
heartbeat_on_in_wizard() { get_auth /v1/admin/setup "$(owner_token)" | grep -q '"heartbeat_configured":true'; }
upload_marker() { dc exec -T api cat /data/uploads/e2e-marker.txt 2>/dev/null | grep -q e2e-upload; }
no_old_brand() { ! grep -q '말끔' "$LOG/install1.txt"; }
rolled_back_to_pinned() { $SUDO grep -Eq '^API_IMAGE=.*(@sha256:|:keep-)' /opt/malkkeum/.env; }
api_env_is() { [ "$(dc exec -T api printenv "$1" 2>/dev/null)" = "$2" ]; }
no_dev_code() { ! post /v1/auth/otp '{"phone":"01012345678"}' | grep -q dev_code; }
dev_api_up() { curl -fs --max-time 5 http://127.0.0.1:18080/health; }
nothing_left() {
  [ -z "$($SUDO docker ps -aq --filter "label=com.docker.compose.project=$PROJECT")" ] \
    && [ -z "$($SUDO docker volume ls -q --filter "label=com.docker.compose.project=$PROJECT")" ] \
    && ! $SUDO test -e /etc/cron.d/malkkeum && ! $SUDO test -e /etc/logrotate.d/dahae \
    && ! test -e /usr/local/bin/dahae && ! test -e /usr/local/bin/malkkeum && ! $SUDO test -e /opt/malkkeum
}

step "1. first install with the real installer ($([ -n "$TAR" ] && echo "offline tar" || echo registry))"
install_once 2>&1 | tee "$LOG/install1.txt"
[ "${PIPESTATUS[0]}" = 0 ] || fail "first install failed"
expect "installer finished" grep -q '설치가 끝났어요' "$LOG/install1.txt"
expect "installer text says 다해" grep -q '다해' "$LOG/install1.txt"
expect "no old brand in installer text" no_old_brand
expect "dahae command installed" test -x /usr/local/bin/dahae
expect "malkkeum alias kept" test -x /usr/local/bin/malkkeum
CODE=$(dahae setup-code)
expect "setup code printed by installer" grep -q "$CODE" "$LOG/install1.txt"
expect ".env readable by root only" mode_is /opt/malkkeum/.env 600
expect "backups readable by root only" mode_is /opt/malkkeum/backups 700
expect "cron jobs installed" $SUDO test -f /etc/cron.d/malkkeum
expect "log rotation installed" $SUDO test -f /etc/logrotate.d/dahae
expect "API uses the non-superuser DB role" app_role_ok
for s in db api web; do expect "$s container hardened (read-only, no capabilities)" hardened "$s"; done
expect "cron reports a failed unattended update" $SUDO grep -q 'dahae auto-update .*|| .*dahae alert update' /etc/cron.d/malkkeum
expect "agent path unit is active" $SUDO systemctl is-active --quiet dahae-agent.path
expect "agent timer is active" $SUDO systemctl is-active --quiet dahae-agent.timer
expect "job status folder is root-owned" sh -c "[ \"\$($SUDO stat -c %u /opt/malkkeum/jobs/status)\" = 0 ]"
expect "job inbox belongs to the API user" sh -c "[ \"\$($SUDO stat -c %u /opt/malkkeum/jobs/inbox)\" = 10001 ]"
memcap; dc up -d >/dev/null 2>&1
expect "healthy with 2 GB VPS memory limits" wait_until 180 api_healthy

step "2. services answer over HTTPS"
expect "API health" api_healthy
expect "API reports the image version" api_version_is_test
expect "website served" website_served
expect "console served at /admin/" console_served
expect "app CSP limits connect-src to PortOne and forbids eval" csp_tight
expect "website CSP allows inline scripts by hash only" site_csp_strict
expect "setup wizard waits for the owner" needs_owner
expect "dahae status" dahae status
expect "dahae version shows the image version" version_shown

step "3. owner account, console sign-in, setup wizard"
expect "owner created with the setup code" create_owner
expect "one staff row" staff_count_is 1
expect "setup code is single use" test "$(post /v1/setup/admin "{\"code\":\"$CODE\",\"email\":\"x@example.com\",\"name\":\"X\",\"password\":\"another-password-1\"}" | grep -c '"ok":true')" = 0
MFA=$(staff_login | json mfa_token)
expect "first console sign-in asks for TOTP enrolment" test -n "$MFA"
SECRET=$(post /v1/auth/staff/mfa/enrol "{\"mfa_token\":\"$MFA\"}" | json secret)
TOKEN=$(post /v1/auth/staff/mfa/enrol/confirm "{\"mfa_token\":\"$MFA\",\"code\":\"$(fresh_totp)\"}" | json access_token)
expect "TOTP enrolment signs the owner in" test -n "$TOKEN"
expect "wizard lists payments, SMS, backup, business" wizard_has_sections
expect "second sign-in with TOTP" test -n "$(owner_token)"

step "4. backup and restore round trip"
dbq "insert into settings (key, value) values ('e2e_before', 'true')" >/dev/null
dc exec -T api sh -c 'echo e2e-upload > /data/uploads/e2e-marker.txt'
expect "dahae backup" dahae backup
BACKUP=$($SUDO sh -c 'ls -t /opt/malkkeum/backups/db-*.sql.gz | head -n1')
dbq "insert into settings (key, value) values ('e2e_after', 'true')" >/dev/null
dc exec -T api rm /data/uploads/e2e-marker.txt
dahae restore "$BACKUP" --yes 2>&1 | tee "$LOG/restore.txt"
[ "${PIPESTATUS[0]}" = 0 ] || fail "dahae restore failed"
expect "restore says done" grep -q '복원 완료' "$LOG/restore.txt"
expect "row from before the backup is back" setting_count_is e2e_before 1
expect "row written after the backup is gone" setting_count_is e2e_after 0
expect "uploads restored" upload_marker
expect "owner kept" staff_count_is 1
expect "API healthy after restore" api_healthy
expect "restore kept the DB owned by the app role" app_role_ok
KEY_BEFORE=$(data_key)
expect "dahae keys-backup" $SUDO env DAHAE_KEYS_PASSPHRASE=$KEYS_PASS /usr/local/bin/dahae keys-backup
expect "key copy is not plain text" sh -c "! $SUDO grep -q DATA_KEY '$(keys_file)'"
expect "wrong passphrase changes nothing" sh -c "! $SUDO env DAHAE_KEYS_PASSPHRASE=wrong-passphrase-x /usr/local/bin/dahae keys-restore '$(keys_file)' --yes"
expect "dahae keys-restore" $SUDO env DAHAE_KEYS_PASSPHRASE=$KEYS_PASS /usr/local/bin/dahae keys-restore "$(keys_file)" --yes
expect "same DATA_KEY after the round trip" test "$(data_key)" = "$KEY_BEFORE"
expect "API healthy after keys-restore" api_healthy

step "5. re-running install.sh is a safe upgrade"
before=$(backups_count)
install_once > "$LOG/install2.txt" 2>&1 || { tail -n 40 "$LOG/install2.txt"; fail "second install failed"; }
expect "installer detected the existing install" grep -q '기존 설치를 찾았어요' "$LOG/install2.txt"
expect "re-run backed up first" test "$(backups_count)" -gt "$before"
expect "owner row survived" staff_count_is 1
expect "setup code unchanged" setup_code_is "$CODE"
expect "API still healthy" api_healthy
expect "owner still set up" owner_is_set_up
expect "banner does not show a dead setup code" sh -c "! grep -q '$CODE' '$LOG/install2.txt'"

# a job file as the API writes it: owned by the API user (10001), UUIDv7 named by the current time
queue_job() { # queue_job 종류 : 작업 파일을 inbox 에 넣고 번호를 돌려줘요
  local ms id
  ms=$(($(date +%s) * 1000)); id=$(printf '%012x' "$ms")
  id="${id:0:8}-${id:8:4}-7000-8000-$(printf '%012d' "$RANDOM$RANDOM")"
  printf 'id=%s\nkind=%s\n' "$id" "$1" > "$LOG/$id.job"
  $SUDO install -o 10001 -g 10001 -m 600 "$LOG/$id.job" "/opt/malkkeum/jobs/inbox/$id.job" && echo "$id"
}
job_state_is() { $SUDO grep -q "\"state\":\"$2\"" "/opt/malkkeum/jobs/status/$1.json" 2>/dev/null; }

step "5b. a queued job is run by the root agent"
JOB=$(queue_job status-refresh)
expect "agent runs the queued job" wait_until 90 job_state_is "$JOB" ok
expect "agent wrote host.json" $SUDO test -s /opt/malkkeum/host/host.json

step "6. a broken release rolls back by itself"
docker tag "$REG/malkkeum-api:$TAG" "$REG/malkkeum-api:good"
publish "$REG/malkkeum-api:good"
mkdir -p "$LOG/broken"
printf 'FROM %s/malkkeum-api:%s\nCMD ["sh", "-c", "echo broken release; exit 1"]\n' "$REG" "$TAG" \
  | docker build -q -f - -t "$REG/malkkeum-api:$TAG" "$LOG/broken" >/dev/null
publish "$REG/malkkeum-api:$TAG"
set +e
$SUDO env MALKKEUM_HEALTH_WAIT=60 /usr/local/bin/dahae update 2>&1 | tee "$LOG/update-broken.txt"
rc=${PIPESTATUS[0]}
set -e
expect "update exits non-zero" test "$rc" -ne 0
expect "update says it rolled back" grep -q '이전 버전으로 되돌렸어요' "$LOG/update-broken.txt"
expect "update exits 3 when it rolled back" test "$rc" -eq 3
JOB=$(queue_job update)
expect "a queued update that rolls back ends rolled_back" wait_until 900 job_state_is "$JOB" rolled_back
expect "API healthy after rollback" api_healthy
expect "running the pinned previous image" rolled_back_to_pinned
expect "data survived the failed update" staff_count_is 1

step "7. a good release updates normally"
docker tag "$REG/malkkeum-api:good" "$REG/malkkeum-api:$TAG"
publish "$REG/malkkeum-api:$TAG"
dahae update 2>&1 | tee "$LOG/update-good.txt"
expect "update succeeded" grep -q '업데이트했어요' "$LOG/update-good.txt"
expect "API healthy after update" api_healthy
expect "data survived the update" staff_count_is 1

step "8. heartbeat and app links without editing .env"
dahae heartbeat "$HEARTBEAT" 2>&1 | tee "$LOG/heartbeat.txt"
expect "heartbeat URL reaches the API" api_env_is HEARTBEAT_URL "$HEARTBEAT"
expect "wizard shows heartbeat on" heartbeat_on_in_wizard
expect "bad heartbeat URL refused" sh -c "! $SUDO /usr/local/bin/dahae heartbeat 'http://x.example/a b'"
expect "heartbeat off" dahae heartbeat off
expect "heartbeat URL cleared" api_env_is HEARTBEAT_URL ""
expect "dahae applinks" dahae applinks --android-sha256 "$FINGERPRINT" --apple-team-id "$TEAM_ID"
expect "assetlinks.json lists the signing cert" sh -c "curl -sk --resolve '$DOMAIN:443:127.0.0.1' https://$DOMAIN/.well-known/assetlinks.json | grep -q '$FINGERPRINT'"
expect "apple-app-site-association names the team" sh -c "curl -sk --resolve '$DOMAIN:443:127.0.0.1' https://$DOMAIN/.well-known/apple-app-site-association | grep -q '$TEAM_ID'"
expect "bad fingerprint refused" sh -c "! $SUDO /usr/local/bin/dahae applinks --android-sha256 nope"

step "9. scripts/smoke.py against the installed stack (temporary dev override)"
$SUDO cp scripts/e2e/override.dev.yml /opt/malkkeum/docker-compose.override.yml
$SUDO install -m 755 scripts/e2e/psql-shim.sh /usr/local/bin/dahae-e2e-psql
dc up -d api >/dev/null 2>&1
expect "dev API answers on 127.0.0.1:18080" wait_until 180 dev_api_up
PSQL=/usr/local/bin/dahae-e2e-psql python3 -I scripts/smoke.py http://127.0.0.1:18080 2>&1 | tee "$LOG/smoke.txt"
[ "${PIPESTATUS[0]}" = 0 ] || fail "smoke.py failed"
memcap; $SUDO rm -f /usr/local/bin/dahae-e2e-psql
dc up -d >/dev/null 2>&1
expect "back to production config" wait_until 180 api_env_is DEV_MODE 0
expect "API healthy in production mode" wait_until 180 api_healthy
expect "no dev login codes in production mode" no_dev_code

step "10. uninstall"
expect "--purge is not skipped by --yes or DAHAE_YES" purge_needs_domain
expect "still installed after the refused purge" $SUDO test -f /opt/malkkeum/.env
dahae uninstall --purge --confirm "$DOMAIN" 2>&1 | tee "$LOG/uninstall.txt"
[ "${PIPESTATUS[0]}" = 0 ] || fail "dahae uninstall failed"
expect "containers, volumes, cron, CLI and /opt/malkkeum removed" nothing_left

printf '\n✔ install end-to-end test passed\n'
