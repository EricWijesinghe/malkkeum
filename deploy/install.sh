#!/usr/bin/env bash
# 말끔 서버 설치 프로그램 (Ubuntu 22.04 / 24.04, Debian 12)
#
#   curl -fsSL https://raw.githubusercontent.com/EricWijesinghe/malkkeum-install/main/install.sh | sudo bash
#   (베타 채널: .../beta/install.sh)
#
# 질문 두 개(도메인, 이메일)에 답하면 Docker 설치, 보안 키 생성, HTTPS 자동 설정, 매일 백업,
# `malkkeum` 명령 설치까지 끝냅니다. 다시 실행해도 안전합니다: 설정과 데이터는 그대로 두고 서비스만 맞춥니다.
#
# 자동 설치·테스트용 환경 변수 (보통은 필요 없어요):
#   MALKKEUM_DOMAIN, MALKKEUM_EMAIL   질문 대신 값 지정
#   MALKKEUM_IMAGES                   이미지 저장소 (기본: 릴리스 저장소)
#   MALKKEUM_IMAGES_TAR=<파일.tar>    인터넷 없이 미리 받아 둔 이미지 묶음 설치 (체험·오프라인용, 버전 기본: local)
#   MALKKEUM_CHANNEL                  stable | beta
#   MALKKEUM_VERSION                  채널 대신 쓸 이미지 태그 (테스트용)
#   MALKKEUM_TLS=internal             공인 인증서 대신 내부 인증 기관 사용 (테스트용)
#   MALKKEUM_SKIP_DNS_CHECK=1         도메인 IP 확인 생략
#   MALKKEUM_HEALTH_WAIT=300          기동 확인 대기 시간(초)
#   MALKKEUM_HEARTBEAT_URL=<핑 주소>    외부 가동 확인(healthchecks.io 등). 없으면 경고만 해요
set -euo pipefail

IMAGE_REPO_DEFAULT=ghcr.io/ericwijesinghe
DEFAULT_CHANNEL=stable
DIR=/opt/malkkeum
HEALTH_WAIT_SECS=${MALKKEUM_HEALTH_WAIT:-300}

