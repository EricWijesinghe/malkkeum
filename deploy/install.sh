#!/usr/bin/env bash
# 다해 서버 설치 프로그램 (Ubuntu 22.04 / 24.04, Debian 12)
#
#   curl -fsSL https://raw.githubusercontent.com/EricWijesinghe/malkkeum-install/v1.2.3/install.sh | sudo bash
#   (버전 태그 v… 는 바뀌지 않고, 같은 태그에 지문 파일 SHA256SUMS 가 있어요. 채널 최신: .../main/install.sh, 베타 .../beta/install.sh)
#
# 질문 두 개(도메인, 이메일)에 답하면 서버 점검, Docker 설치, 보안 키 생성, HTTPS 자동 설정, 매일 백업,
# `dahae` 관리 명령 설치까지 끝냅니다. 다시 실행하면 안전하게 업데이트해요: 먼저 백업하고, 새 버전이
# 응답하지 않으면 이전 버전으로 되돌립니다. 설정과 데이터는 그대로 둡니다.
#
# 자동 설치·테스트용 환경 변수 (보통은 필요 없어요). MALKKEUM_* 대신 DAHAE_* 로 써도 돼요:
#   MALKKEUM_DOMAIN, MALKKEUM_EMAIL   질문 대신 값 지정
#   MALKKEUM_IMAGES                   이미지 저장소 (기본: 릴리스 저장소)
#   MALKKEUM_IMAGES_TAR=<파일.tar>    인터넷 없이 미리 받아 둔 이미지 묶음 설치 (체험·오프라인용, 버전 기본: local)
#   MALKKEUM_CHANNEL                  stable | beta
#   MALKKEUM_VERSION                  채널 대신 쓸 이미지 태그 (테스트용)
#   MALKKEUM_TLS=internal             공인 인증서 대신 내부 인증 기관 사용 (테스트용)
#   MALKKEUM_SKIP_DNS_CHECK=1         도메인 IP 확인 생략
#   MALKKEUM_HEALTH_WAIT=300          기동 확인 대기 시간(초)
#   MALKKEUM_HEARTBEAT_URL=<핑 주소>    외부 가동 확인(healthchecks.io 등). 나중에 `dahae heartbeat <주소>` 로도 돼요
#   MALKKEUM_SIGNER=<owner/repo>      이미지 서명자 GitHub 저장소 (기본: 릴리스 저장소)
#   MALKKEUM_SKIP_SIGNATURE=1         이미지 서명 확인 끄기 (서명 없는 테스트 저장소 전용. 다시 실행하면 다시 켜져요)
set -euo pipefail

IMAGE_REPO_DEFAULT=ghcr.io/ericwijesinghe
DEFAULT_CHANNEL=stable
DIR=/opt/malkkeum
BIN=/usr/local/bin
KB_PER_GB=1048576
MIN_RAM_KB=900000             # 1 GB 서버(실제 약 0.95 GB)까지 허용
SWAP_BELOW_KB=$((2 * KB_PER_GB)) # 이보다 작고 스왑이 없으면 2 GB 스왑 파일을 만들어요
DISK_FRESH_KB=$((5 * KB_PER_GB))
DISK_UPGRADE_KB=$((2 * KB_PER_GB))
COMPOSE_MIN=2.20
APT_LOCK_WAIT=600
DNS_MAX_TRIES=30
HB_URL_RE='^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[A-Za-z0-9._~%/:@+=?-]*)?$'
# 서버 이미지는 이 저장소의 .github/workflows/release.yml 이 v 태그에서 cosign(키 없는 서명)으로 서명해요.
SIGNER_REPO_DEFAULT=EricWijesinghe/malkkeum
# 서명 확인 도구. 버전을 고정하고, 받은 파일의 SHA-256 이 아래와 같을 때만 써요 (cosign_checksums.txt 기준).
COSIGN_VERSION=v3.1.4
COSIGN_SHA256_AMD64=424e2c97d0b45fd7a6b608a87f090f35633f4c23ece5f092d48bba11aaf4bbfa
COSIGN_SHA256_ARM64=ade83b7aac62e131cacfe96d958948b2150cc9efec46a570a2649b8e27dedad2

say()  { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m✘ %s\033[0m\n' "$*" >&2; exit 1; }
dc()   { docker compose --env-file .env "$@"; }
has_tty() { (: </dev/tty) 2>/dev/null; }
env_get() { { grep -E "^$1=" .env 2>/dev/null || true; } | tail -n1 | cut -d= -f2-; }

ask() { # ask "질문" 기본값 -> 답 (터미널이 없으면 기본값)
  local q="$1" def="${2:-}" a=""
  if has_tty; then
    printf '%s%s: ' "$q" "${def:+ [$def]}" >/dev/tty
    IFS= read -r a </dev/tty || true
  fi
  printf '%s' "${a:-$def}"
}

ask_until() { # ask_until 검사함수 "질문" "잘못됐을 때 안내" -> 답. 터미널이 있으면 3번까지 다시 물어요
  local check="$1" q="$2" bad="$3" a i
  for i in 1 2 3; do
    a=$(ask "$q" "")
    if "$check" "$a"; then printf '%s' "$a"; return 0; fi
    if [ -z "$a" ]; then warn "입력이 비어 있어요" >&2; else warn "$bad" >&2; fi
    has_tty || break
    [ "$i" -lt 3 ] && warn "다시 입력해 주세요 ($i/3)" >&2
  done
  return 1
}

# ---- 순수 함수 (scripts/ci/installer-selftest.sh 가 검사해요) ----
norm_domain() { local d="$1"; d=${d#http://}; d=${d#https://}; d=${d%%/*}; printf '%s' "$d" | tr '[:upper:]' '[:lower:]'; }
# .env 는 compose 와 관리 명령이 읽어요: 평범한 호스트 이름과 이메일만 들어가요.
valid_domain() {
  local d; d=$(norm_domain "$1")
  [ -n "$d" ] && printf '%s' "$d" | grep -Eq '^[a-z0-9]([a-z0-9.-]{0,251}[a-z0-9])?$' && case "$d" in *.*) ;; *) return 1 ;; esac
}
valid_email() { [ -z "$1" ] || printf '%s' "$1" | grep -Eq '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'; }
valid_hb_url() { printf '%s' "$1" | grep -Eq "$HB_URL_RE"; }
ver_ge() { [ "$(printf '%s\n%s\n' "${2#v}" "${1#v}" | sort -V | head -n1)" = "${2#v}" ]; } # ver_ge 2.29.1 2.20
mem_kb() { awk -v k="$1:" '$1 == k { print $2; f=1 } END { if (!f) print 0 }' "${2:-/proc/meminfo}"; }
disk_free_kb() { df -Pk "$1" | awk 'NR == 2 { print $4 }'; }
arch_ok() { case "$1" in x86_64|amd64|aarch64|arm64) return 0 ;; *) return 1 ;; esac; }
port_holders() { # `ss -ltnpH` 출력(표준 입력)에서 Docker 가 아닌 프로그램 이름만 뽑아요
  awk '{
    if (match($0, /users:\(\(.*\)\)/)) {
      s = substr($0, RSTART, RLENGTH)
      while (match(s, /"[^"]+"/)) {
        n = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH)
        if (n !~ /^(docker-proxy|dockerd|containerd.*)$/) print n
      }
    } else if (NF) print "?"
  }' | sort -u
}
ip_in_list() { [ -n "$1" ] && printf '%s\n' "$2" | grep -Fxq "$1"; }
only_ipv4() { grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' || true; }
only_ipv6() { grep -E '^[0-9A-Fa-f:]+$' | grep ':' || true; }
sha256_is() { [ "$(sha256sum "$1" | cut -d' ' -f1)" = "$2" ]; } # sha256_is 파일 지문
cosign_sha256() { case "$1" in x86_64|amd64) echo "$COSIGN_SHA256_AMD64" ;; aarch64|arm64) echo "$COSIGN_SHA256_ARM64" ;; *) return 1 ;; esac; }
lock_env() { chmod 600 .env; } # .env 에는 모든 비밀 키가 있어요: 실행할 때마다 root 만 읽게 맞춰요

