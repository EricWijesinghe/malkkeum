#!/usr/bin/env bash
# 다해 서버 작업 실행기. root 로 돌고, systemd 가 jobs/inbox 에 작업 파일이 생기면 깨워요 (1분마다도 한 번 봐요).
# 작업 파일은 API 컨테이너가 써요. 이 파일은 정해진 명령만 실행하고, 파일 내용을 셸로 해석하지 않아요.
#   사용법: agent.sh run   (dahae-agent.service 가 불러요)
# 작업 파일 형식: id=<UUIDv7>, kind=<종류>, arg=<값>, token=<32자리 16진수, 선택> 줄만 허용해요. 그 밖의 줄·키·중복은 거부해요.
# 승인이 필요한 작업(update-tag, rollback)은 승인 칸(host/awaiting.job)에 하나만 두고, 서버 승인 코드(<id>.approve)가 맞을 때만 실행해요.
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
OUT_KEEP_MIN=10                     # 결과 파일(out/)도 10분만 남아요
STATUS_KEEP_DAYS=30                 # 상태·단계 기록은 30일 보관해요
LEDGER_KEEP_MIN=1440                # 작업 번호 기록은 하루 보관해요 (15분 창 밖이라 안전해요)
RC_ROLLED_BACK=3                    # dahae update 가 이전 버전으로 되돌렸을 때의 종료 코드
MIN_CLI_REV=2                       # host.json 에 적는, 이 실행기가 요구하는 관리 명령의 최소 판
SCHEDULE_RE='^(off|(mon|tue|wed|thu|fri|sat|sun)@([01][0-9]|2[0-3]):[0-5][0-9])$'
HB_URL_RE='^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[A-Za-z0-9._~%/:@+=?-]*)?$'   # install.sh 와 같은 규칙
DOMAIN_RE='^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+([a-z]{2,63}|xn--[a-z0-9-]{1,59})$'
IP_CHARS_RE='^[0-9A-Fa-f:.]{3,45}$'
APPROVAL_KEY="$HOST_DIR/approval.key"
APPROVAL_STEP="$HOST_DIR/approval.last-step"
SLOT_JOB="$HOST_DIR/awaiting.job"
SLOT_META="$HOST_DIR/awaiting.meta"
APPROVAL_TTL_SEC=600                # 승인 칸의 작업은 10분 안에 승인해야 해요
APPROVAL_MAX_TRIES=5                # 승인 코드를 이만큼 틀리면 그 작업을 취소해요
APPROVE_MAX_BYTES=64
APPROVAL_FAILS="$HOST_DIR/approval.fails"   # 틀린 승인 코드의 시각 기록 (한 줄에 한 번)
APPROVAL_FAIL_MAX=10                # 한 시간 안에 이만큼 틀리면 승인을 잠가요 (owner-reset 이나 1시간 뒤에 풀려요)
APPROVAL_FAIL_WINDOW_SEC=3600
OWNER_FILE="$HOST_DIR/owner.json"   # 승인 코드를 만든 사장님 계정 번호
LOG_MIN_LINES=50
LOG_MAX_LINES=2000

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
copy_small() { # copy_small 파일 사본 최대바이트 : 일반 파일과 주인을 확인하고, 한 번만 읽어 사본을 만들어요
  local f="$1" c="$2" max="$3" uid size
  [ ! -L "$f" ] && [ -f "$f" ] || return 1
  uid=$(stat -c %u -- "$f") && size=$(stat -c %s -- "$f") || return 1
  [ "$uid" = "$JOB_UID" ] && [ "$size" -le "$max" ] || return 1
  head -c $((max + 1)) "$f" > "$c" || return 1
  [ "$(stat -c %s -- "$c")" -le "$max" ]
}

job_copy() { copy_small "$1" "$2" "$MAX_JOB_BYTES"; } # job_copy 작업파일 사본 : 작업 파일의 사본을 만들어요

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

env_val() { # env_val 키 : .env 의 값을 읽어요 (source 하지 않아요). 없으면 빈 값
  { grep -E "^$1=" "$DIR/.env" 2>/dev/null || true; } | tail -n1 | cut -d= -f2-
}