say()  { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m✘ %s\033[0m\n' "$*" >&2; exit 1; }
dc()   { docker compose --env-file .env "$@"; }

ask() { # ask "질문" 기본값 -> 답 (터미널이 없으면 기본값)
  local q="$1" def="${2:-}" a=""
  if (: </dev/tty) 2>/dev/null; then
    printf '%s%s: ' "$q" "${def:+ [$def]}" >/dev/tty
    IFS= read -r a </dev/tty || true
  fi
  printf '%s' "${a:-$def}"
}

rand_hex() { openssl rand -hex "$1"; }
setup_code() { # 0/O/1/I/L 을 뺀 12자리. 화면을 보고 손으로 입력하는 코드예요.
  local alphabet=23456789ABCDEFGHJKMNPQRSTUVWXYZ code=""
  while [ ${#code} -lt 12 ]; do
    local b; b=$(od -An -N1 -tu1 /dev/urandom | tr -d ' ')
    [ "$b" -lt 248 ] && code="$code${alphabet:$((b % 31)):1}"
  done
  printf '%s' "$code"
}

env_set() { # env_set 키 값 : .env 에 키가 있으면 바꾸고, 없으면 추가해요
  local k="$1" v="$2" tmp; tmp=$(mktemp)
  if grep -q "^$k=" .env; then
    awk -v k="$k" -v v="$v" 'index($0, k "=") == 1 { print k "=" v; next } { print }' .env > "$tmp"
  else
    { cat .env; printf '%s=%s\n' "$k" "$v"; } > "$tmp"
  fi
  cat "$tmp" > .env; rm -f "$tmp"
}

load_images() { # load_images 파일 이미지... : tar 를 docker load 하고, 필요한 이미지가 다 있는지 확인해요
  local f="$1" img; shift
  [ -f "$f" ] || die "이미지 파일을 찾을 수 없어요: $f"
  docker load -i "$f" >/dev/null || die "이미지 파일을 불러오지 못했어요: $f"
  for img in "$@"; do
    docker image inspect "$img" >/dev/null 2>&1 || die "이미지 파일에 $img 이 없어요. 같은 버전으로 만든 파일인지 확인하세요."
  done
}

wait_healthy() { # 도메인을 이 서버로 직접 불러서 응답을 기다려요 (DNS 설정과 무관)
  local waited=0
  until curl -fsSk --max-time 5 --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN/health" >/dev/null 2>&1; do
    [ "$waited" -ge "$HEALTH_WAIT_SECS" ] && return 1
    sleep 5; waited=$((waited + 5))
  done
  return 0 # until 의 종료 상태는 마지막 실행 명령을 따라가서, 명시적으로 성공을 돌려줘요
}

[ "$(id -u)" -eq 0 ] || die "관리자 권한이 필요해요. 명령 앞에 sudo 를 붙여 다시 실행해 주세요."
command -v apt-get >/dev/null || die "Ubuntu 또는 Debian 서버에서 실행해 주세요."

say "말끔 서버 설치를 시작합니다"
mkdir -p "$DIR/backups"
cd "$DIR"

if [ -f .env ]; then
  ok "기존 설치를 찾았어요. 설정과 데이터는 그대로 두고 최신 버전으로 업데이트합니다."
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
  FRESH=0
else
  FRESH=1
fi

# 설정 값 우선순위: 환경 변수 > 기존 .env > 기본값
IMAGE_REPO=${MALKKEUM_IMAGES:-${IMAGE_REPO:-$IMAGE_REPO_DEFAULT}}
TLS_MODE=${MALKKEUM_TLS:-${TLS_MODE:-}}
CHANNEL=${MALKKEUM_CHANNEL:-${CHANNEL:-$DEFAULT_CHANNEL}}
VERSION=${MALKKEUM_VERSION:-${MALKKEUM_CHANNEL:-${VERSION:-$CHANNEL}}}
IMAGES_TAR=${MALKKEUM_IMAGES_TAR:-}
if [ -n "$IMAGES_TAR" ]; then
  IMAGE_SOURCE=local
  VERSION=${MALKKEUM_VERSION:-local}
else
  IMAGE_SOURCE=${IMAGE_SOURCE:-remote} # 한번 local 로 설치했으면 계속 local (이미지는 이 서버에 있어요)
fi
case "$CHANNEL" in stable|beta) ;; *) die "채널은 stable 또는 beta 중 하나예요." ;; esac
case "$TLS_MODE" in ""|internal) ;; *) die "MALKKEUM_TLS 는 internal 만 쓸 수 있어요." ;; esac

if [ -n "${MALKKEUM_DOMAIN:-}" ]; then
  DOMAIN=$MALKKEUM_DOMAIN
elif [ -z "${DOMAIN:-}" ]; then
  DOMAIN=$(ask "서비스 주소(도메인)를 입력하세요. 예: malkkeum.co.kr" "")