rand_hex() { openssl rand -hex "$1"; }
setup_code() { # 0/O/1/I/L 을 뺀 12자리. 화면을 보고 손으로 입력하는 코드예요.
  local alphabet=23456789ABCDEFGHJKMNPQRSTUVWXYZ code=""
  while [ ${#code} -lt 12 ]; do
    local b; b=$(od -An -N1 -tu1 /dev/urandom | tr -d ' ')
    [ "$b" -lt 248 ] && code="$code${alphabet:$((b % 31)):1}"
  done
  printf '%s' "$code"
}

env_set() { # env_set 키 값 : .env 에 키가 있으면 바꾸고, 없으면 추가해요 (inode 와 권한은 그대로)
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

apt_retry() { # 새 서버는 자동 업데이트가 apt 를 잠그고 있어요: 잠금이 풀릴 때까지 기다리고, 두 번 더 시도해요
  local i
  for i in 1 2 3; do
    DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout="$APT_LOCK_WAIT" "$@" && return 0
    [ "$i" -lt 3 ] && { warn "패키지 설치가 잠시 막혔어요. 30초 뒤 다시 시도해요 ($i/3)"; sleep 30; }
  done
  return 1
}

install_cosign() { # 서명 확인 도구를 $DIR/bin/cosign 에 둬요. 지문(SHA-256)이 다르면 설치를 멈춰요
  local arch sum tmp dest="$DIR/bin/cosign"
  arch=$(uname -m)
  sum=$(cosign_sha256 "$arch") || die "이 서버($arch)용 서명 확인 도구가 없어요."
  if [ -x "$dest" ] && sha256_is "$dest" "$sum"; then return 0; fi
  case "$arch" in x86_64|amd64) arch=amd64 ;; *) arch=arm64 ;; esac
  mkdir -p "$DIR/bin"; tmp=$(mktemp "$DIR/bin/.cosign.XXXXXX")
  if ! curl -fsSL --retry 3 --max-time 180 -o "$tmp" "https://github.com/sigstore/cosign/releases/download/$COSIGN_VERSION/cosign-linux-$arch"; then
    rm -f "$tmp"; die "이미지 서명 확인 도구(cosign)를 내려받지 못했어요. 인터넷 연결을 확인하고 다시 실행하세요."
  fi
  if ! sha256_is "$tmp" "$sum"; then
    rm -f "$tmp"; die "내려받은 서명 확인 도구(cosign)의 지문이 예상과 달라요. 안전을 위해 멈췄어요. 잠시 뒤 다시 실행하고, 계속되면 개발자에게 알려 주세요."
  fi
  chmod 755 "$tmp"; mv -f "$tmp" "$dest"
}

# ---- 서버 점검 ----
preflight() {
  local arch mem swap need p free busy
  arch=$(uname -m)
  arch_ok "$arch" || die "이 서버($arch)는 지원하지 않아요. x86_64(amd64) 또는 arm64 서버가 필요해요."
  mem=$(mem_kb MemTotal); swap=$(mem_kb SwapTotal)
  [ "$mem" -ge "$MIN_RAM_KB" ] || die "메모리가 $((mem / 1024)) MB 예요. 최소 1 GB, 권장 2 GB 이상인 서버가 필요해요."
  need=$DISK_FRESH_KB; [ -f "$DIR/.env" ] && need=$DISK_UPGRADE_KB
  for p in /var/lib /opt; do
    [ -d "$p" ] || continue
    free=$(disk_free_kb "$p")
    [ "$free" -ge "$need" ] || die "$p 의 남은 디스크가 $((free / 1024)) MB 예요. 최소 $((need / KB_PER_GB)) GB 가 필요해요. 필요 없는 파일을 지우거나 디스크를 늘려 주세요."
  done
  if [ "$mem" -lt "$SWAP_BELOW_KB" ] && [ "$swap" -eq 0 ]; then make_swap; fi
  if command -v ss >/dev/null; then
    busy=$(ss -ltnpH '( sport = :80 or sport = :443 )' 2>/dev/null | port_holders | tr '\n' ' ' || true)
    [ -z "$busy" ] || die "80/443 포트를 다른 프로그램(${busy% })이 쓰고 있어요. 그 프로그램을 끄고 다시 실행하세요. 예: sudo systemctl disable --now nginx apache2"
  else
    warn "ss 명령이 없어 80/443 포트 확인은 건너뛰었어요"
  fi
  ok "서버 점검 통과 ($arch, 메모리 $((mem / 1024)) MB)"
}

make_swap() {
  local free; free=$(disk_free_kb /)
  if [ -e /swapfile ] || [ "$free" -lt $((DISK_FRESH_KB + 2 * KB_PER_GB)) ]; then
    warn "메모리가 2 GB 보다 작은데 스왑이 없어요. 디스크가 부족하거나 /swapfile 이 이미 있어서 만들지 않았어요."
    return 0
  fi
  say "메모리가 2 GB 보다 작아서 2 GB 스왑 파일을 만들어요"
  if (umask 077; fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none) \
      && mkswap /swapfile >/dev/null && swapon /swapfile; then
    grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
    ok "스왑 2 GB 를 켰어요 (재부팅 후에도 유지)"
  else
    rm -f /swapfile
    warn "스왑을 만들지 못했어요 (서버 종류에 따라 막혀 있어요). 그대로 진행하지만 느릴 수 있어요."
  fi
}

public_ip() {
  local ip u
  for u in https://api.ipify.org https://ifconfig.me; do
    ip=$(curl -fsS4 --max-time 5 "$u" 2>/dev/null | only_ipv4 || true)
    [ -n "$ip" ] && { printf '%s' "$ip"; return 0; }
  done
  return 0
}

dns_check() { # DNS_OK=1 이면 도메인이 이 서버를 가리켜요
  DNS_OK=1
  if [ "$TLS_MODE" = internal ] || [ -n "${MALKKEUM_SKIP_DNS_CHECK:-}" ]; then
    ok "도메인 IP 확인은 건너뛰었어요 (테스트 설치)"; return 0
  fi
  local server a4 a6 bad6 v i
  server=$(public_ip)
  if [ -z "$server" ]; then warn "이 서버의 공인 IP 를 알 수 없어 도메인 확인을 건너뛰어요."; return 0; fi
  for i in $(seq "$DNS_MAX_TRIES"); do
    a4=$(dig +short A "$DOMAIN" 2>/dev/null | only_ipv4 || true)
    a6=$(dig +short AAAA "$DOMAIN" 2>/dev/null | only_ipv6 || true); bad6=""
    for v in $a6; do ip -6 addr show scope global 2>/dev/null | grep -qiF "$v" || bad6="$bad6 $v"; done
    if ip_in_list "$server" "$a4" && [ -z "$bad6" ]; then ok "$DOMAIN → $server (이 서버)"; return 0; fi
    warn "$DOMAIN 이 아직 이 서버를 가리키지 않아요 (현재 A: ${a4:-없음})."
    printf '   도메인 관리 화면에서 이렇게 설정하세요:  A 레코드   %s   →   %s\n' "$DOMAIN" "$server"
    [ -z "$bad6" ] || printf '   AAAA(IPv6) 레코드%s 는 이 서버가 아니에요. 지우거나 이 서버 주소로 바꾸세요.\n' "$bad6"
    if ! has_tty; then break; fi
    [ "$(ask "설정한 뒤 Enter 를 누르면 다시 확인해요. 반영까지 몇 분 걸릴 수 있어요 (건너뛰려면 s, $i/$DNS_MAX_TRIES)" "")" = s ] && break
  done
  DNS_OK=0
  warn "도메인 연결 전이라도 설치는 계속해요. DNS 가 연결되면 HTTPS 인증서가 자동으로 발급돼요."
}

# ---- 서버가 가진 파일들 ----
write_compose() {
  cat > docker-compose.yml <<'EOF'
# Managed by install.sh — re-run the installer or `dahae update` instead of editing.
# Same as deploy/docker-compose.yml in the source repo except the image lines (installer-selftest checks).
x-logging: &log { driver: json-file, options: { max-size: 10m, max-file: "3" } }
# Every container: no privilege gain through setuid binaries or file capabilities, no Linux capability
# unless listed under cap_add, a read-only root filesystem (writes go to volumes and tmpfs only), and
# memory and process caps sized for a 2 GB VPS. No CPU caps: `cpus` above the host's core count stops
# `docker compose up` on a 1-vCPU server.
x-hardened: &hardened
  restart: unless-stopped
  logging: *log
  security_opt: ["no-new-privileges:true"]
  cap_drop: [ALL]
  read_only: true
services:
  db:
    <<: *hardened
    image: postgres:17
    # The entrypoint starts as root, fixes ownership of the data and socket dirs, then drops to postgres.
    cap_add: [CHOWN, DAC_OVERRIDE, FOWNER, SETGID, SETUID]
    tmpfs: [/tmp, /var/run/postgresql]
    mem_limit: 768m
    pids_limit: 200
    stop_grace_period: 60s # a clean shutdown instead of crash recovery on the next start
    environment:
      POSTGRES_DB: cleaning
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD:?set DB_PASSWORD}
    # Sized for a 2 GB VPS (API pool 10 + headroom). Autovacuum is tuned for churn; see docs/DEPLOY.md.
    command: >-
      postgres -c shared_buffers=256MB -c effective_cache_size=1GB -c work_mem=8MB -c maintenance_work_mem=128MB -c max_connections=50 -c wal_compression=on -c max_wal_size=1GB -c min_wal_size=256MB -c checkpoint_completion_target=0.9 -c random_page_cost=1.1 -c password_encryption=scram-sha-256 -c autovacuum_max_workers=2 -c autovacuum_naptime=30s -c autovacuum_vacuum_scale_factor=0.05 -c autovacuum_analyze_scale_factor=0.02 -c autovacuum_vacuum_cost_limit=1000 -c log_min_duration_statement=500 -c log_lock_waits=on -c log_temp_files=10MB -c log_checkpoints=on
    shm_size: 256mb
    volumes: [dbdata:/var/lib/postgresql/data]
    healthcheck: { test: ["CMD-SHELL", "pg_isready -U app -d cleaning"], interval: 5s, retries: 20 }

  api:
    <<: *hardened
    image: ${API_IMAGE:?set by install.sh}
    # Runs as uid 10001 (backend/Dockerfile) and needs no capability. Backup commands write their temp
    # files to the backups folder (TMPDIR), so /tmp stays small.
    tmpfs: ["/tmp:size=64m"]
    init: true
    mem_limit: 512m
    pids_limit: 256
    depends_on: { db: { condition: service_healthy } }
    environment:
      # Non-superuser app role (owner of the cleaning DB); `app` stays the admin/backup superuser.
      # `dahae` (install.sh) creates the role and moves ownership before every install, update and restore.
      DATABASE_URL: postgres://dahae_api:${API_DB_PASSWORD:?set API_DB_PASSWORD}@db:5432/cleaning
      DB_MAX_CONNECTIONS: "20"
      JWT_SECRET: ${JWT_SECRET:?set JWT_SECRET}
      DATA_KEY: ${DATA_KEY:?set DATA_KEY}
      HEARTBEAT_URL: ${HEARTBEAT_URL:-}
      SETUP_CODE: ${SETUP_CODE:-}
      PUBLIC_BASE_URL: https://${DOMAIN:?set DOMAIN}
      ALLOWED_ORIGINS: https://${DOMAIN}
      TRUSTED_PROXY: "1"
      DEV_MODE: "0"
      RUST_LOG: info,sqlx=warn
      # App Links for Naver login (/.well-known/*). Set with `dahae applinks`; empty = not served.
      ANDROID_CERT_SHA256: "${ANDROID_CERT_SHA256:-}"
      APPLE_TEAM_ID: "${APPLE_TEAM_ID:-}"
      LOG_FORMAT: json
    volumes: [uploads:/data/uploads]
    healthcheck: { test: ["CMD", "api", "--ready"], interval: 15s, retries: 10, start_period: 20s }

  web:
    <<: *hardened
    image: ${WEB_IMAGE:?set by install.sh}
    # Caddy's image runs it as root; with every other capability dropped it can only bind 80/443.
    # Certificates and config live in the caddydata/caddyconfig volumes.
    cap_add: [NET_BIND_SERVICE]
    tmpfs: [/tmp]
    mem_limit: 256m
    pids_limit: 256
    # Plain start order, not service_healthy: an API that never gets healthy would make `docker compose up`
    # fail before `dahae update` can roll back to the previous version.
    depends_on: [api]
    ports: ["80:80", "443:443", "443:443/udp"]
    environment:
      DOMAIN: ${DOMAIN}
      ACME_EMAIL: ${ACME_EMAIL:-}
      TLS_MODE: ${TLS_MODE:-}
    volumes: [caddydata:/data, caddyconfig:/config]
    healthcheck: { test: ["CMD", "wget", "-q", "-O", "/dev/null", "http://127.0.0.1:2019/config/"], interval: 30s, retries: 5 }

volumes: { dbdata: {}, uploads: {}, caddydata: {}, caddyconfig: {} }
EOF
}

