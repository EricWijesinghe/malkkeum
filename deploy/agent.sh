#!/usr/bin/env bash
# 다해 서버 작업 실행기. root 로 돌고, systemd 가 jobs/inbox 에 작업 파일이 생기면 깨워요 (1분마다도 한 번 봐요).
# 작업 파일은 API 컨테이너가 써요. 이 파일은 정해진 명령만 실행하고, 파일 내용을 셸로 해석하지 않아요.
#   사용법: agent.sh run   (dahae-agent.service 가 불러요)
# 작업 파일 형식: id=<UUIDv7>, kind=<종류>, arg=<값>, token=<32자리 16진수, 선택> 줄만 허용해요. 그 밖의 줄·키·중복은 거부해요.
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
JOB_TOKEN=""
MAX_JOB_BYTES=4096
ID_WINDOW_MS=900000                 # 작업 번호(UUIDv7)의 시각은 15분 안이어야 해요
MAX_JOB_LINES=8
PROGRESS_KEEP_MIN=10                # 공개 진행 파일은 작업이 끝난 뒤 10분만 남아요
STATUS_KEEP_DAYS=30                 # 상태·단계 기록은 30일 보관해요
LEDGER_KEEP_MIN=1440                # 작업 번호 기록은 하루 보관해요 (15분 창 밖이라 안전해요)
RC_ROLLED_BACK=3                    # dahae update 가 이전 버전으로 되돌렸을 때의 종료 코드
MIN_CLI_REV=2                       # host.json 에 적는, 이 실행기가 요구하는 관리 명령의 최소 판
SCHEDULE_RE='^(off|(mon|tue|wed|thu|fri|sat|sun)@([01][0-9]|2[0-3]):[0-5][0-9])$'

warn() { printf '! %s\n' "$*" >&2; }
die()  { printf '✘ %s\n' "$*" >&2; exit 1; }

# ---- 상태 기록 (사용자에게 보여요: 단계 줄만, 명령 출력은 남기지 않아요) ----
write_file() { # write_file 경로 내용 : 임시 파일에 쓴 뒤 바꿔요 (이름이 같은 링크는 따르지 않아요)
  local dst="$1" tmp
  tmp=$(mktemp "$(dirname -- "$dst")/.tmp.XXXXXX") || return 1
  if printf '%s\n' "$2" > "$tmp" && chmod 0644 -- "$tmp" && mv -fT -- "$tmp" "$dst"; then
    return 0
  fi
  rm -f -- "$tmp"; return 1
}

say_step() { # say_step 기호 내용 : 단계 줄을 덧붙여요 (기록이 안 돼도 작업은 계속해요)
  local log="$JOBS/status/$JOB_ID.log"
  # shortcut: -L 검사와 쓰기 사이에 틈이 남아요. status/ 가 관리자 소유라야 API 가 링크를 못 만들어요 (dir_ok)
  [ ! -L "$log" ] && printf '%s %s\n' "$1" "$2" >> "$log" || warn "단계 기록을 못 했어요"
}

set_state() { # set_state 상태 : status/<id>.json 을 쓰고, 공개 토큰이 있으면 public/<토큰>.json 에도 상태만 써요
  write_file "$JOBS/status/$JOB_ID.json" "$(printf '{"id":"%s","kind":"%s","state":"%s"}' "$JOB_ID" "$JOB_KIND" "$1")" || return 1
  [ -z "$JOB_TOKEN" ] || write_file "$JOBS/public/$JOB_TOKEN.json" "$(printf '{"state":"%s"}' "$1")" || warn "공개 진행 상태를 못 남겼어요"
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

job_parse() { # job_parse 사본 : key=value 줄만 읽어 JOB_ID·JOB_KIND·JOB_ARG·JOB_TOKEN 에 넣어요 (source·eval 없음)
  local k v n=0 seen=" "
  JOB_ID="" JOB_KIND="" JOB_ARG="" JOB_TOKEN=""
  while IFS='=' read -r k v || [ -n "$k" ]; do
    n=$((n + 1)); [ "$n" -le "$MAX_JOB_LINES" ] || return 1
    case "$v" in *\\*|*$'\r'*|*=*) return 1 ;; esac
    case "$seen" in *" $k "*) return 1 ;; esac
    seen="$seen$k "
    case "$k" in
      id) JOB_ID=$v ;;
      kind) JOB_KIND=$v ;;
      arg) JOB_ARG=$v ;;
      token) JOB_TOKEN=$v ;;
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
    schedule) printf '%s' "$JOB_ARG" | grep -Eq "$SCHEDULE_RE" ;;
    *) return 1 ;;
  esac
}