is_high_kind() { case "$1" in update-tag|rollback) return 0 ;; *) return 1 ;; esac; } # 서버 승인이 필요한 종류

tag_ok() { # 정식 채널은 vX.Y.Z 만 받아요. 베타 채널만 -접미사를 받아요
  printf '%s' "$1" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' && return 0
  [ "$(env_val CHANNEL)" = beta ] && printf '%s' "$1" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+-[0-9A-Za-z.]{1,40}$'
}

ver_key() { # ver_key 태그 : 정렬 키 (같은 번호에서는 정식판이 베타보다 높아요: v2.1.0 > v2.1.0-beta.1)
  case "$1" in *-*) printf '%s\t0%s\n' "${1%%-*}" "${1#*-}" ;; *) printf '%s\t1\n' "$1" ;; esac
}

tag_newer() { # 설치 기록의 가장 높은 버전보다 높아야 해요. 기록이 없으면 현재 버전을 몰라서 거부해요 (낮추기 금지)
  local hist top new
  hist=$(grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]{1,40})?$' -- "$HOST_DIR/version-history" 2>/dev/null) || return 1
  top=$(while IFS= read -r v; do ver_key "$v"; done <<< "$hist" | sort -V | tail -n1)
  new=$(ver_key "$1")
  [ "$new" != "$top" ] && [ "$(printf '%s\n%s\n' "$top" "$new" | sort -V | tail -n1)" = "$new" ]
}

private_ipv4() { # 사설·루프백·링크 로컬·예약 주소이면 성공해요
  case "$1" in
    0.*|10.*|127.*|169.254.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[01].*) return 0 ;;
    100.6[4-9].*|100.[7-9][0-9].*|100.1[01][0-9].*|100.12[0-7].*) return 0 ;; # 100.64.0.0/10 (공유 주소)
    22[4-9].*|23[0-9].*|24[0-9].*|25[0-5].*) return 0 ;;                       # 멀티캐스트·예약
  esac
  return 1
}

public_host_ok() { # public_host_ok 호스트 : 점이 있는 공개 이름이고, 풀린 모든 주소가 공개 주소여야 해요
  local h="$1" ips ip
  printf '%s' "$h" | grep -Eq '^([A-Za-z0-9-]+\.)+[A-Za-z]{2,63}$' || return 1
  ips=$(getent ahostsv4 "$h" 2>/dev/null | awk '{ print $1 }' | sort -u) || return 1
  [ -n "$ips" ] || return 1
  while IFS= read -r ip; do
    printf '%s' "$ip" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || return 1
    private_ipv4 "$ip" && return 1
  done <<< "$ips"
  return 0
}

heartbeat_url_ok() { # heartbeat_url_ok 주소 : https 이고 공개 이름이어야 해요 (이 서버의 내부 주소·IP 는 안 돼요)
  local host
  printf '%s' "$1" | grep -Eq "$HB_URL_RE" || return 1
  host=${1#https://}; host=${host%%[:/]*}
  public_host_ok "$host"
}

log_arg_ok() { # 로그 값은 서비스:줄 수 (api|web|db, 50~2000 줄)
  local n
  printf '%s' "$JOB_ARG" | grep -Eq '^(api|web|db):[0-9]{2,4}$' || return 1
  n=${JOB_ARG#*:}
  [ "$n" -ge "$LOG_MIN_LINES" ] && [ "$n" -le "$LOG_MAX_LINES" ]
}

job_args_ok() { # 종류와 값의 짝이 맞아야 해요. 목록에 없는 종류는 이 실행기에서 돌리지 않아요
  case "$JOB_KIND" in
    logs|offsite-list|domain-check|update-tag|rollback|host-approval-enroll) [ -n "$JOB_TOKEN" ] || return 1 ;; # 결과·요약을 공개 파일로 남기려면 토큰이 있어야 해요
  esac
  case "$JOB_KIND" in
    status-refresh|backup-now|update|update-skip|offsite-list|rollback) [ -z "$JOB_ARG" ] ;;
    update-tag) tag_ok "$JOB_ARG" && tag_newer "$JOB_ARG" ;;
    logs) log_arg_ok ;;
    domain-check) printf '%s' "$JOB_ARG" | grep -Eq "$DOMAIN_RE" ;;
    heartbeat) [ "$JOB_ARG" = off ] || heartbeat_url_ok "$JOB_ARG" ;;
    host-approval-enroll) printf '%s' "$JOB_ARG" | grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' ;;
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