# 관리 명령. 본문은 따옴표 heredoc 이라 그대로 옮겨지고, __DIR__ 만 바꿔 넣어요.
write_cli() { # write_cli 경로
  cat > "$1" <<'CLI'
#!/usr/bin/env bash
# 다해 관리 명령 (malkkeum 도 같은 명령이에요). 사용법: dahae help
set -euo pipefail
DIR=__DIR__
BACKUP_KEEP_DAYS=14
UPDATE_WAIT_SECS=${DAHAE_HEALTH_WAIT:-${MALKKEUM_HEALTH_WAIT:-180}}
HB_URL_RE='^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[A-Za-z0-9._~%/:@+=?-]*)?$'
BIN=/usr/local/bin
API_DB_USER=dahae_api # 앱이 쓰는 DB 계정: 슈퍼유저가 아니에요. app 은 관리·백업용 슈퍼유저예요
SIGN_ISSUER=https://token.actions.githubusercontent.com
BACKUP_NAME_RE='^db-[0-9]{8}-[0-9]{6}\.sql\.gz(\.enc)?$'
USAGE='사용법: dahae <명령>
  status                      서비스 상태
  update [태그]               백업 → 새 버전 → 응답 없으면 자동으로 되돌리기
  rollback                    바로 전 버전으로 되돌리기
  channel stable|beta         업데이트 채널 바꾸기
  version                     지금 버전
  backup                      지금 바로 백업
  restore 파일 [--yes]        백업으로 되돌리기 (DB + 사진 파일)
  restore-offsite [이름] [--yes]  외부 백업 목록 / 내려받아 되돌리기
  load 파일.tar               미리 받아 둔 이미지 불러오기 (인터넷 없이 업데이트)
  heartbeat <https 주소>|off  외부 가동 확인 핑 주소 설정
  applinks --android-sha256 지문[,지문] --apple-team-id 팀ID   앱 링크 설정
  demo load [--force] | demo clear   체험용 데이터
  logs [api|web|db]           로그 보기
  setup-code                  사장님 계정 설치 코드
  uninstall [--yes]           서비스 끄기 (데이터와 백업은 남겨요)
  uninstall --purge [--confirm 도메인]  데이터와 백업까지 삭제 (도메인을 입력해 확인. --yes 로는 넘어가지 않아요)
  keys-backup                 비밀 키 사본을 비밀번호로 잠가 만들기 (서버 밖에 보관: 외부 백업을 풀 때 필요)
  keys-restore 파일 [--yes]   새 서버에 예전 비밀 키 넣기 (restore-offsite 전에)
  alert update|backup         자동 작업 실패를 외부 가동 확인 주소로 알리기 (예약 작업용)'

dc() { docker compose --env-file .env "$@"; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m✘ %s\033[0m\n' "$*" >&2; exit 1; }
has_tty() { (: </dev/tty) 2>/dev/null; }
env_get() { { grep -E "^$1=" .env 2>/dev/null || true; } | tail -n1 | cut -d= -f2-; }
env_set() { # 키 값 : .env 에 기록 (있으면 바꾸고 없으면 추가)
  local k="$1" v="$2" tmp; tmp=$(mktemp)
  if grep -q "^$k=" .env; then
    awk -v k="$k" -v v="$v" 'index($0, k "=") == 1 { print k "=" v; next } { print }' .env > "$tmp"
  else
    { cat .env; printf '%s=%s\n' "$k" "$v"; } > "$tmp"
  fi
  cat "$tmp" > .env; rm -f "$tmp"
}
confirm() { # confirm "질문" 기대값 : 터미널에서 기대값을 입력해야 통과 (--yes 면 묻지 않아요)
  local a=""
  [ "${YES:-0}" = 1 ] && return 0
  has_tty || die "확인할 터미널이 없어요. 스크립트에서는 --yes 를 붙여 주세요."
  printf '%s (%s 입력) ' "$1" "$2" >/dev/tty
  IFS= read -r a </dev/tty || true
  [ "$a" = "$2" ] || die "취소했어요."
}
uploads_for() { local b; b=$(basename "$1"); b=${b#db-}; printf '%s/uploads-%s.tar.gz' "$(dirname "$1")" "${b%.sql.gz}"; }
# api 이미지의 백업 명령(backup-upload, -fetch, -list). backups/ 는 root 전용(700)이라 컨테이너 안에서도 root 로
# 실행해요. 권한(capability)은 모두 빠진 채라 이 폴더와 앱 볼륨에만 닿아요. 임시 파일은 메모리(/tmp) 대신 backups/ 에.
api_backup() { dc run --rm --no-deps -T --user 0 -e TMPDIR=/backups -v "$DIR/backups:/backups" api api "$@"; }
# 비밀 키 사본(.env)을 비밀번호로 잠그고 풀어요. 비밀번호는 표준 입력이 아니라 환경 변수로 넘겨요(표준 입력은 내용).
KEYS_ENC=(-aes-256-cbc -pbkdf2 -iter 600000 -md sha256)
keys_seal() { KEYS_PASS="$1" openssl enc "${KEYS_ENC[@]}" -salt -pass env:KEYS_PASS; }
keys_open() { KEYS_PASS="$1" openssl enc -d "${KEYS_ENC[@]}" -pass env:KEYS_PASS 2>/dev/null; }
# 실패 신호 주소: healthchecks.io 방식으로 핑 주소 끝에 /fail 을 붙여요 (?쿼리 는 뒤에 그대로).
fail_url() { local base="${1%%\?*}"; printf '%s/fail%s' "${base%/}" "${1#"$base"}"; }
valid_fingerprints() { printf '%s' "$1" | grep -Eq '^([0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){31})(,[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){31})*$'; }
valid_team_id() { printf '%s' "$1" | grep -Eq '^[A-Za-z0-9]{10}$'; }
valid_backup_name() { printf '%s' "$1" | grep -Eq "$BACKUP_NAME_RE"; }
valid_signer() { printf '%s' "$1" | grep -Eq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$'; }
# 서명 인증서는 이 저장소의 release.yml 이 v 태그에서 실행됐을 때만 맞아요 (GitHub 이름은 대소문자 구분 없음).
signer_re() { printf '(?i)^https://github\\.com/%s/\\.github/workflows/release\\.yml@refs/tags/v[0-9]' "$(printf '%s' "$1" | sed 's/\./\\./g')"; }

purge_ok() { # purge_ok [입력한 도메인] : 데이터 삭제는 --yes 나 DAHAE_YES 로 넘어가지 않아요. 도메인을 직접 맞혀야 해요
  local d YES=0; d=$(env_get DOMAIN)
  [ -n "$d" ] || die "설정 파일에 도메인이 없어 삭제를 확인할 수 없어요."
  if [ -n "${1:-}" ]; then [ "$1" = "$d" ] || die "도메인이 달라서 취소했어요."; return 0; fi
  confirm "모든 고객·예약 데이터와 백업을 지울까요? 되돌릴 수 없어요. 확인을 위해 도메인을" "$d"
}

# 사진 백업은 uploads/ 아래 평범한 파일과 폴더만 담아야 해요: 절대 경로, .., 링크, 장치 파일이 있으면 거부해요.
# uploads/ 항목이 없으면(빈 tar, 손상) 거부해요: 그대로 바꾸면 사진이 모두 사라져요.
uploads_tar_ok() {
  gzip -t "$1" 2>/dev/null || return 1
  tar tzvf "$1" 2>/dev/null | awk '{ t = substr($1, 1, 1) } t != "-" && t != "d" { bad = 1 } END { exit bad }' || return 1
  tar tzf "$1" 2>/dev/null | awk '$0 == "uploads/" { top = 1; next }
    $0 !~ /^uploads\// || $0 ~ /(^|\/)\.\.(\/|$)/ { bad = 1 } END { exit bad || !top }'
}
# 검사를 통과한 tar 를 옆 폴더에 다 풀고 나서야 기존 사진과 바꿔요. 풀다가 실패하면 기존 사진은 그대로예요.
UPLOADS_SWAP='set -e; cd /data/uploads; rm -rf .restore-new; mkdir .restore-new
tar xzf - -C .restore-new --strip-components=1 --no-same-owner --no-same-permissions || { rm -rf .restore-new; exit 1; }
find . -mindepth 1 -maxdepth 1 ! -name .restore-new -exec rm -rf {} +
find .restore-new -mindepth 1 -maxdepth 1 -exec mv -t . {} +
rmdir .restore-new'

# 예전 백업(소유자 app, 확장 포함)도 앱 계정으로 복원되게 소유자·확장 줄을 빼요. 확장은 db_roles 가 미리 만들어요.
restore_filter() { sed -E '/^ALTER .* OWNER TO [^;]+;$/d; /^(DROP|CREATE) EXTENSION /d; /^COMMENT ON EXTENSION /d'; }
# 복원 SQL 은 앱 계정(슈퍼유저 아님)으로, 볼륨 없는 일회용 컨테이너에서 실행해요: 백업 파일에
# COPY ... PROGRAM 이나 psql 의 \! 같은 명령이 섞여 있어도 서버와 데이터 폴더에 닿지 못해요.
psql_api() {
  local cid net img
  cid=$(dc ps -q db 2>/dev/null | head -n1); [ -n "$cid" ] || return 1
  net=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{println $k}}{{end}}' "$cid" | head -n1)
  img=$(docker inspect -f '{{.Config.Image}}' "$cid")
  PGPASSWORD=$(env_get API_DB_PASSWORD) docker run --rm -i --network "$net" -e PGPASSWORD --user postgres \
    --read-only --cap-drop ALL --security-opt no-new-privileges "$img" psql -X -h db -U "$API_DB_USER" -d cleaning "$@"
}

db_roles_sql() { # db_roles_sql 비밀번호 : 앱 계정을 만들고 앱 DB 와 그 안 객체의 소유권을 넘겨요. 몇 번 실행해도 같아요
  sed -e "s/__ROLE__/$API_DB_USER/g" -e "s/__PW__/$1/" <<'SQL'
SET client_min_messages = warning;
SELECT 'CREATE ROLE __ROLE__' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '__ROLE__')
\gexec
ALTER ROLE __ROLE__ WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD '__PW__';
-- 마이그레이션이 쓰는 확장: 앱 계정은 만들 수 없어서 슈퍼유저가 먼저 만들어 둬요
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
SELECT format('ALTER DATABASE %I OWNER TO __ROLE__', current_database())
\gexec
DO $$
DECLARE r record;
BEGIN
  IF (SELECT pg_get_userbyid(nspowner) FROM pg_namespace WHERE nspname = 'public') = current_user THEN
    ALTER SCHEMA public OWNER TO __ROLE__;
  END IF;
  -- 표·시퀀스·뷰 (열에 딸린 시퀀스와 확장 소속 객체는 표·확장을 따라가요)
  FOR r IN SELECT c.oid::regclass AS obj, CASE c.relkind WHEN 'S' THEN 'SEQUENCE' WHEN 'v' THEN 'VIEW'
      WHEN 'm' THEN 'MATERIALIZED VIEW' WHEN 'f' THEN 'FOREIGN TABLE' WHEN 'c' THEN 'TYPE' ELSE 'TABLE' END AS kind
    FROM pg_class c
    WHERE c.relnamespace = 'public'::regnamespace AND pg_get_userbyid(c.relowner) = current_user
      AND c.relkind IN ('r', 'p', 'v', 'm', 'S', 'f', 'c')
      AND NOT EXISTS (SELECT FROM pg_depend d WHERE d.classid = 'pg_class'::regclass AND d.objid = c.oid AND d.deptype IN ('a', 'i', 'e'))
  LOOP
    EXECUTE format('ALTER %s %s OWNER TO __ROLE__', r.kind, r.obj);
  END LOOP;
  FOR r IN SELECT p.oid::regprocedure AS obj FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace AND pg_get_userbyid(p.proowner) = current_user
      AND NOT EXISTS (SELECT FROM pg_depend d WHERE d.classid = 'pg_proc'::regclass AND d.objid = p.oid AND d.deptype = 'e')
  LOOP
    EXECUTE format('ALTER ROUTINE %s OWNER TO __ROLE__', r.obj);
  END LOOP;
  FOR r IN SELECT t.oid::regtype AS obj, CASE t.typtype WHEN 'd' THEN 'DOMAIN' ELSE 'TYPE' END AS kind FROM pg_type t
    WHERE t.typnamespace = 'public'::regnamespace AND pg_get_userbyid(t.typowner) = current_user AND t.typtype IN ('e', 'd', 'r')
      AND NOT EXISTS (SELECT FROM pg_depend d WHERE d.classid = 'pg_type'::regclass AND d.objid = t.oid AND d.deptype = 'e')
  LOOP
    EXECUTE format('ALTER %s %s OWNER TO __ROLE__', r.kind, r.obj);
  END LOOP;
END $$;
SQL
}
db_roles() { # 앱 DB 계정 준비. 설치·업데이트·복원 전에 매번 실행해요 (이미 돼 있으면 바뀌는 게 없어요)
  local pw; pw=$(env_get API_DB_PASSWORD)
  printf '%s' "$pw" | grep -Eq '^[0-9a-f]{32,}$' || die "설정 파일에 API_DB_PASSWORD 가 없어요. 설치 프로그램을 다시 실행하세요."
  db_roles_sql "$pw" | dc exec -T db psql -X -v ON_ERROR_STOP=1 -q -U app -d cleaning >/dev/null \
    || die "앱 DB 계정을 준비하지 못했어요. 'dahae logs db' 로 확인하세요. 지금 서비스는 그대로예요."
}

verify_image() { # verify_image 저장소/이름:태그 -> 서명이 확인된 저장소/이름@sha256:… (확인 못 하면 멈춰요)
  local ref="$1" signer out digest cosign="$DIR/bin/cosign"
  signer=$(env_get SIGNER_REPO)
  valid_signer "$signer" || die "이미지 서명자 설정(SIGNER_REPO)이 없거나 이상해요: '$signer'. 설치 프로그램을 다시 실행하세요."
  [ -x "$cosign" ] || die "이미지 서명 확인 도구($cosign)가 없어요. 설치 프로그램을 다시 실행하세요. 지금 서비스는 그대로예요."
  if ! out=$(TUF_ROOT="$DIR/.sigstore" "$cosign" verify --certificate-identity-regexp "$(signer_re "$signer")" \
      --certificate-oidc-issuer "$SIGN_ISSUER" -o json "$ref" 2>&1); then
    printf '%s\n' "$out" | tail -n 3 >&2
    die "이미지 서명을 확인하지 못해서 새 버전을 적용하지 않았어요: $ref
  정식 릴리스($signer)가 서명한 이미지가 아니거나 서명 확인 서버(sigstore)에 닿지 못했어요. 지금 서비스는 그대로예요."
  fi
  digest=$(printf '%s' "$out" | grep -o '"docker-manifest-digest":"sha256:[0-9a-f]\{64\}"' | head -n1 | cut -d'"' -f4)
  [ -n "$digest" ] || die "서명 확인 결과에서 이미지 지문을 찾지 못했어요: $ref. 지금 서비스는 그대로예요."
  printf '%s@%s' "${ref%:*}" "$digest"
}
pull_images() { # pull_images 저장소 태그 : 띄울 이미지를 NEW_API / NEW_WEB 에 정해요 (서명 확인 → 그 다이제스트로 내려받기)
  local repo="$1" ver="$2"
  if [ "$(env_get IMAGE_SOURCE)" = local ]; then
    docker image inspect "$repo/malkkeum-api:$ver" "$repo/malkkeum-web:$ver" >/dev/null 2>&1 \
      || die "이미지 $ver 이 없어요. 먼저 'dahae load 파일.tar' 를 실행하세요."
    warn "직접 불러온 이미지 파일(.tar)이라 서명 확인 없이 써요."
    NEW_API=$repo/malkkeum-api:$ver; NEW_WEB=$repo/malkkeum-web:$ver
    return 0
  fi
  if [ "$(env_get IMAGE_VERIFY)" = off ]; then
    warn "이미지 서명 확인이 꺼져 있어요 (서명 없는 테스트 저장소 전용). 실제 서버라면 설치 프로그램을 다시 실행하세요."
    NEW_API=$repo/malkkeum-api:$ver; NEW_WEB=$repo/malkkeum-web:$ver
  else
    NEW_API=$(verify_image "$repo/malkkeum-api:$ver") || exit 1
    NEW_WEB=$(verify_image "$repo/malkkeum-web:$ver") || exit 1
  fi
  { docker pull -q "$NEW_API" >/dev/null && docker pull -q "$NEW_WEB" >/dev/null; } \
    || die "새 버전을 내려받지 못했어요. 지금 서비스는 그대로 돌고 있어요."
}

# 앱이 DB 까지 정상인지(컨테이너 안 /ready)와 웹 서버가 돌고 있는지를 봐요. HTTPS 인증서와는 무관해요.
health_ok() { dc exec -T api api --ready >/dev/null 2>&1 && [ -n "$(dc ps -q --status running web 2>/dev/null)" ]; }
https_ok() {
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
running_image() { # running_image 서비스 .env태그 -> 실행 중인 컨테이너의 이미지 ID (없으면 태그의 ID)
  local cid; cid=$(dc ps -q "$1" 2>/dev/null | head -n1 || true)
  if [ -n "$cid" ]; then docker inspect -f '{{.Image}}' "$cid"; else docker image inspect -f '{{.Id}}' "$2" 2>/dev/null || printf '%s' "$2"; fi
}
# 지금 쓰는 이미지를 바뀌지 않는 이름으로 기록해 둬야, 태그가 새 이미지로 옮겨 가도 되돌릴 수 있어요.
# 저장소에서 받은 이미지는 저장소@다이제스트, tar 로 불러온 이미지는 이미지 ID 로 만든 로컬 태그(keep-…)를 써요.
digest_ref() { # digest_ref 이미지 저장소이름
  local id d
  id=$(docker image inspect -f '{{.Id}}' "$1" 2>/dev/null) || { printf '%s' "$1"; return 0; }
  if [ "$(env_get IMAGE_SOURCE)" != local ]; then
    d=$(docker image inspect -f '{{index .RepoDigests 0}}' "$id" 2>/dev/null || true)
    if [ -n "$d" ]; then printf '%s' "$d"; return 0; fi
  fi
  d="$2:keep-$(printf '%s' "${id#sha256:}" | cut -c1-12)"
  docker tag "$id" "$d" >/dev/null
  printf '%s' "$d"
}
prune_keep_tags() { # 되돌리기에 쓰는 태그만 남기고 예전 keep- 태그를 지워요
  local t keep; keep=" $(env_get PREV_API_IMAGE) $(env_get PREV_WEB_IMAGE) $(env_get API_IMAGE) $(env_get WEB_IMAGE) "
  for t in $(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep ':keep-' || true); do
    case "$keep" in *" $t "*) ;; *) docker rmi "$t" >/dev/null 2>&1 || true ;; esac
  done
  docker image prune -f --filter until=336h >/dev/null 2>&1 || true
}
set_images() { # 이미지 두 개를 지정해서 기동하고 .env 에 기록해요.
  env_set API_IMAGE "$1"; env_set WEB_IMAGE "$2"
  dc up -d --remove-orphans
}

cmd_backup() { # BACKUP_WARN=1 이면 DB 는 백업됐지만 사진 파일이나 외부 백업이 실패했어요
  local ts db up prune="${1:-prune}"; ts=$(date +%Y%m%d-%H%M%S); BACKUP_WARN=0
  db="backups/db-$ts.sql.gz"; up="backups/uploads-$ts.tar.gz"
  if ! dc exec -T db pg_dump -U app -d cleaning --clean --if-exists | gzip > "$db"; then
    rm -f "$db"; die "DB 백업에 실패했어요. 'dahae logs db' 로 확인하세요."
  fi
  if ! dc run --rm --no-deps -T --entrypoint tar api czf - -C /data uploads > "$up"; then
    rm -f "$up"; BACKUP_WARN=1; warn "사진 파일 백업에 실패했어요 (DB 백업은 됐어요). 'dahae logs api' 로 확인하세요."
  fi
  [ "$prune" = noprune ] || find backups \( -name 'db-*.sql.gz' -o -name 'uploads-*.tar.gz' \) -mtime +"$BACKUP_KEEP_DAYS" -delete
  # Offsite copy (콘솔: 설정 > 외부 백업). The local backup stays good if this fails or isn't set up.
  if [ -f "$up" ]; then api_backup backup-upload "/$up" >> backups/backup.log 2>&1 || true; fi
  api_backup backup-upload "/$db" >> backups/backup.log 2>&1 \
    || warn "외부 백업 실패 또는 미설정 — 콘솔 [설정 > 외부 백업]을 확인하세요"
  ok "백업 완료: $DIR/$db"
}

cmd_load() { # 미리 받아 둔 이미지 묶음(.tar)을 불러와요. 인터넷 없이 업데이트할 때 써요.
  local f="${1:?사용법: dahae load 파일.tar}"
  [ -f "$f" ] || die "파일을 찾을 수 없어요: $f"
  docker load -i "$f" || die "이미지 파일을 불러오지 못했어요: $f"
  env_set IMAGE_SOURCE local
  ok "이미지를 불러왔어요. 적용하려면: dahae update <태그>  (위 Loaded image 의 태그)"
}

cmd_update() { # dahae update [태그]: 태그를 주면 그 버전으로 바꿔요 (로컬 이미지면 먼저 dahae load)
  local repo ver cur_api cur_web new_api
  printf '\n▶ 업데이트를 시작합니다 (먼저 백업해요)\n'
  db_roles # 백업의 외부 업로드도 앱 계정으로 접속해요: 예전 설치를 처음 올릴 때 계정부터 만들어요
  cmd_backup
  repo=$(env_get IMAGE_REPO); ver=${1:-$(env_get VERSION)}
  pull_images "$repo" "$ver"
  cur_api=$(digest_ref "$(running_image api "$(env_get API_IMAGE)")" "$repo/malkkeum-api")
  cur_web=$(digest_ref "$(running_image web "$(env_get WEB_IMAGE)")" "$repo/malkkeum-web")
  new_api=$(docker image inspect -f '{{.Id}}' "$NEW_API")
  # 같은 이미지로 다시 맞추는 경우(설치 프로그램 재실행 등)에는 되돌리기 기록을 덮어쓰지 않아요.
  if [ "$new_api" != "$(docker image inspect -f '{{.Id}}' "$cur_api" 2>/dev/null || true)" ]; then
    env_set PREV_API_IMAGE "$cur_api"; env_set PREV_WEB_IMAGE "$cur_web"
  fi
  set_images "$NEW_API" "$NEW_WEB"
  if wait_healthy; then
    env_set VERSION "$ver"
    prune_keep_tags
    ok "최신 버전($ver)으로 업데이트했어요"
    return 0
  fi
  warn "새 버전이 응답하지 않아요. 이전 버전으로 되돌릴게요."
  set_images "$cur_api" "$cur_web"
  if wait_healthy; then
    die "업데이트에 실패해서 이전 버전으로 되돌렸어요. 'dahae logs' 로 원인을 확인해 주세요."
  fi
  die "이전 버전으로도 응답하지 않아요. 'dahae logs' 화면을 개발자에게 전달해 주세요."
}

cmd_prepare() { # 설치 프로그램이 처음 띄우기 전에 불러요: 이미지 확인·내려받기 → DB 시작 → 앱 DB 계정
  local repo ver="${1:?사용법: dahae prepare 태그}"; repo=$(env_get IMAGE_REPO)
  pull_images "$repo" "$ver"
  env_set API_IMAGE "$NEW_API"; env_set WEB_IMAGE "$NEW_WEB"
  dc up -d --wait db >/dev/null || die "DB 를 시작하지 못했어요. 'dahae logs db' 로 확인하세요."
  db_roles
}

cmd_rollback() {
  local prev_api prev_web cur_api cur_web repo
  prev_api=$(env_get PREV_API_IMAGE); prev_web=$(env_get PREV_WEB_IMAGE); repo=$(env_get IMAGE_REPO)
  if [ -z "$prev_api" ] || [ "$prev_api" = "$(env_get API_IMAGE)" ]; then
    die "되돌릴 이전 버전 기록이 없어요. 업데이트를 한 번 한 뒤에 쓸 수 있어요."
  fi
  cmd_backup
  cur_api=$(digest_ref "$(running_image api "$(env_get API_IMAGE)")" "$repo/malkkeum-api")
  cur_web=$(digest_ref "$(running_image web "$(env_get WEB_IMAGE)")" "$repo/malkkeum-web")
  env_set PREV_API_IMAGE "$cur_api"; env_set PREV_WEB_IMAGE "$cur_web"
  set_images "$prev_api" "${prev_web:-$(env_get WEB_IMAGE)}"
  # 데이터베이스 구조 변경(마이그레이션)은 되돌리지 않아요. 이전 버전은 새 구조를 그대로 읽어요.
  if wait_healthy; then ok "이전 버전으로 되돌렸어요"; else die "되돌린 뒤에도 응답이 없어요. 'dahae logs' 를 확인하세요."; fi
}

cmd_channel() {
  local ch="${1:-}"
  case "$ch" in
    stable|beta) ;;
    *) die "사용법: dahae channel stable | beta" ;;
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
  if health_ok; then ok "앱 정상"; else warn "앱 응답 없음 — 'dahae logs' 로 확인하세요"; fi
  if https_ok; then ok "HTTPS 정상: https://$(env_get DOMAIN)/admin/"
  else warn "HTTPS 인증서가 아직 없어요. 도메인 A 레코드가 이 서버를 가리키면 몇 분 안에 자동으로 발급돼요."; fi
  if [ -n "$(env_get HEARTBEAT_URL)" ]; then ok "외부 가동 확인(heartbeat) 설정됨"; else warn "외부 가동 확인이 없어요 — 'dahae heartbeat <주소>' 로 켜세요 (healthchecks.io 등)"; fi
  # 로컬 백업은 DB 와 같은 디스크에 있어요: 외부 백업이 없으면 디스크 하나를 잃을 때 전부 잃어요.
  if tail -n 40 backups/backup.log 2>/dev/null | grep -q 'offsite backup uploaded'; then ok "외부 백업 정상"
  else warn "최근 외부 백업이 없어요 — 서버 디스크를 잃으면 데이터도 모두 잃어요. 콘솔 [설정 > 외부 백업]에서 켜세요"; fi
  if compgen -G 'backups/keys-*.env.enc' >/dev/null; then ok "비밀 키 사본 있음 (서버 밖에도 보관했는지 확인하세요)"
  else warn "비밀 키 사본이 없어요 — 'dahae keys-backup' 으로 만들어 서버 밖에 보관하세요. 없으면 외부 백업을 풀 수 없어요"; fi
}

cmd_keys_backup() { # dahae keys-backup : 외부 백업은 DATA_KEY 로 잠겨요. 서버를 잃어도 풀 수 있게 .env 를 비밀번호로 잠근 사본을 만들어요
  local out pass="${DAHAE_KEYS_PASSPHRASE:-}" again
  out="backups/keys-$(date +%Y%m%d-%H%M%S).env.enc"
  if [ -z "$pass" ]; then
    has_tty || die "비밀번호를 물어볼 터미널이 없어요. 터미널에서 'sudo dahae keys-backup' 을 실행하세요."
    IFS= read -rsp "잠금 비밀번호 (12자 이상, 서버 밖에 적어 두세요): " pass </dev/tty; echo
    IFS= read -rsp "한 번 더: " again </dev/tty; echo
    [ "$pass" = "$again" ] || die "두 비밀번호가 달라요. 다시 실행하세요."
  fi
  [ "${#pass}" -ge 12 ] || die "비밀번호는 12자 이상이어야 해요."
  keys_seal "$pass" < .env > "$out" || { rm -f "$out"; die "비밀 키 사본을 만들지 못했어요 (openssl)."; }
  ok "비밀 키 사본: $DIR/$out"
  echo "  이 파일과 비밀번호를 서버 밖(USB, 비밀번호 관리자 등)에 따로 보관하세요. 서버를 잃으면:"
  echo "  새 서버에 설치 → dahae keys-restore <이 파일> → 콘솔에서 외부 백업 연결 → dahae restore-offsite"
}

keys_field() { sed -n "s/^$1=\([0-9a-f]\{32,\}\)\$/\1/p" | tail -n1; } # keys_field 이름 < 내용 : 16진수 값만

cmd_keys_restore() { # dahae keys-restore 파일 [--yes] : 잠근 사본의 DATA_KEY·JWT_SECRET 을 이 서버에 넣어요
  local f="" a pass="${DAHAE_KEYS_PASSPHRASE:-}" plain key jwt
  for a in "$@"; do case "$a" in --yes|-y) YES=1 ;; *) f="$a" ;; esac; done
  { [ -n "$f" ] && [ -f "$f" ]; } || die "사용법: dahae keys-restore keys-20261110-033000.env.enc [--yes]"
  if [ -z "$pass" ]; then
    has_tty || die "비밀번호를 물어볼 터미널이 없어요."
    IFS= read -rsp "잠금 비밀번호: " pass </dev/tty; echo
  fi
  plain=$(keys_open "$pass" < "$f") || die "비밀번호가 틀렸거나 파일이 손상됐어요. 아무것도 바뀌지 않았어요."
  # 파이프로 넘겨요: here-string 은 오래된 bash 에서 /tmp 에 임시 파일을 만들어요.
  key=$(printf '%s\n' "$plain" | keys_field DATA_KEY); jwt=$(printf '%s\n' "$plain" | keys_field JWT_SECRET)
  [ "${#key}" = 64 ] || die "사본에 DATA_KEY 가 없어요. 아무것도 바뀌지 않았어요."
  confirm "이 서버의 DATA_KEY 를 사본의 키로 바꿀까요? 이 서버에서 새로 입력한 연동 키는 다시 입력해야 해요." yes
  cp -p .env "backups/env-before-keys-restore-$(date +%Y%m%d-%H%M%S)"
  env_set DATA_KEY "$key"
  if [ -n "$jwt" ]; then env_set JWT_SECRET "$jwt"; fi
  dc up -d api >/dev/null
  wait_healthy || die "키를 바꾼 뒤 앱이 응답하지 않아요. 'dahae logs' 를 확인하세요. 예전 .env 는 backups/ 에 있어요."
  ok "예전 비밀 키를 넣었어요. 이제 콘솔에서 외부 백업을 연결하고 'dahae restore-offsite' 로 되돌리세요."
}