fi
DOMAIN=${DOMAIN#http://}; DOMAIN=${DOMAIN#https://}; DOMAIN=${DOMAIN%%/*}
# .env is sourced by root later: only plain host names and e-mail addresses may go in.
printf '%s' "$DOMAIN" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$' || die "도메인 형식이 올바르지 않아요: $DOMAIN (예: malkkeum.co.kr)"
[ -n "$DOMAIN" ] || die "도메인이 필요해요."
ACME_EMAIL=${MALKKEUM_EMAIL:-${ACME_EMAIL:-$(ask "보안 인증서 안내를 받을 이메일" "")}}
[ -z "$ACME_EMAIL" ] || printf '%s' "$ACME_EMAIL" | grep -Eq '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+$' || die "이메일 형식이 올바르지 않아요: $ACME_EMAIL"

say "필수 프로그램 설치"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl openssl gzip cron dnsutils >/dev/null
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh >/dev/null
fi
systemctl enable --now docker >/dev/null 2>&1 || true
docker compose version >/dev/null 2>&1 || die "Docker Compose 를 설치하지 못했어요."
ok "Docker 준비 완료"

say "도메인 확인"
if [ "$TLS_MODE" = internal ] || [ -n "${MALKKEUM_SKIP_DNS_CHECK:-}" ]; then
  ok "도메인 IP 확인은 건너뛰었어요 (테스트 설치)"
else
  SERVER_IP=$(curl -fsS4 https://api.ipify.org || true)
  DOMAIN_IP=$(dig +short A "$DOMAIN" | tail -n1 || true)
  if [ -n "$SERVER_IP" ] && [ "$SERVER_IP" = "$DOMAIN_IP" ]; then
    ok "$DOMAIN → $SERVER_IP (이 서버)"
  else
    warn "$DOMAIN 의 A 레코드가 이 서버($SERVER_IP)를 가리키지 않아요 (현재: ${DOMAIN_IP:-없음})."
    warn "도메인 관리 화면에서 A 레코드를 $SERVER_IP 로 설정하세요. 설정 후 몇 분 안에 HTTPS 가 자동으로 켜집니다."
  fi
fi

if [ "$FRESH" = 1 ]; then
  umask 077
  cat > .env <<EOF
# 말끔 서버 설정 — install.sh 가 만들었어요. 이 파일을 안전한 곳에 따로 보관하세요.
# DATA_KEY 를 잃어버리면 저장된 결제·연동 키와 계좌 정보를 복구할 수 없어요.
DB_PASSWORD=$(rand_hex 24)
JWT_SECRET=$(rand_hex 32)
DATA_KEY=$(rand_hex 32)
SETUP_CODE=$(setup_code)
EOF
  umask 022
  ok "보안 키를 새로 만들었어요"
fi
env_set DOMAIN "$DOMAIN"
env_set ACME_EMAIL "$ACME_EMAIL"
env_set IMAGE_REPO "$IMAGE_REPO"
env_set TLS_MODE "$TLS_MODE"
env_set CHANNEL "$CHANNEL"
env_set VERSION "$VERSION"
env_set API_IMAGE "$IMAGE_REPO/malkkeum-api:$VERSION"
env_set WEB_IMAGE "$IMAGE_REPO/malkkeum-web:$VERSION"
env_set IMAGE_SOURCE "$IMAGE_SOURCE"
if [ -n "${MALKKEUM_HEARTBEAT_URL:-}" ]; then env_set HEARTBEAT_URL "$MALKKEUM_HEARTBEAT_URL"; fi

cat > docker-compose.yml <<'EOF'
# Managed by install.sh — re-run the installer or `malkkeum update` instead of editing.
services:
  db:
    image: postgres:17
    restart: unless-stopped
    environment: { POSTGRES_DB: cleaning, POSTGRES_USER: app, POSTGRES_PASSWORD: "${DB_PASSWORD}" }
    volumes: [dbdata:/var/lib/postgresql/data]
    healthcheck: { test: ["CMD-SHELL", "pg_isready -U app -d cleaning"], interval: 5s, retries: 20 }
  api:
    image: ${API_IMAGE:?set by install.sh}
    restart: unless-stopped
    depends_on: { db: { condition: service_healthy } }
    environment:
      DATABASE_URL: postgres://app:${DB_PASSWORD}@db:5432/cleaning
      JWT_SECRET: "${JWT_SECRET}"
      DATA_KEY: "${DATA_KEY}"
      SETUP_CODE: "${SETUP_CODE}"
      PUBLIC_BASE_URL: https://${DOMAIN}
      ALLOWED_ORIGINS: https://${DOMAIN}
      TRUSTED_PROXY: "1"
      DEV_MODE: "0"
      RUST_LOG: info,sqlx=warn
      ANDROID_CERT_SHA256: "${ANDROID_CERT_SHA256:-}"
      APPLE_TEAM_ID: "${APPLE_TEAM_ID:-}"
    volumes: [uploads:/data/uploads]
    healthcheck: { test: ["CMD", "api", "--health"], interval: 15s, retries: 10, start_period: 20s }
  web:
    image: ${WEB_IMAGE:?set by install.sh}
    restart: unless-stopped
    depends_on: [api]
    ports: ["80:80", "443:443", "443:443/udp"]
    environment: { DOMAIN: "${DOMAIN}", ACME_EMAIL: "${ACME_EMAIL}", TLS_MODE: "${TLS_MODE}" }
    volumes: [caddydata:/data, caddyconfig:/config]
volumes: { dbdata: {}, uploads: {}, caddydata: {}, caddyconfig: {} }
EOF

# 관리 명령. 본문은 따옴표 heredoc 이라 그대로 옮겨지고, __DIR__ 만 바꿔 넣어요.
cat > /usr/local/bin/malkkeum <<'CLI'
#!/usr/bin/env bash
# 말끔 관리 명령. 사용법: malkkeum [status|update [태그]|load 파일.tar|rollback|channel stable|beta|version|backup|restore 파일|restore-offsite [이름]|demo load|demo clear|logs|setup-code]
set -euo pipefail
DIR=__DIR__
BACKUP_KEEP_DAYS=14
UPDATE_WAIT_SECS=${MALKKEUM_HEALTH_WAIT:-180}
cd "$DIR"
# Backups hold every customer's data: only root may read them.
umask 077
chmod 700 backups 2>/dev/null || true

dc() { docker compose --env-file .env "$@"; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m✘ %s\033[0m\n' "$*" >&2; exit 1; }
env_get() { { grep -E "^$1=" .env || true; } | tail -n1 | cut -d= -f2-; }
env_set() { # 키 값 : .env 에 기록 (있으면 바꾸고 없으면 추가)
  local k="$1" v="$2" tmp; tmp=$(mktemp)
  if grep -q "^$k=" .env; then
    awk -v k="$k" -v v="$v" 'index($0, k "=") == 1 { print k "=" v; next } { print }' .env > "$tmp"
  else
    { cat .env; printf '%s=%s\n' "$k" "$v"; } > "$tmp"
  fi
  cat "$tmp" > .env; rm -f "$tmp"
}
health_ok() {
  local d; d=$(env_get DOMAIN)
  curl -fsSk --max-time 5 --resolve "$d:443:127.0.0.1" "https://$d/health" >/dev/null 2>&1
}
wait_healthy() {
  local waited=0
  until health_ok; do
    [ "$waited" -ge "$UPDATE_WAIT_SECS" ] && return 1
    sleep 5; waited=$((waited + 5))
  done
  return 0 # until 의 종료 상태는 마지막 실행 명령을 따라가서, 명시적으로 성공을 돌려줘요
}
# 지금 쓰는 이미지를 저장소@다이제스트 형태로 기록해 둬야, 태그가 바뀌어도 되돌릴 수 있어요.
digest_ref() {
  local d; d=$(docker image inspect --format '{{index .RepoDigests 0}}' "$1" 2>/dev/null || true)
  printf '%s' "${d:-$1}"
}
# 이미지 두 개를 지정해서 기동하고 .env 에 기록해요.
set_images() {
  env_set API_IMAGE "$1"; env_set WEB_IMAGE "$2"
  dc up -d --remove-orphans
}

cmd_backup() {
  local ts; ts=$(date +%Y%m%d-%H%M%S)
  dc exec -T db pg_dump -U app -d cleaning --clean --if-exists | gzip > "backups/db-$ts.sql.gz"
  dc run --rm --no-deps -T --entrypoint tar api czf - -C /data uploads > "backups/uploads-$ts.tar.gz" 2>/dev/null || true
  find backups \( -name 'db-*.sql.gz' -o -name 'uploads-*.tar.gz' \) -mtime +"$BACKUP_KEEP_DAYS" -delete
  # Offsite copy (콘솔: 설정 > 외부 백업). The local backup stays good if this fails or isn't set up.
  dc run --rm --no-deps -T -v "$DIR/backups:/backups" api api backup-upload "/backups/uploads-$ts.tar.gz" >> backups/backup.log 2>&1 || true
  dc run --rm --no-deps -T -v "$DIR/backups:/backups" api api backup-upload "/backups/db-$ts.sql.gz" >> backups/backup.log 2>&1     || warn "외부 백업 실패 또는 미설정 — 콘솔 [설정 > 외부 백업]을 확인하세요"
  ok "백업 완료: $DIR/backups/db-$ts.sql.gz"
}

cmd_load() { # 미리 받아 둔 이미지 묶음(.tar)을 불러와요. 인터넷 없이 업데이트할 때 써요.
  local f="${1:?사용법: malkkeum load 파일.tar}"
  [ -f "$f" ] || die "파일을 찾을 수 없어요: $f"
  docker load -i "$f" || die "이미지 파일을 불러오지 못했어요: $f"
  env_set IMAGE_SOURCE local
  ok "이미지를 불러왔어요. 적용하려면: malkkeum update <태그>  (위 Loaded image 의 태그)"
}

cmd_update() { # malkkeum update [태그]: 태그를 주면 그 버전으로 바꿔요 (로컬 이미지면 먼저 malkkeum load)
  local repo ver cur_api cur_web
  printf '\n▶ 업데이트를 시작합니다 (먼저 백업해요)\n'
  cmd_backup || die "백업에 실패해서 업데이트를 멈췄어요. 'malkkeum logs' 로 확인하세요."
  repo=$(env_get IMAGE_REPO); ver=${1:-$(env_get VERSION)}
  cur_api=$(digest_ref "$(env_get API_IMAGE)"); cur_web=$(digest_ref "$(env_get WEB_IMAGE)")
  if [ "$(env_get IMAGE_SOURCE)" = local ]; then
    docker image inspect "$repo/malkkeum-api:$ver" "$repo/malkkeum-web:$ver" >/dev/null 2>&1 \
      || die "이미지 $ver 이 없어요. 먼저 'malkkeum load 파일.tar' 를 실행하세요."
  else
    docker pull -q "$repo/malkkeum-api:$ver" >/dev/null && docker pull -q "$repo/malkkeum-web:$ver" >/dev/null \
      || die "새 버전을 내려받지 못했어요. 지금 서비스는 그대로 돌고 있어요."
  fi
  env_set PREV_API_IMAGE "$cur_api"; env_set PREV_WEB_IMAGE "$cur_web"
  set_images "$repo/malkkeum-api:$ver" "$repo/malkkeum-web:$ver"
  if wait_healthy; then
    env_set VERSION "$ver"
    dc image prune -f --filter until=336h >/dev/null 2>&1 || true
    ok "최신 버전($ver)으로 업데이트했어요"
    return 0
  fi
  warn "새 버전이 응답하지 않아요. 이전 버전으로 되돌릴게요."
  set_images "$cur_api" "$cur_web"
  if wait_healthy; then
    die "업데이트에 실패해서 이전 버전으로 되돌렸어요. 'malkkeum logs' 로 원인을 확인해 주세요."
  fi
  die "이전 버전으로도 응답하지 않아요. 'malkkeum logs' 화면을 개발자에게 전달해 주세요."
}

cmd_rollback() {
  local prev_api prev_web cur_api cur_web
  prev_api=$(env_get PREV_API_IMAGE); prev_web=$(env_get PREV_WEB_IMAGE)
  if [ -z "$prev_api" ] || [ "$prev_api" = "$(env_get API_IMAGE)" ]; then
    die "되돌릴 이전 버전 기록이 없어요. 업데이트를 한 번 한 뒤에 쓸 수 있어요."
  fi
  cmd_backup || die "백업에 실패해서 되돌리기를 멈췄어요."
  cur_api=$(digest_ref "$(env_get API_IMAGE)"); cur_web=$(digest_ref "$(env_get WEB_IMAGE)")
  env_set PREV_API_IMAGE "$cur_api"; env_set PREV_WEB_IMAGE "$cur_web"
  set_images "$prev_api" "${prev_web:-$(env_get WEB_IMAGE)}"
  if wait_healthy; then ok "이전 버전으로 되돌렸어요"; else die "되돌린 뒤에도 응답이 없어요. 'malkkeum logs' 를 확인하세요."; fi
}

cmd_channel() {
  local ch="${1:-}"
  case "$ch" in
    stable|beta) ;;
    *) die "사용법: malkkeum channel stable | beta" ;;
  esac
  env_set CHANNEL "$ch"; env_set VERSION "$ch"
  printf '\n▶ %s 채널로 바꾸고 업데이트합니다\n' "$ch"
  cmd_update
}

cmd_version() {
  local cid running=""
  cid=$(dc ps -q api 2>/dev/null | head -n1 || true)
  [ -n "$cid" ] && running=$(docker inspect -f '{{ index .Config.Labels "org.opencontainers.image.version" }}' "$cid" 2>/dev/null || true)
  if [ -z "$running" ] || [ "$running" = "<no value>" ]; then
    running=$(curl -fsSk --max-time 5 --resolve "$(env_get DOMAIN):443:127.0.0.1" "https://$(env_get DOMAIN)/health" 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || true)
  fi
  echo "채널: $(env_get CHANNEL)  (이미지 태그: $(env_get VERSION))"
  echo "실행 중인 버전: ${running:-알 수 없음}"
}

cmd_status() {
  dc ps
  if health_ok; then ok "서비스 정상"; else warn "서비스 응답 없음 — 'malkkeum logs' 로 확인하세요"; fi
  if [ -n "$(env_get HEARTBEAT_URL)" ]; then ok "외부 가동 확인(heartbeat) 설정됨"; else warn "외부 가동 확인이 없어요 — .env 에 HEARTBEAT_URL 을 넣으세요 (docs/OPERATIONS.md)"; fi
}

cmd_restore() {
  local f="${1:?복원할 백업 파일을 지정하세요. 예: malkkeum restore backups/db-20261110-033000.sql.gz}"
  local a=""
  read -r -p "현재 데이터를 $f 로 되돌릴까요? (yes 입력) " a </dev/tty || true
  [ "$a" = yes ] || die "취소했어요."
  gunzip -c "$f" | dc exec -T db psql -q -U app -d cleaning >/dev/null && ok "복원 완료"
}

case "${1:-status}" in
  status) cmd_status ;;
  update) shift; cmd_update "$@" ;;
  load) shift; cmd_load "$@" ;;
  rollback) cmd_rollback ;;
  channel) shift; cmd_channel "$@" ;;
  version) cmd_version ;;
  backup) cmd_backup ;;
  restore) shift; cmd_restore "$@" ;;
  restore-offsite)
    name="${2:-}"
    if [ -z "$name" ]; then dc run --rm --no-deps -T -v "$DIR/backups:/backups" api api backup-list; exit 0; fi
    dc run --rm --no-deps -T -v "$DIR/backups:/backups" api api backup-fetch "$name" "/backups/${name%.enc}" || die "외부 백업을 내려받지 못했어요"
    cmd_restore "backups/${name%.enc}" ;;
  demo)
    case "${2:-}" in
      load)
        echo "체험용 데이터를 넣을게요. 실제 예약이 이미 있으면 넣지 않아요. (강제로 넣으려면: malkkeum demo load --force)"
        dc exec -T api api demo load ${3:+"$3"} && ok "체험용 데이터를 넣었어요. 지우려면: malkkeum demo clear" ;;
      clear)
        a=""; read -r -p "체험용 데이터를 모두 지울까요? 실제 고객·예약 데이터는 지우지 않아요. (yes 입력) " a </dev/tty || true
        [ "$a" = yes ] || die "취소했어요."
        dc exec -T api api demo clear && ok "체험용 데이터를 지웠어요" ;;
      *) die "사용법: malkkeum demo [load [--force] | clear]" ;;
    esac ;;
  logs) dc logs --tail 200 -f "${2:-api}" ;;
  setup-code) env_get SETUP_CODE | sed -E 's/(....)(....)(....)/\1-\2-\3/' ;;
  *)
    echo "사용법: malkkeum [status|update [태그]|load 파일.tar|rollback|channel stable|beta|version|backup|restore 파일|restore-offsite [이름]|demo load|demo clear|logs|setup-code]"
    exit 1 ;;