# ---- 서버 승인 (TOTP, RFC 6238: HMAC-SHA1, 30초, 6자리) ----
totp_at() { # totp_at 비밀(base32) 시각(초) : 그 시각의 6자리 코드. 비밀은 표준 입력으로만 받아요 (명령 줄 인자에 두지 않아요)
  printf '%s' "$1" | python3 -c '
import base64, hashlib, hmac, struct, sys
key = base64.b32decode(sys.stdin.read().strip())
mac = hmac.new(key, struct.pack(">Q", int(sys.argv[1]) // 30), hashlib.sha1).digest()
off = mac[-1] & 15
print("%06d" % ((struct.unpack(">I", mac[off:off + 4])[0] & 0x7fffffff) % 1000000))
' "$2" 2>/dev/null
}

approval_secret() { # 서버 승인 비밀(base32 32자리). 없거나 모양이 다르면 빈 값
  local s
  [ -f "$APPROVAL_KEY" ] && [ ! -L "$APPROVAL_KEY" ] || return 0
  s=$(head -n1 -- "$APPROVAL_KEY")
  printf '%s' "$s" | grep -Eq '^[A-Z2-7]{32}$' && printf '%s' "$s"
  return 0
}

last_step() { # 마지막으로 받은 승인 단계 (없으면 0)
  local v
  v=$(head -n1 -- "$APPROVAL_STEP" 2>/dev/null || true)
  case "$v" in ''|*[!0-9]*) echo 0 ;; *) echo "$v" ;; esac
}

verify_code() { # verify_code 코드 : 앞뒤 한 단계 안에서 맞는 코드를 찾고, 쓴 단계는 기록해 다시 받지 않아요
  local code="$1" key now step last s
  key=$(approval_secret); [ -n "$key" ] || return 1
  now=$(date +%s); step=$((now / 30)); last=$(last_step)
  for s in $((step - 1)) "$step" $((step + 1)); do
    [ "$s" -gt "$last" ] || continue
    [ "$(totp_at "$key" $((s * 30)))" = "$code" ] || continue
    write_file "$APPROVAL_STEP" "$s" || return 1
    return 0
  done
  return 1
}

slot_is() { grep -qxF "id=$1" -- "$SLOT_JOB" 2>/dev/null; } # 승인 칸의 작업 번호가 이 번호인가

slot_field() { # slot_field 이름 : 승인 칸 기록의 숫자 값 (없으면 0)
  local v
  v=$(sed -n "s/^$1=\([0-9]\{1,12\}\)\$/\1/p" "$SLOT_META" 2>/dev/null | head -n1)
  printf '%s' "${v:-0}"
}

clear_slot() { rm -f -- "$SLOT_JOB" "$SLOT_META"; }

cancel_slot() { # cancel_slot 이유 : 승인 칸의 작업을 취소로 남기고 칸을 비워요
  local reason="$1"
  if ! job_parse "$SLOT_JOB"; then clear_slot; return 0; fi
  say_step "!" "$reason"
  set_state cancelled || warn "취소 상태를 못 남겼어요"
  clear_slot
}

expire_slot() { # 승인 시간이 지난 작업은 취소해요 (실행기가 돌 때마다 봐요)
  [ -e "$SLOT_JOB" ] || return 0
  if [ "$(date +%s)" -ge "$(slot_field expires)" ]; then cancel_slot "승인 시간(10분)이 지나서 취소했어요"; fi
  return 0
}

summary_for() { # 서버가 직접 쓰는 요약 (값은 이미 검사를 통과한 것만 들어가요)
  case "$1" in
    update-tag) printf '업데이트: %s 버전으로 바꿔요 (먼저 백업해요)' "$2" ;;
    rollback) printf '이전 버전으로 되돌려요 (데이터는 그대로예요)' ;;
  esac
}