cmd_alert() { # dahae alert update|backup : 예약 작업(cron)이 실패하면 외부 가동 확인 주소로 실패 신호와 로그 끝부분을 보내요
  local what="${1:-}" url
  case "$what" in update|backup) ;; *) die "사용법: dahae alert update|backup" ;; esac
  url=$(env_get HEARTBEAT_URL)
  [ -n "$url" ] || { warn "외부 가동 확인 주소가 없어 실패를 알리지 못했어요 ('dahae heartbeat <주소>' 로 켜세요)"; return 1; }
  tail -n 30 "backups/$what.log" 2>/dev/null | curl -fsS --max-time 15 -o /dev/null --data-binary @- "$(fail_url "$url")" \
    || { warn "실패 알림을 보내지 못했어요"; return 1; }
  ok "자동 $what 실패를 알렸어요"
}

cmd_restore() { # dahae restore 파일 [--yes]
  local f="" up a
  for a in "$@"; do case "$a" in --yes|-y) YES=1 ;; *) f="$a" ;; esac; done
  [ -n "$f" ] || die "복원할 백업 파일을 지정하세요. 예: dahae restore backups/db-20261110-033000.sql.gz"
  [ -f "$f" ] || die "백업 파일을 찾을 수 없어요: $f"
  gzip -t "$f" 2>/dev/null || die "백업 파일이 손상됐어요: $f"
  up=$(uploads_for "$f")
  if [ -f "$up" ] && ! uploads_tar_ok "$up"; then
    die "사진 파일 백업이 손상됐거나 허용되지 않는 항목(절대 경로, .., 링크)이 있어서 복원을 멈췄어요. 아무것도 바뀌지 않았어요: $up"
  fi
  confirm "현재 데이터를 $f 로 되돌릴까요? 지금 데이터는 먼저 따로 백업해 둬요." yes
  printf '\n▶ 복원 전에 지금 상태를 백업해요\n'
  cmd_backup noprune
  db_roles
  dc stop api >/dev/null
  # 한 트랜잭션으로 적용해요: 오류가 하나라도 나면 아무것도 바뀌지 않아요.
  if ! gunzip -c "$f" | restore_filter | psql_api -v ON_ERROR_STOP=1 --single-transaction -q >/dev/null; then
    dc start api >/dev/null || true
    die "DB 복원에 실패했어요. 데이터는 복원 전 그대로예요. 위 오류를 개발자에게 전달해 주세요."
  fi
  local files=복원됨 rc=0
  if [ ! -f "$up" ]; then
    files="백업 없음"; warn "같은 시각의 사진 파일 백업($up)이 없어 DB 만 복원했어요."
  elif ! dc run --rm --no-deps -T --entrypoint sh api -c "$UPLOADS_SWAP" < "$up"; then
    files=실패; rc=1; warn "사진 파일 복원에 실패했어요 (DB 는 복원됐어요): $up"
  fi
  dc start api >/dev/null
  wait_healthy || die "복원 뒤 앱이 응답하지 않아요. 'dahae logs' 를 확인하세요."
  ok "복원 완료: $f (사진 파일: $files)"
  return "$rc"
}