esac
CLI
sed -i "s|__DIR__|$DIR|" /usr/local/bin/malkkeum
chmod 755 /usr/local/bin/malkkeum
ok "관리 명령 malkkeum 을 설치했어요"

# 매일 03:30 백업, 매주 월요일 04:00 자동 업데이트 (업데이트 전에도 백업하고, 실패하면 자동으로 되돌려요).
timedatectl set-timezone Asia/Seoul 2>/dev/null || true
cat > /etc/cron.d/malkkeum <<EOF
30 3 * * * root /usr/local/bin/malkkeum backup >> $DIR/backups/backup.log 2>&1
0 4 * * 1 root /usr/local/bin/malkkeum update >> $DIR/backups/update.log 2>&1
*/5 * * * * root /usr/local/bin/malkkeum-heartbeat >> $DIR/backups/heartbeat.log 2>&1
EOF
ok "매일 새벽 3시 30분 자동 백업, 매주 월요일 자동 업데이트를 예약했어요"
# 5분마다 /health 가 정상일 때만 HEARTBEAT_URL 로 핑을 보내요. 핑이 끊기면 외부 서비스가 알려줘요.
cat > /usr/local/bin/malkkeum-heartbeat <<'HB'
#!/usr/bin/env bash
# 말끔 외부 가동 확인 핑 (healthchecks.io 등). HEARTBEAT_URL 이 없으면 로그만 남기고 끝나요.
DIR=__DIR__
URL=$(grep -E '^HEARTBEAT_URL=' "$DIR/.env" 2>/dev/null | tail -n1 | cut -d= -f2-)
DOMAIN=$(grep -E '^DOMAIN=' "$DIR/.env" 2>/dev/null | tail -n1 | cut -d= -f2-)
if [ -z "$URL" ]; then echo "$(date -Is) HEARTBEAT_URL 없음 - 외부 가동 확인이 꺼져 있어요" >&2; exit 0; fi
if curl -fsSk --max-time 10 --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN/health" 2>/dev/null | grep -q '"ok":true'; then
  curl -fsS --max-time 10 -o /dev/null "$URL" || echo "$(date -Is) 핑 전송 실패" >&2