hold_for_approval() { # hold_for_approval 사본 : 승인 칸에 하나만 두고, 서버가 쓴 요약을 공개 파일에 남겨요
  local copy="$1"
  [ -n "$(approval_secret)" ] || { rm -f -- "$copy"; warn "서버 승인 코드가 없어요"; reject_job "$JOB_ID"; return 1; }
  approval_locked && { rm -f -- "$copy"; warn "틀린 승인 코드가 많아서 승인이 잠겨 있어요"; reject_job "$JOB_ID"; return 1; }
  [ ! -e "$SLOT_JOB" ] || { rm -f -- "$copy"; reject_job "$JOB_ID"; return 1; } # 승인 칸이 차 있으면 두 번째 작업은 거부해요
  mv -f -- "$copy" "$SLOT_JOB" || { rm -f -- "$copy"; return 1; }
  write_file "$SLOT_META" "$(printf 'expires=%s\ntries=0' $(( $(date +%s) + APPROVAL_TTL_SEC )))" || return 1
  set_state awaiting_approval || warn "승인 대기 상태를 못 남겼어요"
  say_step "!" "서버 승인을 기다려요"
  [ -z "$JOB_TOKEN" ] || write_file "$JOBS/public/$JOB_TOKEN.json" \
    "$(printf '{"state":"awaiting_approval","summary":"%s"}' "$(summary_for "$JOB_KIND" "$JOB_ARG")")" || warn "서버 요약을 못 남겼어요"
}

approval_locked() { # 한 시간 안에 틀린 코드가 많으면 잠가요 (승인도, 새 승인 작업도 받지 않아요). owner-reset 이 기록을 지워요
  local since n
  since=$(( $(date +%s) - APPROVAL_FAIL_WINDOW_SEC ))
  n=$(awk -v s="$since" '$1 + 0 >= s + 0 { n++ } END { print n + 0 }' "$APPROVAL_FAILS" 2>/dev/null || true)
  [ "${n:-0}" -ge "$APPROVAL_FAIL_MAX" ]
}

record_approval_fail() { # 틀린 승인 코드를 기록해요 (지난 한 시간 것만 남겨요). 기록이 안 되면 그 작업을 취소하고 실패해요
  local since
  since=$(( $(date +%s) - APPROVAL_FAIL_WINDOW_SEC ))
  write_file "$APPROVAL_FAILS" "$({ cat -- "$APPROVAL_FAILS" 2>/dev/null || true; date +%s; } | awk -v s="$since" '$1 + 0 >= s + 0')" && return 0
  cancel_slot "승인 실패 기록을 못 남겨서 취소했어요"; return 1
}

slot_try_fail() { # 틀린 승인 코드: 여러 번 틀리면 그 작업을 취소해요
  local tries
  record_approval_fail || return 0
  tries=$(( $(slot_field tries) + 1 ))
  if [ "$tries" -ge "$APPROVAL_MAX_TRIES" ]; then
    cancel_slot "승인 코드를 여러 번 틀려서 취소했어요"
  else
    write_file "$SLOT_META" "$(printf 'expires=%s\ntries=%s' "$(slot_field expires)" "$tries")" || warn "승인 기록을 못 남겼어요"
    warn "승인 코드가 맞지 않아요"
  fi
}

approve_run() { # 승인된 작업을 실행해요: 승인 칸의 사본을 다시 검사하고, 칸을 비운 뒤에 실행해요
  if ! { job_parse "$SLOT_JOB" && job_args_ok && token_ok; }; then
    cancel_slot "승인 칸의 작업을 다시 검사하지 못해서 취소했어요"; return 1
  fi
  clear_slot
  run_job
}