cmd_restore_offsite() { # dahae restore-offsite [이름] [--yes]
  local name="" a up_name
  for a in "$@"; do case "$a" in --yes|-y) YES=1 ;; *) name="$a" ;; esac; done
  if [ -z "$name" ]; then api_backup backup-list; return 0; fi
  valid_backup_name "$name" || die "외부 백업 이름이 아니에요 (예: db-20261110-033000.sql.gz.enc): $name"
  api_backup backup-fetch "$name" "/backups/${name%.enc}" || die "외부 백업을 내려받지 못했어요"
  up_name=$(basename "$(uploads_for "${name%.enc}")")
  api_backup backup-fetch "$up_name.enc" "/backups/$up_name" >/dev/null 2>&1 \
    || warn "외부 백업에 같은 시각의 사진 파일이 없어요"
  cmd_restore "backups/${name%.enc}"
}

cmd_heartbeat() { # dahae heartbeat <https 주소>|off
  local url="${1:-}"
  case "$url" in
    "") die "사용법: dahae heartbeat https://hc-ping.com/... (끄려면: dahae heartbeat off)" ;;
    off) url="" ;;
    *) printf '%s' "$url" | grep -Eq "$HB_URL_RE" || die "https:// 로 시작하는 주소만 쓸 수 있어요 (& 나 공백은 안 돼요): $url" ;;
  esac
  env_set HEARTBEAT_URL "$url"
  dc up -d api >/dev/null
  if [ -z "$url" ]; then ok "외부 가동 확인을 껐어요"; return 0; fi
  if curl -fsS --max-time 10 -o /dev/null "$url"; then ok "외부 가동 확인을 켰어요. 테스트 핑을 보냈어요."
  else warn "주소는 저장했지만 테스트 핑이 실패했어요. 주소를 확인하세요."; fi
}