token_ok() { # 공개 토큰은 없거나, 32자리 16진수여야 해요 (파일 이름으로 쓰여요)
  [ -z "$JOB_TOKEN" ] || printf '%s' "$JOB_TOKEN" | grep -Eq '^[0-9a-f]{32}$'
}

ledger_take() { # ledger_take 번호 : 처음 보는 번호면 기록하고 성공해요. 같은 번호가 또 오면 실패해요 (다시 실행 막기)
  ( set -C; : > "$JOBS/work/done/$1" ) 2>/dev/null
}

# ---- 실행 (고정 명령만) ----
run_cli() { # run_cli 인자... : 관리 명령을 --yes 로, 입력 없이, 시간 제한을 걸어 실행해요 (종료 코드를 그대로 돌려줘요)
  local pre=()
  # setsid 는 리눅스 서버에 있어요. 없는 환경(개발 PC 테스트)에서는 생략해요.
  command -v setsid >/dev/null && pre=(setsid)
  DAHAE_YES=1 "${pre[@]}" timeout "$RUN_TIMEOUT" "$CLI" "$@" </dev/null >/dev/null 2>&1
}

run_compose() { # run_compose 인자... : compose 명령을 설치 폴더에서 실행해요 (출력은 남기지 않아요)
  (cd "$DIR" && timeout "$RUN_TIMEOUT" docker compose --env-file .env "$@") </dev/null >/dev/null 2>&1
}

env_val() { # env_val 키 : .env 의 값을 읽어요 (source 하지 않아요). 없으면 빈 값
  { grep -E "^$1=" "$DIR/.env" 2>/dev/null || true; } | tail -n1 | cut -d= -f2-
}

word_or_unknown() { # 값이 글자·숫자·.-_ 만 아니면 unknown 으로 바꿔요 (host.json 에 그대로 들어가요)
  case "$1" in ''|*[!A-Za-z0-9._-]*) printf 'unknown' ;; *) printf '%s' "$1" ;; esac
}

next_update() { # 다음 자동 업데이트 시각을 JSON 값으로 (예약이 꺼져 있거나 알 수 없으면 null)
  local spec day time d
  spec=$(cat -- "$DIR/update-schedule" 2>/dev/null || echo mon@04:00)
  printf '%s' "$spec" | grep -Eq "$SCHEDULE_RE" || { echo null; return; }
  [ "$spec" != off ] || { echo null; return; }
  day=${spec%@*}; time=${spec#*@}
  d=$(date -d "next $day" +%F 2>/dev/null) || { echo null; return; }
  printf '"%s"' "$(date -d "$d $time" -Iseconds)"
}

host_refresh() { # 호스트 정보 파일(host.json): 확인 시각, 채널, 버전, 필요한 관리 명령 판, 다음 자동 업데이트
  write_file "$HOST_DIR/host.json" "$(printf '{"checked":"%s","channel":"%s","version":"%s","min_cli":%s,"next_update":%s}' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(word_or_unknown "$(env_val CHANNEL)")" "$(word_or_unknown "$(env_val VERSION)")" \
    "$MIN_CLI_REV" "$(next_update)")"
}