approve_one() { # approve_one 경로 : 승인 코드 파일 하나를 받아요. 칸의 작업 번호와 맞고 코드가 맞을 때만 실행해요
  local src="$1" name id copy code lines
  name=$(basename -- "$src")
  printf '%s' "$name" | grep -Eq '^[0-9a-f-]{36}\.approve$' || return 1
  id=${name%.approve}
  copy=$(mktemp "$JOBS/work/copy.XXXXXX") || return 1
  if ! copy_small "$src" "$copy" "$APPROVE_MAX_BYTES"; then rm -f -- "$src" "$copy"; return 1; fi
  rm -f -- "$src"
  if approval_locked; then rm -f -- "$copy"; warn "틀린 승인 코드가 많아서 승인이 잠겨 있어요 (1시간 뒤에 풀려요)"; return 1; fi
  if ! slot_is "$id"; then rm -f -- "$copy"; warn "승인 칸에 없는 작업이에요: $id"; return 1; fi
  code=$(sed -n 's/^code=\([0-9]\{6\}\)$/\1/p' "$copy" | head -n1)
  lines=$(grep -c '' "$copy" || true)
  rm -f -- "$copy"
  if [ "$lines" = 1 ] && [ -n "$code" ] && verify_code "$code"; then
    approve_run
  else
    slot_try_fail
  fi
}

approval_enroll() { # 승인 코드를 처음 한 번만 만들어요 (이미 있으면 실패). 사장님 계정 번호와 인증 앱 주소를 남겨요
  local secret
  [ ! -e "$APPROVAL_KEY" ] && [ ! -L "$APPROVAL_KEY" ] || { warn "이미 서버 승인 코드가 있어요"; return 1; }
  secret=$(head -c 20 /dev/urandom | base32 | tr -d '=\n')
  [ "${#secret}" = 32 ] || return 1
  write_file "$OWNER_FILE" "$(printf '{"staff_id":"%s"}' "$JOB_ARG")" || return 1
  (umask 077; printf '%s\n' "$secret" > "$APPROVAL_KEY") || return 1
  printf 'otpauth://totp/Dahae:server?secret=%s&issuer=Dahae&digits=6&period=30\n' "$secret" | out_publish "$JOB_TOKEN"
}

# ---- 실행 (고정 명령만) ----
run_cli() { # run_cli 인자... : 관리 명령을 --yes 로, 입력 없이, 시간 제한을 걸어 실행해요 (종료 코드를 그대로 돌려줘요)
  local pre=()
  # setsid 는 리눅스 서버에 있어요. 없는 환경(개발 PC 테스트)에서는 생략해요.
  command -v setsid >/dev/null && pre=(setsid)
  DAHAE_YES=1 "${pre[@]}" timeout "$RUN_TIMEOUT" "$CLI" "$@" </dev/null >/dev/null 2>&1
}

cli_out() { # cli_out 인자... : 관리 명령의 표준 출력을 내보내요 (결과 파일로 가요)
  DAHAE_YES=1 timeout "$RUN_TIMEOUT" "$CLI" "$@" </dev/null 2>/dev/null
}

run_compose() { # run_compose 인자... : compose 명령을 설치 폴더에서 실행해요 (출력은 남기지 않아요)
  (cd "$DIR" && timeout "$RUN_TIMEOUT" docker compose --env-file .env "$@") </dev/null >/dev/null 2>&1
}

run_out() { # run_out 인자... : compose 명령을 설치 폴더에서 실행하고 출력을 내보내요
  (cd "$DIR" && timeout "$RUN_TIMEOUT" docker compose --env-file .env "$@") </dev/null 2>/dev/null
}

out_publish() { # out_publish 토큰 : 표준 입력을 out/<토큰> 으로 남겨요 (임시 파일을 거쳐 한 번에 바꿔요)
  local tmp
  tmp=$(mktemp "$JOBS/out/.tmp.XXXXXX") || return 1
  if cat > "$tmp" && chmod 0644 -- "$tmp" && mv -fT -- "$tmp" "$JOBS/out/$1"; then return 0; fi
  rm -f -- "$tmp"; return 1
}

