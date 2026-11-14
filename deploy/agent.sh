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
LOCK_WAIT=$((RUN_TIMEOUT + 60))     # 잠금 대기는 작업 하나의 제한 시간보다 길어야 뒤의 작업이 버려지지 않아요
OWNER_UID=${DAHAE_OWNER_UID:-0}     # 상태·작업·호스트 폴더의 주인: 관리자(root)만 쓸 수 있어야 해요
JOB_RUNNING=""
MAX_JOB_BYTES=4096
ID_WINDOW_MS=900000                 # 작업 번호(UUIDv7)의 시각은 15분 안이어야 해요
MAX_JOB_LINES=8

warn() { printf '! %s\n' "$*" >&2; }
die()  { printf '✘ %s\n' "$*" >&2; exit 1; }

# ---- 상태 기록 (사용자에게 보여요: 단계 줄만, 명령 출력은 남기지 않아요) ----
say_step() { # say_step 기호 내용 : 단계 줄을 덧붙여요 (기록이 안 돼도 작업은 계속해요)
  local log="$JOBS/status/$JOB_ID.log"
  # shortcut: -L 검사와 쓰기 사이에 틈이 남아요. status/ 가 관리자 소유라야 API 가 링크를 못 만들어요 (dir_ok)
  [ ! -L "$log" ] && printf '%s %s\n' "$1" "$2" >> "$log" || warn "단계 기록을 못 했어요"
}
set_state() { # set_state 상태 : status/<id>.json 을 임시 파일로 쓴 뒤 바꿔요 (값은 모두 검사한 것만 들어가요)
  local tmp dst="$JOBS/status/$JOB_ID.json"
  tmp=$(mktemp "$JOBS/status/.$JOB_ID.XXXXXX") || return 1   # mktemp 은 기존 이름(링크 포함)을 따르지 않아요
  if printf '{"id":"%s","kind":"%s","state":"%s"}\n' "$JOB_ID" "$JOB_KIND" "$1" > "$tmp" \
     && chmod 0644 -- "$tmp" && mv -fT -- "$tmp" "$dst"; then
    return 0
  fi
  rm -f -- "$tmp"; return 1
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
  local tmp
  tmp=$(mktemp "$HOST_DIR/.host.XXXXXX") || return 1
  if printf '{"checked":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$tmp" \
     && chmod 0644 -- "$tmp" && mv -fT -- "$tmp" "$HOST_DIR/host.json"; then
    return 0
  fi
  rm -f -- "$tmp"; return 1
}

dispatch() { # 종류에 맞는 명령 하나만 실행해요
  case "$JOB_KIND" in
    status-refresh) host_refresh ;;
    backup-now) run_cli backup ;;
    update) run_cli update ;;
    # shortcut: 건너뛰기 표시는 아직 아무도 읽지 않아요. 예약 업데이트 스크립트가 읽도록 붙이기 전까지 효과가 없어요
    update-skip) : > "$HOST_DIR/skip-next-update" ;;
    channel) run_cli channel "$JOB_ARG" ;;
    restart)
      if [ "$JOB_ARG" = all ]; then run_compose restart; else run_compose restart "$JOB_ARG"; fi ;;
  esac
}

run_job() { # 작업 하나를 실행하고 결과를 상태에 남겨요 (잠금 안에서 한 번만 받은 작업이라, 기록이 실패해도 실행해요)
  JOB_RUNNING=1
  set_state running || warn "진행 상태를 못 남겼어요"
  say_step "▶" "$JOB_KIND"
  if dispatch; then
    say_step "✔" "완료"; set_state ok || warn "완료 상태를 못 남겼어요"
  else
    say_step "✘" "실패"; set_state failed || warn "실패 상태를 못 남겼어요"
  fi
  JOB_RUNNING=""
}

abort_job() { # 실행 도중 끝나면(신호 등) 그 작업을 실패로 남겨요
  if [ -n "$JOB_RUNNING" ]; then set_state failed 2>/dev/null || true; fi
}

dir_ok() { # dir_ok 폴더 : 심볼릭 링크가 아니고, 관리자 소유이며, 그룹·다른 사용자가 쓸 수 없어야 해요
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  [ "$(stat -c %u -- "$1")" = "$OWNER_UID" ] || return 1
  [ $((0$(stat -c %a -- "$1") & 022)) -eq 0 ]
}

dirs_ok() { dir_ok "$HOST_DIR" && dir_ok "$JOBS/status" && dir_ok "$JOBS/work" && dir_ok "$JOBS/work/done"; }

sweep_work() { # 예전 실행이 중간에 끝나서 남긴 작업 파일과 사본을 치워요 (잠금 안에서만 불러요)
  rm -f -- "$JOBS"/work/*.job "$JOBS"/work/copy.* 2>/dev/null || true
}

# ---- 흐름 ----
reject_job() { # reject_job 번호 : 검사에 실패한 작업은 상태를 rejected 로 두고 치워요
  local id="$1" dst="$JOBS/status/$1.json"
  # 이미 상태가 있는 번호(예전 작업의 재전송)는 덮어쓰지 않아요. 끊어진 링크도 따라가지 않아요
  if printf '%s' "$id" | grep -Eq '^[0-9a-f-]{36}$' && [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    printf '{"id":"%s","kind":"unknown","state":"rejected"}\n' "$id" > "$dst" || warn "거부 기록을 못 했어요"
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
      trap 'exit 143' TERM INT HUP
      trap abort_job EXIT
      exec 9>"$LOCK" && flock -w "$LOCK_WAIT" 9 || die "잠금을 잡지 못했어요"
      dirs_ok || die "작업 폴더의 주인이나 권한이 안전하지 않아요"
      sweep_work
      intake_all ;;
    *) die "사용법: agent.sh run" ;;
  esac
}

if [ -z "${DAHAE_SELFTEST:-}" ]; then main "$@"; fi
