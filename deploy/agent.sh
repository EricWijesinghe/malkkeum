#!/usr/bin/env bash
# 다해 서버 작업 실행기. root 로 돌고, systemd 가 jobs/inbox 에 작업 파일이 생기면 깨워요.
# 작업 파일은 API 컨테이너가 써요. 이 파일은 정해진 명령만 실행하고, 파일 내용을 셸로 해석하지 않아요.
#   사용법: agent.sh run   (dahae-agent.service 가 불러요)
# 작업 파일 형식: id=<UUIDv7>, kind=<종류>, arg=<값> 줄만 허용해요. 그 밖의 줄·키·중복은 거부해요.
set -euo pipefail

JOBS=${DAHAE_JOBS:-/opt/malkkeum/jobs}
HOST_DIR=${DAHAE_HOST_DIR:-/opt/malkkeum/host}
DIR=${DAHAE_DIR:-/opt/malkkeum}
CLI=${DAHAE_CLI:-/usr/local/bin/dahae}
JOB_UID=${DAHAE_JOB_UID:-10001}     # API 컨테이너의 사용자 번호: 이 번호가 아닌 주인의 파일은 무시해요
LOCK=${DAHAE_LOCK:-/run/dahae.lock} # 예약 작업(cron)과 같은 잠금
RUN_TIMEOUT=${DAHAE_RUN_TIMEOUT:-1800}
MAX_JOB_BYTES=4096
ID_WINDOW_MS=900000                 # 작업 번호(UUIDv7)의 시각은 15분 안이어야 해요
MAX_JOB_LINES=8

warn() { printf '! %s\n' "$*" >&2; }
die()  { printf '✘ %s\n' "$*" >&2; exit 1; }

# ---- 상태 기록 (사용자에게 보여요: 단계 줄만, 명령 출력은 남기지 않아요) ----
say_step() { printf '%s %s\n' "$1" "$2" >> "$JOBS/status/$JOB_ID.log"; }
set_state() { # set_state 상태 : status/<id>.json 을 원자적으로 바꿔요 (값은 모두 검사한 것만 들어가요)
  local tmp="$JOBS/status/.$JOB_ID.tmp"
  printf '{"id":"%s","kind":"%s","state":"%s"}\n' "$JOB_ID" "$JOB_KIND" "$1" > "$tmp"
  mv -f -- "$tmp" "$JOBS/status/$JOB_ID.json"
}

# ---- 검사 (규칙 2~6) ----
job_copy() { # job_copy 작업파일 사본 : 일반 파일과 주인을 확인하고, 한 번만 읽어 사본을 만들어요
  local f="$1" c="$2" uid size
  [ ! -L "$f" ] && [ -f "$f" ] || return 1
  uid=$(stat -c %u -- "$f") && size=$(stat -c %s -- "$f") || return 1
  [ "$uid" = "$JOB_UID" ] && [ "$size" -le "$MAX_JOB_BYTES" ] || return 1
  head -c $((MAX_JOB_BYTES + 1)) "$f" > "$c" || return 1
  [ "$(stat -c %s -- "$c")" -le "$MAX_JOB_BYTES" ]
}

job_parse() { # job_parse 사본 : key=value 줄만 읽어 JOB_ID·JOB_KIND·JOB_ARG 에 넣어요 (source·eval 없음)
  local k v n=0 seen=" "
  JOB_ID="" JOB_KIND="" JOB_ARG=""
  while IFS='=' read -r k v || [ -n "$k" ]; do
    n=$((n + 1)); [ "$n" -le "$MAX_JOB_LINES" ] || return 1
    case "$v" in *\\*|*$'\r'*|*=*) return 1 ;; esac
    case "$seen" in *" $k "*) return 1 ;; esac
    seen="$seen$k "
    case "$k" in
      id) JOB_ID=$v ;;
      kind) JOB_KIND=$v ;;
      arg) JOB_ARG=$v ;;
      *) return 1 ;;
    esac
  done < "$1"
  [ -n "$JOB_ID" ] && [ -n "$JOB_KIND" ]
}

id_fresh() { # id_fresh 번호 : UUIDv7 이고, 시각이 15분 안이며 미래가 아니어야 해요
  local id="$1" hex ms now
  printf '%s' "$id" | grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' || return 1
  hex=${id//-/}; hex=${hex:0:12}
  ms=$((16#$hex)); now=$(($(date +%s) * 1000))
  [ "$ms" -le "$now" ] && [ $((now - ms)) -le "$ID_WINDOW_MS" ]
}

job_args_ok() { # 종류와 값의 짝이 맞아야 해요. 목록에 없는 종류는 이 실행기에서 돌리지 않아요
  case "$JOB_KIND" in
    status-refresh|backup-now|update|update-skip) [ -z "$JOB_ARG" ] ;;
    channel) case "$JOB_ARG" in stable|beta) ;; *) return 1 ;; esac ;;
    restart) case "$JOB_ARG" in api|web|db|all) ;; *) return 1 ;; esac ;;
    *) return 1 ;;
  esac
}