mask_log() { # 로그에서 토큰·비밀번호·접속 주소의 암호·설정 값·설정 코드를 가려요
  sed -E \
    -e 's#(Bearer[[:space:]]+)[A-Za-z0-9._~+=/-]+#\1[가려짐]#g' \
    -e 's#((Basic|Token)[[:space:]]+)[A-Za-z0-9._~+=/-]+#\1[가려짐]#gI' \
    -e 's/((Set-)?Cookie:[[:space:]]*).*/\1[가려짐]/gI' \
    -e 's/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/[가려짐]/g' \
    -e 's/[a-z]+_(sk|ck)_[A-Za-z0-9]+/[가려짐]/g' \
    -e 's#(://[^:/[:space:]]+:)[^@/[:space:]]+@#\1[가려짐]@#g' \
    -e 's/("?(token|secret|password|key)"?[[:space:]]*[:=][[:space:]]*"?)[^"[:space:]}]+/\1[가려짐]/gI' \
    -e 's/([A-Za-z0-9_]*_KEY:)[[:space:]]*.*/\1 [가려짐]/g' \
    -e 's/\b[A-HJ-KM-NP-Z2-9]{4}-[A-HJ-KM-NP-Z2-9]{4}-[A-HJ-KM-NP-Z2-9]{4}\b/[가려짐]/g' \
    -e 's/((setup|code)[^[:space:]]*[[:space:]:=]+)[2-9A-HJ-KM-NP-Z]{12}\b/\1[가려짐]/gI' \
    -e 's/\b01[016-9][0-9]{7,8}\b/[가려짐]/g' \
    -e 's/\b0[0-9]{1,2}[-. ][0-9]{3,4}[-. ][0-9]{4}\b/[가려짐]/g'
}

logs_job() { # 서비스 로그의 끝부분을 가려서 out/<토큰> 에 남겨요
  run_out logs --no-color --tail "${JOB_ARG#*:}" "${JOB_ARG%%:*}" | mask_log | out_publish "$JOB_TOKEN"
}

update_tag() { # 승인 받은 버전 올리기: 성공하면 설치 기록에 남겨 다음부터 낮추지 못하게 해요
  local rc=0
  run_cli update "$JOB_ARG" || rc=$?
  if [ "$rc" = 0 ]; then printf '%s\n' "$JOB_ARG" >> "$HOST_DIR/version-history" || warn "버전 기록을 못 남겼어요"; fi
  return "$rc"
}

server_ip() { # server_ip 4|6 : 이 서버의 공개 IPv4·IPv6 를 두 곳에 물어봐요 (답이 다르면 실패해요)
  local fam="$1" a b
  a=$(curl -fsS -"$fam" --max-time 5 https://api.ipify.org 2>/dev/null) || return 1
  b=$(curl -fsS -"$fam" --max-time 5 https://icanhazip.com 2>/dev/null) || return 1
  [ "$a" = "$b" ] || return 1
  if [ "$fam" = 4 ]; then printf '%s' "$a" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || return 1
  else printf '%s' "$a" | grep -Eq '^[0-9A-Fa-f:]{3,45}$' && printf '%s' "$a" | grep -q ':' || return 1; fi
  printf '%s' "$a"
}

json_list() { awk 'NF { printf "%s\"%s\"", (n++ ? "," : ""), $1 }'; } # 줄마다 값 하나를 JSON 배열 안에 넣어요

domain_check() { # 도메인이 이 서버를 가리키는지 봐요 (서버 IP 는 이 서버가 직접 물어봐요). A 는 이 서버의 IPv4, AAAA 는 없거나 이 서버의 IPv6 이어야 해요
  local ip ip6 a aaaa a_ok=false aaaa_ok=false
  ip=$(server_ip 4) || { warn "서버 IP 를 확인하지 못했어요"; return 1; }
  ip6=$(server_ip 6) || ip6=""   # IPv6 가 없는 서버는 빈 값이에요
  a=$(getent ahostsv4 "$JOB_ARG" 2>/dev/null | awk '{ print $1 }' | grep -E "$IP_CHARS_RE" | sort -u || true)
  aaaa=$(getent ahostsv6 "$JOB_ARG" 2>/dev/null | awk '{ print $1 }' | grep -E "$IP_CHARS_RE" | sort -u || true)
  grep -qxF "$ip" <<< "$a" && a_ok=true
  if [ -z "$aaaa" ]; then aaaa_ok=true
  elif [ -n "$ip6" ] && [ -z "$(grep -vxF "$ip6" <<< "$aaaa" || true)" ]; then aaaa_ok=true; fi
  printf '{"domain":"%s","server_ip":"%s","a":[%s],"aaaa":[%s],"match":%s,"aaaa_ok":%s}\n' \
    "$JOB_ARG" "$ip" "$(json_list <<< "$a")" "$(json_list <<< "$aaaa")" \
    "$([ "$a_ok" = true ] && [ "$aaaa_ok" = true ] && echo true || echo false)" "$aaaa_ok" | out_publish "$JOB_TOKEN"
}

offsite_list() { cli_out restore-offsite | mask_log | out_publish "$JOB_TOKEN"; } # 외부 백업 목록을 out/<토큰> 에 남겨요

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
    update-tag) update_tag ;;
    rollback) run_cli rollback ;;
    # 건너뛰기 표시는 예약 업데이트(dahae auto-update)가 읽고 지워요
    update-skip) : > "$HOST_DIR/skip-next-update" ;;
    channel) run_cli channel "$JOB_ARG" ;;
    schedule) run_cli update-schedule "$JOB_ARG" ;;
    restart)
      if [ "$JOB_ARG" = all ]; then run_compose restart; else run_compose restart "$JOB_ARG"; fi ;;
    heartbeat) run_cli heartbeat "$JOB_ARG" ;;
    logs) logs_job ;;
    offsite-list) offsite_list ;;
    domain-check) domain_check ;;
    host-approval-enroll) approval_enroll ;;
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