cmd_applinks() { # dahae applinks --android-sha256 지문[,지문] --apple-team-id 팀ID
  local sha="" team="" changed=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --android-sha256) sha="${2:-}"; shift 2 || die "--android-sha256 다음에 지문을 쓰세요" ;;
      --apple-team-id) team="${2:-}"; shift 2 || die "--apple-team-id 다음에 팀 ID 를 쓰세요" ;;
      *) die "$USAGE" ;;
    esac
  done
  [ -n "$sha$team" ] || die "사용법: dahae applinks --android-sha256 AA:BB:...(32쌍)[,다른지문] --apple-team-id ABCDE12345"
  if [ -n "$sha" ]; then
    valid_fingerprints "$sha" || die "Android 인증서 SHA-256 지문 형식이 아니에요 (AA:BB:... 32쌍, 여러 개는 쉼표로): $sha"
    env_set ANDROID_CERT_SHA256 "$(printf '%s' "$sha" | tr 'a-f' 'A-F')"; changed=1
  fi
  if [ -n "$team" ]; then
    valid_team_id "$team" || die "Apple 팀 ID 는 영문·숫자 10자리예요: $team"
    env_set APPLE_TEAM_ID "$team"; changed=1
  fi
  [ "$changed" = 1 ] && dc up -d api >/dev/null
  wait_healthy || die "설정 후 앱이 응답하지 않아요. 'dahae logs' 를 확인하세요."
  ok "앱 링크를 설정했어요: https://$(env_get DOMAIN)/.well-known/assetlinks.json"
}