dispatch() { # 종류에 맞는 명령 하나만 실행해요. 종료 코드를 그대로 돌려줘요
  case "$JOB_KIND" in
    status-refresh) host_refresh ;;
    backup-now) run_cli backup ;;
    update) run_cli update ;;
    # 건너뛰기 표시는 예약 업데이트(dahae auto-update)가 읽고 지워요
    update-skip) : > "$HOST_DIR/skip-next-update" ;;
    channel) run_cli channel "$JOB_ARG" ;;
    schedule) run_cli update-schedule "$JOB_ARG" ;;
    restart)
      if [ "$JOB_ARG" = all ]; then run_compose restart; else run_compose restart "$JOB_ARG"; fi ;;
  esac
}

run_job() { # 작업 하나를 실행하고 결과(완료·되돌림·실패)를 상태에 남겨요 (잠금 안에서 한 번만 받은 작업이라, 기록이 실패해도 실행해요)
  local rc=0
  JOB_RUNNING=1
  set_state running || warn "진행 상태를 못 남겼어요"
  say_step "▶" "$JOB_KIND"
  if dispatch; then rc=0; else rc=$?; fi
  case "$rc" in
    0) say_step "✔" "완료"; set_state ok || warn "완료 상태를 못 남겼어요" ;;
    "$RC_ROLLED_BACK") say_step "!" "이전 버전으로 되돌렸어요"; set_state rolled_back || warn "되돌림 상태를 못 남겼어요" ;;
    *) say_step "✘" "실패"; set_state failed || warn "실패 상태를 못 남겼어요" ;;
  esac
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

dirs_ok() { dir_ok "$HOST_DIR" && dir_ok "$JOBS/status" && dir_ok "$JOBS/work" && dir_ok "$JOBS/work/done" && dir_ok "$JOBS/public"; }

sweep_work() { # 예전 실행이 중간에 끝나서 남긴 작업 파일과 사본을 치워요 (잠금 안에서만 불러요)
  rm -f -- "$JOBS"/work/*.job "$JOBS"/work/copy.* 2>/dev/null || true
}

recover_interrupted() { # 실행 중에 꺼져서 running 으로 남은 작업은 중단으로 바꿔요 (잠금을 잡은 지금 실행 중인 작업은 없어요)
  local f id
  for f in "$JOBS"/status/*.json; do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    grep -q '"state":"running"' "$f" || continue
    id=$(basename -- "$f" .json)
    write_file "$f" "$(sed 's/"state":"running"/"state":"failed"/' "$f")" || { warn "중단된 작업을 못 고쳤어요: $id"; continue; }
    [ ! -L "$JOBS/status/$id.log" ] && printf '✘ %s\n' "중단됨 (서버가 실행 중에 다시 시작됐어요)" >> "$JOBS/status/$id.log" 2>/dev/null || true
  done
}

prune_old() { # 오래된 기록을 지워요 (상태·단계 30일, 작업 번호 1일, 공개 진행 파일 작업 종료 후 10분)
  find "$JOBS/status" -maxdepth 1 -type f \( -name '*.json' -o -name '*.log' \) -mtime +"$STATUS_KEEP_DAYS" -delete 2>/dev/null || true
  find "$JOBS/work/done" -maxdepth 1 -type f -mmin +"$LEDGER_KEEP_MIN" -delete 2>/dev/null || true
  find "$JOBS/public" -maxdepth 1 -type f -name '*.json' -mmin +"$PROGRESS_KEEP_MIN" -delete 2>/dev/null || true
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
  job_parse "$1" && [ "$JOB_ID" = "$2" ] && job_args_ok && token_ok && id_fresh "$2"
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
      recover_interrupted
      prune_old
      host_refresh || warn "호스트 정보를 못 남겼어요"
      intake_all ;;
    *) die "사용법: agent.sh run" ;;
  esac
}

if [ -z "${DAHAE_SELFTEST:-}" ]; then main "$@"; fi