dirs_ok() { dir_ok "$HOST_DIR" && dir_ok "$JOBS/status" && dir_ok "$JOBS/work" && dir_ok "$JOBS/work/done" && dir_ok "$JOBS/public" && dir_ok "$JOBS/out"; }

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

prune_old() { # 오래된 기록을 지워요 (상태·단계 30일, 작업 번호 1일, 공개 진행 파일·결과 파일 10분)
  find "$JOBS/status" -maxdepth 1 -type f \( -name '*.json' -o -name '*.log' \) -mtime +"$STATUS_KEEP_DAYS" -delete 2>/dev/null || true
  find "$JOBS/work/done" -maxdepth 1 -type f -mmin +"$LEDGER_KEEP_MIN" -delete 2>/dev/null || true
  find "$JOBS/public" -maxdepth 1 -type f -name '*.json' -mmin +"$PROGRESS_KEEP_MIN" -delete 2>/dev/null || true
  find "$JOBS/out" -maxdepth 1 -type f -mmin +"$OUT_KEEP_MIN" -delete 2>/dev/null || true
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

intake_one() { # intake_one 경로 : 작업 파일 하나를 규칙대로 받아요 (승인이 필요하면 승인 칸에 두고, 아니면 바로 실행해요)
  local src="$1" name id dst copy
  name=$(basename -- "$src")
  printf '%s' "$name" | grep -Eq '^[0-9a-f-]{36}\.job$' || return 1
  id=${name%.job}
  dst="$JOBS/work/$name"
  mv -- "$src" "$dst" || return 1                       # 같은 파일 시스템 안의 이동이라 원자적이에요
  copy=$(mktemp "$JOBS/work/copy.XXXXXX") || return 1
  if job_copy "$dst" "$copy" && intake_check "$copy" "$id"; then
    rm -f -- "$dst"
    if ! ledger_take "$id"; then rm -f -- "$copy"; warn "같은 작업이 이미 있어요: $id"; return 0; fi
    if is_high_kind "$JOB_KIND"; then hold_for_approval "$copy"; return; fi
    rm -f -- "$copy"; run_job
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
  for f in "$JOBS"/inbox/*.approve; do
    [ -e "$f" ] || continue
    approve_one "$f" || warn "건너뛰었어요: $(basename -- "$f")"
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
      expire_slot
      intake_all ;;
    *) die "사용법: agent.sh run" ;;
  esac
}

if [ -z "${DAHAE_SELFTEST:-}" ]; then main "$@"; fi