cmd_uninstall() { # dahae uninstall [--yes] | dahae uninstall --purge [--confirm 도메인]
  local purge=0 given=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --purge) purge=1 ;;
      --yes|-y) YES=1 ;;
      --confirm) given="${2:-}"; [ -n "$given" ] || die "--confirm 다음에 도메인을 쓰세요"; shift ;;
      *) die "$USAGE" ;;
    esac
    shift
  done
  if [ "$purge" = 1 ]; then
    purge_ok "$given"
  else
    confirm "다해 서비스를 끌까요? 데이터와 백업은 $DIR 와 Docker 볼륨에 남겨 둬요." yes
  fi
  if [ "$purge" = 1 ]; then dc down --volumes --remove-orphans || true; else dc down --remove-orphans || true; fi
  rm -f /etc/cron.d/malkkeum /etc/logrotate.d/dahae "$BIN/malkkeum-heartbeat" "$BIN/malkkeum" "$BIN/dahae"
  if [ "$purge" = 1 ]; then
    case "$DIR" in /opt/?*) cd / && rm -rf "$DIR" ;; *) die "삭제할 폴더가 이상해요: $DIR" ;; esac
    ok "다해를 모두 지웠어요 (Docker 자체는 남겨 뒀어요)"
  else
    ok "다해 서비스를 껐어요. 설정과 백업은 $DIR 에 남아 있어요. 설치 프로그램을 다시 실행하면 그대로 이어서 써요."
  fi
}

main() {
  cd "$DIR"
  # Backups hold every customer's data: only root may read them.
  umask 077
  chmod 700 backups 2>/dev/null || true
  chmod 600 .env 2>/dev/null || true
  YES=${DAHAE_YES:-0}
  case "${1:-status}" in
    status) cmd_status ;;
    update) shift; cmd_update "$@" ;;
    load) shift; cmd_load "$@" ;;
    prepare) shift; cmd_prepare "$@" ;; # 설치 프로그램 전용
    rollback) cmd_rollback ;;
    channel) shift; cmd_channel "$@" ;;
    version) cmd_version ;;
    backup) cmd_backup; [ "$BACKUP_WARN" = 0 ] ;;
    restore) shift; cmd_restore "$@" ;;
    restore-offsite) shift; cmd_restore_offsite "$@" ;;
    heartbeat) shift; cmd_heartbeat "$@" ;;
    keys-backup) cmd_keys_backup ;;
    keys-restore) shift; cmd_keys_restore "$@" ;;
    alert) shift; cmd_alert "$@" ;;
    applinks) shift; cmd_applinks "$@" ;;
    uninstall) shift; cmd_uninstall "$@" ;;
    demo)
      case "${2:-}" in
        load)
          echo "체험용 데이터를 넣을게요. 실제 예약이 이미 있으면 넣지 않아요. (강제로 넣으려면: dahae demo load --force)"
          dc exec -T api api demo load ${3:+"$3"} && ok "체험용 데이터를 넣었어요. 지우려면: dahae demo clear" ;;
        clear)
          confirm "체험용 데이터를 모두 지울까요? 실제 고객·예약 데이터는 지우지 않아요." yes
          dc exec -T api api demo clear && ok "체험용 데이터를 지웠어요" ;;
        *) die "사용법: dahae demo [load [--force] | clear]" ;;
      esac ;;
    logs) dc logs --tail 200 -f "${2:-api}" ;;
    setup-code) env_get SETUP_CODE | sed -E 's/(....)(....)(....)/\1-\2-\3/' ;;
    help|-h|--help) echo "$USAGE" ;;
    *) echo "$USAGE"; exit 1 ;;
  esac
}
[ "${DAHAE_SELFTEST:-}" = 1 ] || main "$@"
CLI
  sed -i "s|__DIR__|$DIR|" "$1"
  chmod 755 "$1"
}

write_heartbeat() { # 5분마다 /health 가 정상일 때만 HEARTBEAT_URL 로 핑을 보내요. 핑이 끊기면 외부 서비스가 알려줘요.
  cat > "$1" <<'HB'
#!/usr/bin/env bash
# 다해 외부 가동 확인 핑 (healthchecks.io 등). HEARTBEAT_URL 이 없으면 로그만 남기고 끝나요.
DIR=__DIR__
URL=$(grep -E '^HEARTBEAT_URL=' "$DIR/.env" 2>/dev/null | tail -n1 | cut -d= -f2-)
DOMAIN=$(grep -E '^DOMAIN=' "$DIR/.env" 2>/dev/null | tail -n1 | cut -d= -f2-)
TLS=$(grep -E '^TLS_MODE=' "$DIR/.env" 2>/dev/null | tail -n1 | cut -d= -f2-)
# 공인 인증서는 검사까지 해요: 인증서 만료나 발급 실패도 핑이 끊겨 알림이 가요. 내부 인증서(테스트)만 -k.
insecure=; [ "$TLS" = internal ] && insecure=1
if [ -z "$URL" ]; then echo "$(date -Is) HEARTBEAT_URL 없음 - 외부 가동 확인이 꺼져 있어요" >&2; exit 0; fi
if curl -fsS ${insecure:+-k} --max-time 10 --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN/health" 2>/dev/null | grep -q '"ok":true'; then
  curl -fsS --max-time 10 -o /dev/null "$URL" || echo "$(date -Is) 핑 전송 실패" >&2
fi
HB
  sed -i "s|__DIR__|$DIR|" "$1"
  chmod 755 "$1"
}