fi
HB
sed -i "s|__DIR__|$DIR|" /usr/local/bin/malkkeum-heartbeat
chmod 755 /usr/local/bin/malkkeum-heartbeat

if command -v ufw >/dev/null && ufw status | grep -q active; then
  ufw allow 22/tcp >/dev/null; ufw allow 80/tcp >/dev/null; ufw allow 443 >/dev/null
fi

if [ -n "$IMAGES_TAR" ]; then
  say "미리 받아 둔 이미지를 불러와요 (인터넷에서 받지 않아요)"
  load_images "$IMAGES_TAR" "$IMAGE_REPO/malkkeum-api:$VERSION" "$IMAGE_REPO/malkkeum-web:$VERSION"
  ok "이미지를 불러왔어요: $IMAGES_TAR"
fi

say "서비스 시작 (처음에는 몇 분 걸릴 수 있어요)"
[ "$IMAGE_SOURCE" = local ] || dc pull -q api web
dc up -d --remove-orphans

wait_healthy || warn "서비스가 아직 응답하지 않아요. 'malkkeum logs' 로 확인하세요."

CODE=$(/usr/local/bin/malkkeum setup-code)
CH=$(grep '^CHANNEL=' .env | cut -d= -f2-)
cat <<EOF

────────────────────────────────────────────────────────────
  ✔ 설치가 끝났어요!   (채널: $CH)

  1) 브라우저에서 이 주소를 여세요:   https://$DOMAIN/admin/
  2) 설치 코드를 입력하고 사장님 계정을 만드세요:

         설치 코드:  $CODE

  3) [설정] 메뉴에서 결제·문자·로그인 연동을 차례로 연결하세요.

  ⚠ $DIR/.env 파일을 USB 나 안전한 곳에 꼭 복사해 두세요.
    (이 파일이 없으면 백업을 복원할 수 없어요)

  관리 명령:  malkkeum status | update | rollback | channel | version | backup | logs
────────────────────────────────────────────────────────────
EOF
