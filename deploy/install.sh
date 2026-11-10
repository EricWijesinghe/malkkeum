#!/usr/bin/env bash
# 말끔 서버 설치 프로그램 (Ubuntu 22.04 / 24.04, Debian 12)
#
#   curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/main/deploy/install.sh | sudo bash
#
# Asks two questions (domain, email), then installs Docker, generates every secret, starts the
# service with automatic HTTPS, schedules daily backups and installs the `malkkeum` command.
# Re-running it is safe: existing settings and data are kept and the service is updated.
set -euo pipefail

IMAGE_REPO="${MALKKEUM_IMAGES:-ghcr.io/malkkeum}"
VERSION="${MALKKEUM_VERSION:-latest}"
DIR=/opt/malkkeum
BACKUP_KEEP_DAYS=14
HEALTH_WAIT_SECS=300

say()  { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m✘ %s\033[0m\n' "$*" >&2; exit 1; }

ask() { # ask "질문" default -> answer (reads from the terminal even when piped from curl)
  local q="$1" def="${2:-}" a
  if [ -n "$def" ]; then printf '%s [%s]: ' "$q" "$def" >/dev/tty; else printf '%s: ' "$q" >/dev/tty; fi
  IFS= read -r a </dev/tty || true
  printf '%s' "${a:-$def}"
}

rand_hex() { openssl rand -hex "$1"; }
setup_code() { # 12 characters without 0/O/1/I/L, shown as XXXX-XXXX-XXXX
  local alphabet=23456789ABCDEFGHJKMNPQRSTUVWXYZ code=""
  while [ ${#code} -lt 12 ]; do
    local b; b=$(od -An -N1 -tu1 /dev/urandom | tr -d ' ')
    [ "$b" -lt 248 ] && code="$code${alphabet:$((b % 31)):1}"
  done
  printf '%s' "$code"
}

[ "$(id -u)" -eq 0 ] || die "관리자 권한이 필요해요. 명령 앞에 sudo 를 붙여 다시 실행해 주세요."
command -v apt-get >/dev/null || die "Ubuntu 또는 Debian 서버에서 실행해 주세요."

say "말끔 서버 설치를 시작합니다"
mkdir -p "$DIR/backups"
cd "$DIR"

if [ -f .env ]; then
  ok "기존 설치를 찾았어요. 설정과 데이터는 그대로 두고 최신 버전으로 업데이트합니다."
  # shellcheck disable=SC1091
  set -a; . ./.env; set +a
else
  DOMAIN=$(ask "서비스 주소(도메인)를 입력하세요. 예: malkkeum.co.kr" "")
  DOMAIN=${DOMAIN#http://}; DOMAIN=${DOMAIN#https://}; DOMAIN=${DOMAIN%%/*}
  [ -n "$DOMAIN" ] || die "도메인이 필요해요."
  ACME_EMAIL=$(ask "보안 인증서 안내를 받을 이메일" "")
fi

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
SERVER_IP=$(curl -fsS4 https://api.ipify.org || true)
DOMAIN_IP=$(dig +short A "$DOMAIN" | tail -n1 || true)
if [ -n "$SERVER_IP" ] && [ "$SERVER_IP" = "$DOMAIN_IP" ]; then
  ok "$DOMAIN → $SERVER_IP (이 서버)"
else
  warn "$DOMAIN 의 A 레코드가 이 서버($SERVER_IP)를 가리키지 않아요 (현재: ${DOMAIN_IP:-없음})."
  warn "도메인 관리 화면에서 A 레코드를 $SERVER_IP 로 설정하세요. 설정 후 몇 분 안에 HTTPS 가 자동으로 켜집니다."
fi

if [ ! -f .env ]; then
  SETUP_CODE=$(setup_code)
  umask 077
  cat > .env <<EOF
# 말끔 서버 설정 — install.sh 가 만들었어요. 이 파일을 안전한 곳에 따로 보관하세요.
# DATA_KEY 를 잃어버리면 저장된 결제·연동 키와 계좌 정보를 복구할 수 없어요.
DOMAIN=$DOMAIN
ACME_EMAIL=$ACME_EMAIL
IMAGE_REPO=$IMAGE_REPO
VERSION=$VERSION
DB_PASSWORD=$(rand_hex 24)
JWT_SECRET=$(rand_hex 32)
DATA_KEY=$(rand_hex 32)
SETUP_CODE=$SETUP_CODE
EOF
  umask 022
  ok "보안 키를 새로 만들었어요"
fi

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
    image: ${IMAGE_REPO}/malkkeum-api:${VERSION}
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
    volumes: [uploads:/data/uploads]
    healthcheck: { test: ["CMD", "api", "--health"], interval: 15s, retries: 10, start_period: 20s }
  web:
    image: ${IMAGE_REPO}/malkkeum-web:${VERSION}
    restart: unless-stopped
    depends_on: [api]
    ports: ["80:80", "443:443", "443:443/udp"]
    environment: { DOMAIN: "${DOMAIN}", ACME_EMAIL: "${ACME_EMAIL}" }
    volumes: [caddydata:/data, caddyconfig:/config]
volumes: { dbdata: {}, uploads: {}, caddydata: {}, caddyconfig: {} }
EOF

cat > /usr/local/bin/malkkeum <<EOF
#!/usr/bin/env bash
# 말끔 관리 명령. 사용법: malkkeum [status|update|backup|restore 파일|restore-offsite [이름]|logs|setup-code|demo load|demo clear|version]
set -euo pipefail
cd $DIR
dc() { docker compose --env-file .env "\$@"; }
case "\${1:-status}" in
  status)
    dc ps
    if curl -fsS "https://\$(grep ^DOMAIN= .env | cut -d= -f2)/health" >/dev/null; then echo "✔ 서비스 정상"; else echo "✘ 서비스 응답 없음 — 'malkkeum logs' 로 확인하세요"; fi ;;
  update)
    "\$0" backup
    dc pull -q && dc up -d --remove-orphans && docker image prune -f >/dev/null
    echo "✔ 최신 버전으로 업데이트했어요" ;;
  backup)
    ts=\$(date +%Y%m%d-%H%M)
    dc exec -T db pg_dump -U app -d cleaning --clean --if-exists | gzip > backups/db-\$ts.sql.gz
    dc run --rm --no-deps -T --entrypoint tar api czf - -C /data uploads > backups/uploads-\$ts.tar.gz 2>/dev/null || true
    find backups -type f -mtime +$BACKUP_KEEP_DAYS -delete
    # Offsite copy (console: 설정 > 외부 백업). Local backup stays good if this fails.
    dc run --rm --no-deps -T -v "$DIR/backups:/backups" api api backup-upload "/backups/uploads-\$ts.tar.gz" >> backups/backup.log 2>&1 || true
    dc run --rm --no-deps -T -v "$DIR/backups:/backups" api api backup-upload "/backups/db-\$ts.sql.gz" >> backups/backup.log 2>&1 || echo "⚠ 외부 백업 실패 또는 미설정 — 'malkkeum logs' 나 설정 > 외부 백업을 확인하세요"
    echo "✔ 백업 완료: $DIR/backups/db-\$ts.sql.gz" ;;
  restore)
    f="\${2:?복원할 백업 파일을 지정하세요. 예: malkkeum restore backups/db-20261110-0330.sql.gz}"
    read -r -p "현재 데이터를 \$f 로 되돌릴까요? (yes 입력) " a </dev/tty; [ "\$a" = yes ] || exit 1
    gunzip -c "\$f" | dc exec -T db psql -q -U app -d cleaning >/dev/null && echo "✔ 복원 완료" ;;
  restore-offsite)
    name="\${2:-}"
    if [ -z "\$name" ]; then dc run --rm --no-deps -T -v "$DIR/backups:/backups" api api backup-list; exit 0; fi
    dc run --rm --no-deps -T -v "$DIR/backups:/backups" api api backup-fetch "\$name" "/backups/\${name%.enc}" || { echo "✘ 외부 백업을 내려받지 못했어요"; exit 1; }
    "\$0" restore "backups/\${name%.enc}" ;;
  logs) dc logs --tail 200 -f "\${2:-api}" ;;
  setup-code) grep ^SETUP_CODE= .env | cut -d= -f2 | sed -E 's/(....)(....)(....)/\1-\2-\3/' ;;
  demo)
    case "\${2:-}" in
      load)
        echo "체험용 데이터를 넣을게요. 실제 예약이 이미 있으면 넣지 않아요. (강제로 넣으려면: malkkeum demo load --force)"
        dc exec -T api api demo load "\${3:-}" && echo "✔ 체험용 데이터를 넣었어요. 지우려면: malkkeum demo clear" ;;
      clear)
        read -r -p "체험용 데이터를 모두 지울까요? 실제 고객·예약 데이터는 지우지 않아요. (yes 입력) " a </dev/tty; [ "\$a" = yes ] || { echo "취소했어요."; exit 1; }
        dc exec -T api api demo clear && echo "✔ 체험용 데이터를 지웠어요" ;;
      *) echo "사용법: malkkeum demo [load [--force] | clear]"; exit 1 ;;
    esac ;;
  version) grep ^VERSION= .env | cut -d= -f2 ;;
  *) echo "사용법: malkkeum [status|update|backup|restore 파일|restore-offsite [이름]|logs|setup-code|demo load|demo clear|version]"; exit 1 ;;