write_schedules() { # 매일 03:30 백업, 매주 월요일 04:00 자동 업데이트 (업데이트 전에도 백업하고, 실패하면 자동으로 되돌려요).
  timedatectl set-timezone Asia/Seoul 2>/dev/null || true
  cat > /etc/cron.d/malkkeum <<EOF
30 3 * * * root $BIN/dahae backup >> $DIR/backups/backup.log 2>&1 || $BIN/dahae alert backup >> $DIR/backups/backup.log 2>&1
0 4 * * 1 root $BIN/dahae update >> $DIR/backups/update.log 2>&1 || $BIN/dahae alert update >> $DIR/backups/update.log 2>&1
*/5 * * * * root $BIN/malkkeum-heartbeat >> $DIR/backups/heartbeat.log 2>&1
EOF
  cat > /etc/logrotate.d/dahae <<EOF
$DIR/backups/*.log {
  weekly
  rotate 8
  compress
  delaycompress
  missingok
  notifempty
}
EOF
  ok "매일 새벽 3시 30분 자동 백업, 매주 월요일 자동 업데이트를 예약했어요"
}

wait_for() { # wait_for 초 명령... : 명령이 성공할 때까지 기다려요
  local limit="$1" waited=0; shift
  until "$@" >/dev/null 2>&1; do
    [ "$waited" -ge "$limit" ] && return 1
    sleep 5; waited=$((waited + 5))
  done
  return 0
}
app_ready() { dc exec -T api api --ready; }
https_up() { curl -fsSk --max-time 5 --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN/health"; }
owner_exists() { [ "$(dc exec -T db psql -U app -d cleaning -tAc 'SELECT EXISTS (SELECT 1 FROM staff)' 2>/dev/null | tr -d '[:space:]')" = t ]; }

final_banner() { # final_banner https정상(1/0)
  local code ch line='────────────────────────────────────────────────────────────'
  ch=$(env_get CHANNEL)
  code="  2) 설치 코드를 입력하고 사장님 계정을 만드세요:

         설치 코드:  $("$BIN/dahae" setup-code)
"
  owner_exists && code="  2) 사장님 계정으로 로그인하세요 (계정은 이미 만들어져 있어요).
"
  if [ "$1" = 1 ]; then
    printf '\n%s\n  ✔ 설치가 끝났어요!   (채널: %s)\n\n  1) 브라우저에서 이 주소를 여세요:   https://%s/admin/\n' "$line" "$ch" "$DOMAIN"
  else
    printf '\n%s\n  ! 앱은 정상이에요. HTTPS 인증서는 아직이에요.   (채널: %s)\n' "$line" "$ch"
    printf '    도메인 A 레코드가 이 서버를 가리키면 몇 분 안에 자동으로 발급돼요. 확인: dahae status\n\n'
    printf '  1) 인증서가 나오면 브라우저에서 이 주소를 여세요:   https://%s/admin/\n' "$DOMAIN"
  fi
  printf '%s\n  3) [설정] 메뉴에서 결제·문자·로그인 연동을 차례로 연결하세요.\n\n' "$code"
  printf '  ⚠ 비밀 키 사본을 꼭 만들어 서버 밖에 보관하세요:  sudo dahae keys-backup\n    (%s/.env 의 키가 없으면 외부 백업을 복원할 수 없어요)\n\n' "$DIR"
  printf '  관리 명령:  dahae status | update | rollback | backup | restore | logs | help\n%s\n' "$line"
}

main() {
  local k a m
  for k in DOMAIN EMAIL IMAGES IMAGES_TAR CHANNEL VERSION TLS SKIP_DNS_CHECK HEALTH_WAIT HEARTBEAT_URL SIGNER SKIP_SIGNATURE; do
    a=DAHAE_$k; m=MALKKEUM_$k
    if [ -n "${!a:-}" ] && [ -z "${!m:-}" ]; then export "$m=${!a}"; fi
  done
  HEALTH_WAIT_SECS=${MALKKEUM_HEALTH_WAIT:-300}

  [ "$(id -u)" -eq 0 ] || die "관리자 권한이 필요해요. 명령 앞에 sudo 를 붙여 다시 실행해 주세요."
  command -v apt-get >/dev/null || die "Ubuntu 또는 Debian 서버에서 실행해 주세요."

  say "다해 서버 설치를 시작합니다"
  preflight
  mkdir -p "$DIR/backups"
  cd "$DIR"

  if [ -f .env ]; then
    ok "기존 설치를 찾았어요. 설정과 데이터는 그대로 두고 최신 버전으로 업데이트합니다."
    FRESH=0
  else
    FRESH=1
  fi

  # 설정 값 우선순위: 환경 변수 > 기존 .env > 기본값. .env 는 읽기만 하고 실행(source)하지 않아요.
  IMAGE_REPO=${MALKKEUM_IMAGES:-$(env_get IMAGE_REPO)}; IMAGE_REPO=${IMAGE_REPO:-$IMAGE_REPO_DEFAULT}
  TLS_MODE=${MALKKEUM_TLS:-$(env_get TLS_MODE)}
  CHANNEL=${MALKKEUM_CHANNEL:-$(env_get CHANNEL)}; CHANNEL=${CHANNEL:-$DEFAULT_CHANNEL}
  VERSION=${MALKKEUM_VERSION:-${MALKKEUM_CHANNEL:-$(env_get VERSION)}}; VERSION=${VERSION:-$CHANNEL}
  IMAGES_TAR=${MALKKEUM_IMAGES_TAR:-}
  if [ -n "$IMAGES_TAR" ]; then
    IMAGE_SOURCE=local
    VERSION=${MALKKEUM_VERSION:-local}
  else
    IMAGE_SOURCE=$(env_get IMAGE_SOURCE); IMAGE_SOURCE=${IMAGE_SOURCE:-remote} # 한번 local 로 설치했으면 계속 local
  fi
  SIGNER_REPO=${MALKKEUM_SIGNER:-$(env_get SIGNER_REPO)}; SIGNER_REPO=${SIGNER_REPO:-$SIGNER_REPO_DEFAULT}
  IMAGE_VERIFY=on; [ -z "${MALKKEUM_SKIP_SIGNATURE:-}" ] || IMAGE_VERIFY=off
  case "$CHANNEL" in stable|beta) ;; *) die "채널은 stable 또는 beta 중 하나예요." ;; esac
  printf '%s' "$SIGNER_REPO" | grep -Eq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' || die "MALKKEUM_SIGNER 는 owner/repo 형식이에요: $SIGNER_REPO"
  case "$TLS_MODE" in ""|internal) ;; *) die "MALKKEUM_TLS 는 internal 만 쓸 수 있어요." ;; esac

  DOMAIN=${MALKKEUM_DOMAIN:-$(env_get DOMAIN)}
  if [ -z "$DOMAIN" ]; then
    DOMAIN=$(ask_until valid_domain "서비스 주소(도메인)를 입력하세요. 예: myshop.co.kr" "도메인 형식이 올바르지 않아요 (예: myshop.co.kr)") \
      || die "도메인이 필요해요. 예: myshop.co.kr"
  fi
  valid_domain "$DOMAIN" || die "도메인 형식이 올바르지 않아요: $DOMAIN (예: myshop.co.kr)"
  DOMAIN=$(norm_domain "$DOMAIN")
  if [ -n "${MALKKEUM_EMAIL:-}" ] || [ "$FRESH" = 0 ]; then
    ACME_EMAIL=${MALKKEUM_EMAIL:-$(env_get ACME_EMAIL)}
  else
    ACME_EMAIL=$(ask_until valid_email "보안 인증서 안내를 받을 이메일 (없으면 Enter)" "이메일 형식이 올바르지 않아요 (예: owner@myshop.co.kr)") \
      || die "이메일 형식이 올바르지 않아요."
  fi
  valid_email "$ACME_EMAIL" || die "이메일 형식이 올바르지 않아요: $ACME_EMAIL"
  if [ -n "${MALKKEUM_HEARTBEAT_URL:-}" ]; then
    valid_hb_url "$MALKKEUM_HEARTBEAT_URL" || die "MALKKEUM_HEARTBEAT_URL 은 https:// 주소여야 해요 (& 나 공백은 안 돼요)."
  fi

  say "필수 프로그램 설치 (새 서버면 자동 업데이트가 끝날 때까지 최대 10분 기다려요)"
  apt_retry update -qq || die "패키지 목록을 받지 못했어요. 인터넷 연결을 확인하고 다시 실행하세요."
  apt_retry install -y -qq ca-certificates curl openssl gzip cron dnsutils logrotate iproute2 >/dev/null \
    || die "필수 프로그램을 설치하지 못했어요. 잠시 뒤 다시 실행하세요."
  if ! command -v docker >/dev/null; then
    curl -fsSL https://get.docker.com | sh >/dev/null || die "Docker 를 설치하지 못했어요. 잠시 뒤 다시 실행하세요."
  fi
  systemctl enable --now docker >/dev/null 2>&1 || true
  local cv; cv=$(docker compose version --short 2>/dev/null) || die "Docker Compose 를 설치하지 못했어요."
  ver_ge "$cv" "$COMPOSE_MIN" || die "Docker Compose($cv)가 너무 오래됐어요. 'curl -fsSL https://get.docker.com | sudo sh' 로 업데이트하세요."
  ok "Docker 준비 완료"

  say "도메인 확인"
  dns_check

  if [ "$FRESH" = 1 ]; then
    umask 077
    cat > .env <<EOF
# 다해 서버 설정 — install.sh 가 만들었어요. 이 파일을 안전한 곳에 따로 보관하세요.
# DATA_KEY 를 잃어버리면 저장된 결제·연동 키와 계좌 정보를 복구할 수 없어요.
DB_PASSWORD=$(rand_hex 24)
JWT_SECRET=$(rand_hex 32)
DATA_KEY=$(rand_hex 32)
SETUP_CODE=$(setup_code)
EOF
    umask 022
    ok "보안 키를 새로 만들었어요"
  fi
  lock_env
  # 앱 전용 DB 계정 비밀번호. 예전 설치에는 없어서 처음 다시 실행할 때 만들어요 (계정은 dahae update 가 만들어요).
  [ -n "$(env_get API_DB_PASSWORD)" ] || env_set API_DB_PASSWORD "$(rand_hex 24)"
  env_set DOMAIN "$DOMAIN"
  env_set ACME_EMAIL "$ACME_EMAIL"
  env_set IMAGE_REPO "$IMAGE_REPO"
  env_set TLS_MODE "$TLS_MODE"
  env_set CHANNEL "$CHANNEL"
  env_set IMAGE_SOURCE "$IMAGE_SOURCE"
  env_set SIGNER_REPO "$SIGNER_REPO"
  env_set IMAGE_VERIFY "$IMAGE_VERIFY"
  if [ -n "${MALKKEUM_HEARTBEAT_URL:-}" ]; then env_set HEARTBEAT_URL "$MALKKEUM_HEARTBEAT_URL"; fi

  write_compose
  write_cli "$BIN/dahae"
  ln -sf dahae "$BIN/malkkeum"
  write_heartbeat "$BIN/malkkeum-heartbeat"
  ok "관리 명령 dahae 를 설치했어요 (예전 이름 malkkeum 도 그대로 돼요)"
  write_schedules

  if command -v ufw >/dev/null && ufw status | grep -q active; then
    ufw allow 22/tcp >/dev/null; ufw allow 80/tcp >/dev/null; ufw allow 443 >/dev/null
  fi

  if [ "$IMAGE_SOURCE" = local ]; then
    :
  elif [ "$IMAGE_VERIFY" = on ]; then
    install_cosign
    ok "이미지 서명 확인 도구 준비 완료 (cosign $COSIGN_VERSION)"
  else
    warn "이미지 서명 확인을 껐어요 (MALKKEUM_SKIP_SIGNATURE). 서명 없는 테스트 저장소에서만 쓰세요."
  fi

  if [ -n "$IMAGES_TAR" ]; then
    say "미리 받아 둔 이미지를 불러와요 (인터넷에서 받지 않아요)"
    load_images "$IMAGES_TAR" "$IMAGE_REPO/malkkeum-api:$VERSION" "$IMAGE_REPO/malkkeum-web:$VERSION"
    ok "이미지를 불러왔어요: $IMAGES_TAR"
  fi

  if [ "$FRESH" = 0 ] && [ -n "$(dc ps -q --status running db 2>/dev/null)" ]; then
    # 다시 실행 = 안전한 업데이트: 백업 → 새 버전 → 응답 확인, 실패하면 이전 버전으로 되돌려요.
    DAHAE_HEALTH_WAIT=$HEALTH_WAIT_SECS "$BIN/dahae" update "$VERSION" || die "업데이트하지 못했어요. 위 안내를 확인해 주세요."
  else
    env_set VERSION "$VERSION"
    say "서비스 시작 (처음에는 몇 분 걸릴 수 있어요)"
    # 이미지 서명 확인 → 확인된 다이제스트로 내려받기 → DB 와 앱 전용 계정 준비. 실패하면 아무것도 띄우지 않아요.
    "$BIN/dahae" prepare "$VERSION" || die "서비스를 준비하지 못했어요. 위 안내를 확인해 주세요. (다시 실행해도 안전해요)"
    dc up -d --remove-orphans
    wait_for "$HEALTH_WAIT_SECS" app_ready \
      || die "서비스가 시작되지 않았어요. 'dahae logs' 화면을 개발자에게 전달해 주세요. (다시 실행해도 안전해요)"
  fi
  ok "앱 정상"

  local tls_wait=$HEALTH_WAIT_SECS tls=0
  [ "$DNS_OK" = 1 ] || tls_wait=15
  if wait_for "$tls_wait" https_up; then tls=1; ok "HTTPS 정상"; fi
  final_banner "$tls"
}

[ "${DAHAE_SELFTEST:-}" = 1 ] || main "$@"