ledger_take() { # ledger_take 번호 : 처음 보는 번호면 기록하고 성공해요. 같은 번호가 또 오면 실패해요 (다시 실행 막기)
  ( set -C; : > "$JOBS/work/done/$1" ) 2>/dev/null
}

# ---- 실행 (고정 명령만) ----
run_cli() { # run_cli 인자... : 관리 명령을 --yes 로, 입력 없이, 시간 제한을 걸어 실행해요
  local pre=()
  # setsid 는 리눅스 서버에 있어요. 없는 환경(개발 PC 테스트)에서는 생략해요.
  command -v setsid >/dev/null && pre=(setsid)
  DAHAE_YES=1 "${pre[@]}" timeout "$RUN_TIMEOUT" "$CLI" "$@" </dev/null >/dev/null 2>&1
}

run_compose() { # run_compose 인자... : compose 명령을 설치 폴더에서 실행해요 (출력은 남기지 않아요)
  (cd "$DIR" && timeout "$RUN_TIMEOUT" docker compose --env-file .env "$@") </dev/null >/dev/null 2>&1
}

host_refresh() { # 호스트 정보 파일(host.json)을 새로 써요: 확인 시각
  local tmp="$HOST_DIR/.host.tmp"
  printf '{"checked":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$tmp"
  mv -f -- "$tmp" "$HOST_DIR/host.json"
}

dispatch() { # 종류에 맞는 명령 하나만 실행해요
  case "$JOB_KIND" in
    status-refresh) host_refresh ;;
    backup-now) run_cli backup ;;
    update) run_cli update ;;
    update-skip) : > "$HOST_DIR/skip-next-update" ;;
    channel) run_cli channel "$JOB_ARG" ;;
    restart)
      if [ "$JOB_ARG" = all ]; then run_compose restart; else run_compose restart "$JOB_ARG"; fi ;;
  esac
}

run_job() { # 작업 하나를 실행하고 결과를 상태에 남겨요
  set_state running
  say_step "▶" "$JOB_KIND"
  if dispatch; then
    say_step "✔" "완료"; set_state ok
  else
    say_step "✘" "실패"; set_state failed
  fi
}

# ---- 흐름 ----
reject_job() { # reject_job 번호 : 검사에 실패한 작업은 상태를 rejected 로 두고 치워요
  local id="$1"
  # 이미 상태가 있는 번호(예전 작업의 재전송)는 덮어쓰지 않아요
  if printf '%s' "$id" | grep -Eq '^[0-9a-f-]{36}$' && [ ! -e "$JOBS/status/$id.json" ]; then
    printf '{"id":"%s","kind":"unknown","state":"rejected"}\n' "$id" > "$JOBS/status/$id.json"
  fi
  warn "작업을 거부했어요: $id"
}

intake_check() { # intake_check 사본 번호 : 파일 내용과 번호를 검사해요 (성공하면 JOB_* 가 채워져요)
  job_parse "$1" && [ "$JOB_ID" = "$2" ] && job_args_ok && id_fresh "$2"
}

intake_one() { # intake_one 경로 : 작업 파일 하나를 규칙대로 받아 실행해요
  local src="$1" name id dst copy
  name=$(basename -- "$src")
  printf '%s' "$name" | grep -Eq '^[0-9a-f-]{36}\.job$' || return 1
  id=${name%.job}
  dst="$JOBS/work/$name"
  mv -- "$src" "$dst" || return 1                       # 같은 파일 시스템 안의 이동이라 원자적이에요
  copy=$(mktemp "$JOBS/work/copy.XXXXXX") || return 1
  if job_copy "$dst" "$copy" && intake_check "$copy" "$id"; then
    rm -f -- "$copy" "$dst"
    if ledger_take "$id"; then run_job; else warn "같은 작업이 이미 있어요: $id"; fi
  else
    rm -f -- "$copy" "$dst"
    reject_job "$id"
  fi
}

intake_all() {
  local f
  for f in "$JOBS"/inbox/*.job; do
    [ -e "$f" ] || continue
    intake_one "$f" || warn "건너뛰었어요: $(basename -- "$f")"
  done
}

main() {
  case "${1:-}" in
    run)
      exec 9>"$LOCK" && flock -w 900 9 || die "잠금을 잡지 못했어요"
      intake_all ;;
    *) die "사용법: agent.sh run" ;;
  esac
}

if [ -z "${DAHAE_SELFTEST:-}" ]; then main "$@"; fi