esac
EOF
chmod 755 /usr/local/bin/malkkeum

# Daily backup at 03:30, weekly automatic update (after a backup) on Monday 04:00.
timedatectl set-timezone Asia/Seoul 2>/dev/null || true
cat > /etc/cron.d/malkkeum <<EOF
30 3 * * * root /usr/local/bin/malkkeum backup >> $DIR/backups/backup.log 2>&1
0 4 * * 1 root /usr/local/bin/malkkeum update >> $DIR/backups/update.log 2>&1
EOF
ok "매일 새벽 3시 30분 자동 백업, 매주 월요일 자동 업데이트를 예약했어요"

if command -v ufw >/dev/null && ufw status | grep -q active; then
  ufw allow 22/tcp >/dev/null; ufw allow 80/tcp >/dev/null; ufw allow 443 >/dev/null
fi

say "서비스 시작 (처음에는 몇 분 걸릴 수 있어요)"
docker compose --env-file .env pull -q
docker compose --env-file .env up -d --remove-orphans

waited=0
until curl -fsS "https://$DOMAIN/health" >/dev/null 2>&1 || curl -fsS -H "Host: $DOMAIN" http://127.0.0.1/health >/dev/null 2>&1; do
  sleep 5; waited=$((waited + 5))
  [ $waited -ge $HEALTH_WAIT_SECS ] && { warn "서비스가 아직 응답하지 않아요. 'malkkeum logs' 로 확인하세요."; break; }
done

CODE=$(/usr/local/bin/malkkeum setup-code)
cat <<EOF

────────────────────────────────────────────────────────────
  ✔ 설치가 끝났어요!

  1) 브라우저에서 이 주소를 여세요:   https://$DOMAIN/admin/
  2) 설치 코드를 입력하고 사장님 계정을 만드세요:

         설치 코드:  $CODE

  3) [설정] 메뉴에서 결제·문자·로그인 연동을 차례로 연결하세요.

  ⚠ $DIR/.env 파일을 USB 나 안전한 곳에 꼭 복사해 두세요.
    (이 파일이 없으면 백업을 복원할 수 없어요)

  관리 명령:  malkkeum status | update | backup | logs
────────────────────────────────────────────────────────────
EOF
