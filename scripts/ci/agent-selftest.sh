#!/usr/bin/env bash
# Self-test for deploy/agent.sh (the root job runner). Runs in a sandbox: a fake `dahae` records its arguments,
# no Docker, no root. Usage: bash scripts/ci/agent-selftest.sh
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SB=$(mktemp -d)
trap 'rm -rf "$SB"' EXIT
PASS=0 FAIL=0

t()  { if "${@:2}"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL: $1"; fi; }
nt() { if "${@:2}"; then FAIL=$((FAIL + 1)); echo "FAIL (should fail): $1"; else PASS=$((PASS + 1)); fi; }
eq() { [ "$1" = "$2" ] || { echo "   got [$1] want [$2]"; return 1; }; }

# sandbox layout and a fake CLI that only records its arguments and DAHAE_YES
export DAHAE_JOBS="$SB/jobs" DAHAE_HOST_DIR="$SB/host" DAHAE_LOCK="$SB/lock" DAHAE_DIR="$SB"
export DAHAE_CLI="$SB/dahae"
mkdir -p "$DAHAE_JOBS/inbox" "$DAHAE_JOBS/work/done" "$DAHAE_JOBS/status" "$DAHAE_JOBS/public" "$DAHAE_JOBS/out" "$DAHAE_HOST_DIR"
# fake dahae: `update` exits 3 (rolled back) once after `touch $SB/rollback-next`, or 1 after `touch $SB/fail-next`
cat > "$DAHAE_CLI" <<EOF
#!/usr/bin/env bash
printf '%s YES=%s\n' "\$*" "\${DAHAE_YES:-}" >> "$SB/argv.log"
if [ "\$1" = update ] && [ -e "$SB/rollback-next" ]; then rm -f "$SB/rollback-next"; exit 3; fi
if [ "\$1" = update ] && [ -e "$SB/fail-next" ]; then rm -f "$SB/fail-next"; exit 1; fi
exit 0
EOF
printf 'DOMAIN=myshop.co.kr\nCHANNEL=stable\nVERSION=stable\n' > "$DAHAE_DIR/.env"
chmod +x "$DAHAE_CLI"
export DAHAE_JOB_UID="$(id -u)" DAHAE_OWNER_UID="$(id -u)"
# fake docker: records the working folder and argv of every compose call; `logs` prints the file $SB/logs.txt
mkdir -p "$SB/bin"
cat > "$SB/bin/docker" <<EOF
#!/usr/bin/env bash
printf '%s %s\n' "\$PWD" "\$*" >> "$SB/docker.log"
case "\$*" in *" logs "*) cat "$SB/logs.txt" 2>/dev/null || true ;; esac
EOF
chmod +x "$SB/bin/docker"
# fake public-IP lookup and DNS lookups: the server is 203.0.113.7, the domain has one A and one AAAA record
cat > "$SB/bin/curl" <<'EOF'
#!/usr/bin/env bash
echo 203.0.113.7
EOF
cat > "$SB/bin/getent" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  ahostsv4) echo "203.0.113.7  STREAM myshop.co.kr" ;;
  ahostsv6) echo "2001:db8::1  STREAM myshop.co.kr" ;;
esac
EOF
chmod +x "$SB/bin/curl" "$SB/bin/getent"
export PATH="$SB/bin:$PATH"

# shellcheck source=deploy/agent.sh
DAHAE_SELFTEST=1 . "$ROOT/deploy/agent.sh"
set +e

uuid7() { # uuid7 [밀리초]: 시각이 든 UUIDv7 을 만들어요 (기본: 지금)
  local ms="${1:-$(($(date +%s) * 1000))}" hex rnd
  hex=$(printf '%012x' "$ms")
  rnd=$(od -An -N10 -tx1 /dev/urandom | tr -d ' \n')
  printf '%s-%s-7%s-%x%s-%s\n' "${hex:0:8}" "${hex:8:4}" "${rnd:0:3}" $((8 + RANDOM % 4)) "${rnd:3:3}" "${rnd:6:12}"
}
now_ms() { echo $(($(date +%s) * 1000)); }
submit() { printf '%b' "$2" > "$DAHAE_JOBS/inbox/$1.job"; intake_all; } # submit 번호 본문(\n 이스케이프 가능)
state() { sed -n 's/.*"state":"\([a-z_]*\)".*/\1/p' "$DAHAE_JOBS/status/$1.json" 2>/dev/null; }
argv_lines() { [ -f "$SB/argv.log" ] || { echo 0; return; }; wc -l < "$SB/argv.log" | tr -d ' '; }
argv_has() { grep -qxF "$1" "$SB/argv.log" 2>/dev/null; }
# refuse 번호 본문 : 아무것도 실행되지 않고 상태가 rejected 가 되면 성공(거부됨)
refuse() {
  local before; before=$(argv_lines)
  submit "$1" "$2"
  [ "$(argv_lines)" = "$before" ] && [ "$(state "$1")" = rejected ]
}

# ---- UUIDv7 time window ----
id=$(uuid7)
t  "fresh id passes"           id_fresh "$id"
nt "old id (16 min) refused"   id_fresh "$(uuid7 $(( $(now_ms) - 960000 )))"
nt "future id refused"         id_fresh "$(uuid7 $(( $(now_ms) + 60000 )))"
nt "v4 id refused"             id_fresh "$(printf '%s' "$id" | sed 's/^\(.\{14\}\)7/\14/')"  # 14번째 글자가 버전

# ---- happy path: the fixed argv, step lines only, state ok ----
id=$(uuid7)
submit "$id" "id=$id\nkind=backup-now\n"
t  "backup-now runs dahae backup"  argv_has "backup YES=1"
t  "job state ok"                  eq "$(state "$id")" ok
t  "status log holds step lines only" test -z "$(grep -vE '^(▶|✔|✘|!) ' "$DAHAE_JOBS/status/$id.log")"
t  "moved job file is removed"     test ! -e "$DAHAE_JOBS/work/$id.job"

id=$(uuid7); submit "$id" "id=$id\nkind=channel\narg=beta\n"
t  "channel beta"                  argv_has "channel beta YES=1"
id=$(uuid7); submit "$id" "id=$id\nkind=update-skip\n"
t  "update-skip writes marker"     test -e "$DAHAE_HOST_DIR/skip-next-update"
id=$(uuid7); submit "$id" "id=$id\nkind=status-refresh\n"
t  "status-refresh writes host.json" grep -q '"checked"' "$DAHAE_HOST_DIR/host.json"
id=$(uuid7); submit "$id" "id=$id\nkind=update\n"
t  "update runs dahae update"       argv_has "update YES=1"
id=$(uuid7); submit "$id" "id=$id\nkind=restart\narg=api\n"
t  "restart api runs compose argv" grep -q ' compose --env-file .env restart api$' "$SB/docker.log"
id=$(uuid7); submit "$id" "id=$id\nkind=restart\narg=all\n"
t  "restart all runs compose argv" grep -q ' compose --env-file .env restart$' "$SB/docker.log"

# ---- replay: the same id is never run twice, and the old ok state stays ----
before=$(argv_lines)
submit "$id" "id=$id\nkind=status-refresh\n"
t  "replayed id not re-run"        eq "$(argv_lines)" "$before"
t  "replay keeps old state"        eq "$(state "$id")" ok

# ---- refusals: nothing runs, state rejected ----
id=$(uuid7); t  "unknown key refused"              refuse "$id" "id=$id\nkind=backup-now\nextra=1\n"
id=$(uuid7); t  "unknown kind (restore) refused"   refuse "$id" "id=$id\nkind=restore\narg=x.sql.gz\n"
id=$(uuid7); t  "shell in channel arg refused"     refuse "$id" "id=$id\nkind=channel\narg=beta;rm\n"
id=$(uuid7); t  "backslash in value refused"       refuse "$id" "id=$id\nkind=restart\narg=api\\\\\n"
id=$(uuid7); t  "CR in value refused"              refuse "$id" "id=$id\r\nkind=backup-now\r\n"
id=$(uuid7); t  "duplicate key refused"            refuse "$id" "id=$id\nkind=backup-now\nkind=update\n"
id=$(uuid7); t  "value with = refused"             refuse "$id" "id=$id\nkind=channel\narg=a=b\n"
id=$(uuid7); t  "restart bad service refused"      refuse "$id" "id=$id\nkind=restart\narg=mysql\n"
id=$(uuid7); t  "job id not matching file name"    refuse "$id" "id=$(uuid7)\nkind=backup-now\n"
id=$(uuid7); t  "oversize job refused"             refuse "$id" "id=$id\nkind=backup-now\narg=$(printf 'x%.0s' $(seq 5000))\n"
old=$(uuid7 $(( $(now_ms) - 960000 )))
t  "stale id (16 min) refused"     refuse "$old" "id=$old\nkind=backup-now\n"
t  "unknown key: rejected state"   eq "$(state "$id")" rejected

# ---- ownership, links and names ----
WRONG=$((DAHAE_JOB_UID + 1))
JOB_UID=$WRONG
id=$(uuid7); t  "wrong owner uid refused"          refuse "$id" "id=$id\nkind=backup-now\n"
JOB_UID=$(id -u)
id=$(uuid7)
printf 'id=%s\nkind=backup-now\n' "$id" > "$DAHAE_JOBS/inbox/not-a-job.txt"
before=$(argv_lines); intake_all
t  "file with a bad name is ignored" eq "$(argv_lines)" "$before"
if ln -s /etc/hostname "$SB/link.job" 2>/dev/null; then
  mv "$SB/link.job" "$DAHAE_JOBS/inbox/$id.job"
  before=$(argv_lines); intake_all
  t  "symlinked job refused"       eq "$(argv_lines)" "$before"
else
  echo "skip: symlink cannot be created here"
fi

# ---- the intake copy is what gets checked ----
src="$SB/copy-src.job"; cp=$(mktemp "$SB/copy.XXXXXX")
id=$(uuid7); printf 'id=%s\nkind=backup-now\n' "$id" > "$src"
t  "a good job is copied"          job_copy "$src" "$cp"
t  "the copy passes the checks"    intake_check "$cp" "$id"
printf 'id=%s\nkind=restore\n' "$id" > "$cp"
nt "a copy with a bad kind is refused" intake_check "$cp" "$id"

# a writer that still holds the moved file changes only the original, never the checked copy
held="$SB/held.job"; moved="$SB/held-moved.job"; cp=$(mktemp "$SB/copy.XXXXXX")
id=$(uuid7); printf 'id=%s\nkind=backup-now\n' "$id" > "$held"
exec 7>>"$held"; mv "$held" "$moved"
t  "held copy is taken"            job_copy "$moved" "$cp"
printf 'id=%s\nkind=restore\n' "$id" >&7; exec 7>&-
t  "copy unaffected by held handle" intake_check "$cp" "$id"
t  "copy still runs backup-now"    eq "$JOB_KIND" backup-now

# ---- status files: a planted link is never followed ----
victim="$SB/victim"; echo keep > "$victim"
id=$(uuid7)
if ln -s "$victim" "$DAHAE_JOBS/status/$id.log" 2>/dev/null; then
  before=$(argv_lines); submit "$id" "id=$id\nkind=backup-now\n"
  t  "planted log link not followed" eq "$(cat "$victim")" keep
  t  "job runs despite planted log"  eq "$(argv_lines)" "$((before + 1))"
  t  "state written past planted log" eq "$(state "$id")" ok
else echo "skip: symlink cannot be created here"; fi
victim2="$SB/victim2"; id=$(uuid7)
if ln -s "$victim2" "$DAHAE_JOBS/status/$id.json" 2>/dev/null; then
  submit "$id" "id=$id\nkind=restore\n"
  t  "dangling link not followed on reject" test ! -e "$victim2"
else echo "skip: symlink cannot be created here"; fi

# ---- root folders: owner and write bits are checked ----
t  "status dir owned by the root owner" dir_ok "$DAHAE_JOBS/status"
OWNER_UID=$((OWNER_UID + 1))
nt "status dir with another owner refused" dir_ok "$DAHAE_JOBS/status"
OWNER_UID=$((OWNER_UID - 1))
chmod 777 "$DAHAE_JOBS/status"
if [ "$(stat -c %a "$DAHAE_JOBS/status")" = 777 ]; then
  nt "group/other writable dir refused" dir_ok "$DAHAE_JOBS/status"
else echo "skip: mode bits cannot be set here"; fi
chmod 755 "$DAHAE_JOBS/status"
t  "all root folders pass" dirs_ok

# ---- a job left in work/ by an earlier run is swept, never run ----
id=$(uuid7); printf 'id=%s\nkind=backup-now\n' "$id" > "$DAHAE_JOBS/work/$id.job"
before=$(argv_lines); sweep_work
t  "stale work job swept"        test ! -e "$DAHAE_JOBS/work/$id.job"
t  "stale work job not run"      eq "$(argv_lines)" "$before"

# ---- schedule kind: only HH:MM on a weekday, or off ----
id=$(uuid7); submit "$id" "id=$id\nkind=schedule\narg=mon@04:00\n"
t  "schedule runs update-schedule" argv_has "update-schedule mon@04:00 YES=1"
id=$(uuid7); submit "$id" "id=$id\nkind=schedule\narg=off\n"
t  "schedule off accepted"         argv_has "update-schedule off YES=1"

# ---- outcomes of update: a reverted update is rolled_back, a failed one is failed ----
touch "$SB/rollback-next"
id=$(uuid7); submit "$id" "id=$id\nkind=update\n"
t  "reverted update ends rolled_back" eq "$(state "$id")" rolled_back
touch "$SB/fail-next"
id=$(uuid7); submit "$id" "id=$id\nkind=update\n"
t  "failed update ends failed"        eq "$(state "$id")" failed

# ---- public progress: the token names the file, it holds the state only, and it goes 10 minutes after the end ----
tok=0123456789abcdef0123456789abcdef
id=$(uuid7); submit "$id" "id=$id\nkind=backup-now\ntoken=$tok\n"
t  "progress file holds the state" grep -qx '{"state":"ok"}' "$DAHAE_JOBS/public/$tok.json"
old=ffffffffffffffffffffffffffffffff
printf '{"state":"ok"}\n' > "$DAHAE_JOBS/public/$old.json"; touch -d '20 minutes ago' "$DAHAE_JOBS/public/$old.json"
printf '{"state":"ok"}\n' > "$DAHAE_JOBS/public/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.json"
prune_old
t  "old progress file removed"  test ! -e "$DAHAE_JOBS/public/$old.json"
t  "fresh progress file kept"   test -e "$DAHAE_JOBS/public/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.json"

# ---- a job that was running when the server stopped is failed on the next start ----
id=$(uuid7); printf '{"id":"%s","kind":"backup-now","state":"running"}\n' "$id" > "$DAHAE_JOBS/status/$id.json"
recover_interrupted
t  "interrupted job marked failed" eq "$(state "$id")" failed
t  "interrupted job logged"        grep -q '중단됨' "$DAHAE_JOBS/status/$id.log"

# ---- old step logs are pruned after 30 days ----
id=$(uuid7); printf '▶ old\n' > "$DAHAE_JOBS/status/$id.log"; touch -d '40 days ago' "$DAHAE_JOBS/status/$id.log"
prune_old
t  "40-day-old step log removed" test ! -e "$DAHAE_JOBS/status/$id.log"

# ---- host.json: channel, version, required CLI revision, next automatic update ----
host_refresh
t  "host.json has channel"        grep -q '"channel":"stable"' "$DAHAE_HOST_DIR/host.json"
t  "host.json has min_cli"        grep -q '"min_cli":2' "$DAHAE_HOST_DIR/host.json"
t  "host.json next update set"    grep -q '"next_update":"20' "$DAHAE_HOST_DIR/host.json"
echo off > "$DAHAE_DIR/update-schedule"; host_refresh
t  "host.json next update null when off" grep -q '"next_update":null' "$DAHAE_HOST_DIR/host.json"
rm -f "$DAHAE_DIR/update-schedule"

# ---- server approval (TOTP): update-tag and rollback wait in one slot; a code for that job runs it once ----
SECRET=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ # the RFC 6238 test key ("12345678901234567890")
TOK1=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa TOK2=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
TOK3=cccccccccccccccccccccccccccccccc TOK4=dddddddddddddddddddddddddddddddd
TOK5=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ap() { printf 'code=%s\n' "$2" > "$DAHAE_JOBS/inbox/$1.approve"; intake_all; } # ap 번호 코드 : 승인 파일을 넣고 실행기를 한 번 돌려요
t  "totp RFC 6238 at T=59"          eq "$(totp_at "$SECRET" 59)" 287082
t  "totp RFC 6238 at T=1111111109"  eq "$(totp_at "$SECRET" 1111111109)" 081804
t  "totp RFC 6238 at T=1234567890"  eq "$(totp_at "$SECRET" 1234567890)" 005924
printf 'DOMAIN=myshop.co.kr\nCHANNEL=stable\nVERSION=stable\n' > "$DAHAE_DIR/.env"
id=$(uuid7); id=$(uuid7); t  "no approval key: update-tag refused" refuse "$id" "id=$id\nkind=update-tag\narg=v2.1.0\ntoken=$TOK1\n"
printf '%s\n' "$SECRET" > "$DAHAE_HOST_DIR/approval.key"; chmod 600 "$DAHAE_HOST_DIR/approval.key"
printf 'v2.0.0\n' > "$DAHAE_HOST_DIR/version-history"
id=$(uuid7); t  "older version refused"                refuse "$id" "id=$id\nkind=update-tag\narg=v1.9.0\ntoken=$TOK1\n"
id=$(uuid7); t  "same version refused"                 refuse "$id" "id=$id\nkind=update-tag\narg=v2.0.0\ntoken=$TOK1\n"
id=$(uuid7); t  "beta suffix refused on stable"        refuse "$id" "id=$id\nkind=update-tag\narg=v2.1.0-beta.1\ntoken=$TOK1\n"
id=$(uuid7); t  "update-tag without token refused"     refuse "$id" "id=$id\nkind=update-tag\narg=v2.1.0\n"
id=$(uuid7); t  "rollback without token refused"       refuse "$id" "id=$id\nkind=rollback\n"
printf 'DOMAIN=myshop.co.kr\nCHANNEL=beta\nVERSION=stable\n' > "$DAHAE_DIR/.env"
t  "beta suffix accepted on beta"  tag_ok v2.1.0-beta.1
printf 'DOMAIN=myshop.co.kr\nCHANNEL=stable\nVERSION=stable\n' > "$DAHAE_DIR/.env"

# A: the job waits, a wrong code keeps it waiting, the right code runs it once
id=$(uuid7); before=$(argv_lines)
submit "$id" "id=$id\nkind=update-tag\narg=v2.1.0\ntoken=$TOK1\n"
t  "update-tag waits for approval"        eq "$(state "$id")" awaiting_approval
t  "approval slot holds the job"          grep -qxF "id=$id" "$HOST_DIR/awaiting.job"
t  "summary is written for the console"   grep -q '"summary":"업데이트: v2.1.0' "$DAHAE_JOBS/public/$TOK1.json"
t  "nothing ran while waiting"            eq "$(argv_lines)" "$before"
id2=$(uuid7); submit "$id2" "id=$id2\nkind=rollback\ntoken=$TOK2\n"
t  "second high-impact job refused while one waits" eq "$(state "$id2")" rejected
ap "$id" 000000
t  "wrong code keeps the slot"            test -e "$HOST_DIR/awaiting.job"
t  "wrong code runs nothing"              eq "$(argv_lines)" "$before"
good=$(totp_at "$SECRET" "$(date +%s)")
ap "$(uuid7)" "$good"
t  "code for a job not in the slot ignored" test -e "$HOST_DIR/awaiting.job"
ap "$id" "$good"
t  "right code runs update v2.1.0"        argv_has "update v2.1.0 YES=1"
t  "approved job ends ok"                 eq "$(state "$id")" ok
t  "slot is empty after approval"         test ! -e "$HOST_DIR/awaiting.job"
t  "version history records v2.1.0"       grep -qx v2.1.0 "$HOST_DIR/version-history"
nt "downgrade after approval refused"     tag_newer v2.0.0

# B: the same code is never accepted twice; five wrong codes cancel the job
id2=$(uuid7); submit "$id2" "id=$id2\nkind=rollback\ntoken=$TOK2\n"
t  "rollback waits for approval"          eq "$(state "$id2")" awaiting_approval
before=$(argv_lines)
ap "$id2" "$good"
t  "reused code refused"                  eq "$(argv_lines)" "$before"
t  "reused code keeps the slot"           test -e "$HOST_DIR/awaiting.job"
for w in 000001 000002 000003 000004; do ap "$id2" "$w"; done
t  "five wrong codes cancel the job"      eq "$(state "$id2")" cancelled
t  "cancel empties the slot"              test ! -e "$HOST_DIR/awaiting.job"

# C: an unanswered job expires after its time is up
id3=$(uuid7); submit "$id3" "id=$id3\nkind=rollback\ntoken=$TOK3\n"
printf 'expires=1\ntries=0\n' > "$HOST_DIR/awaiting.meta"
expire_slot
t  "expired job is cancelled"             eq "$(state "$id3")" cancelled
t  "expiry empties the slot"              test ! -e "$HOST_DIR/awaiting.job"

# D: a fresh code runs rollback; the fixed argv is the only thing that runs
printf '0\n' > "$HOST_DIR/approval.last-step"
id4=$(uuid7); submit "$id4" "id=$id4\nkind=rollback\ntoken=$TOK4\n"
good=$(totp_at "$SECRET" "$(date +%s)")
ap "$id4" "$good"
t  "approved rollback runs rollback"      argv_has "rollback YES=1"
t  "approved rollback ends ok"            eq "$(state "$id4")" ok
t  "rollback result shown publicly"      grep -q '"state":"ok"' "$DAHAE_JOBS/public/$TOK4.json"

# ---- results written to out/<token>: logs are masked, read-only folders, 10 minutes ----
cat > "$SB/logs.txt" <<'LOG'
GET /admin Authorization: Bearer abc.def-ghi
session eyJhbGciOi.eyJzdWIiOiIxIn0.sig1234
DATA_KEY=supersecretvalue
db postgres://app:hunter2@db:5432/cleaning
{"token":"tokenvalue123","name":"kim"}
setup code ABCD-EFGH-JKMN
GET /health 200
LOG
id=$(uuid7); submit "$id" "id=$id\nkind=logs\narg=api:200\ntoken=$TOK5\n"
t  "logs result written to out/"          test -f "$DAHAE_JOBS/out/$TOK5"
t  "logs keep ordinary lines"             grep -q 'GET /health 200' "$DAHAE_JOBS/out/$TOK5"
nt "logs hide the bearer token"           grep -q 'abc.def-ghi' "$DAHAE_JOBS/out/$TOK5"
nt "logs hide the session token"          grep -q 'sig1234' "$DAHAE_JOBS/out/$TOK5"
nt "logs hide the key value"              grep -q 'supersecretvalue' "$DAHAE_JOBS/out/$TOK5"
nt "logs hide the database password"      grep -q 'hunter2' "$DAHAE_JOBS/out/$TOK5"
nt "logs hide the json token"             grep -q 'tokenvalue123' "$DAHAE_JOBS/out/$TOK5"
nt "logs hide the setup code"             grep -q 'ABCD-EFGH-JKMN' "$DAHAE_JOBS/out/$TOK5"
t  "logs run compose logs for api"        grep -q ' compose --env-file .env logs --no-color --tail 200 api$' "$SB/docker.log"
id=$(uuid7); submit "$id" "id=$id\nkind=logs\narg=api:10\ntoken=$TOK5\n"
t  "logs line count under 50 refused"     eq "$(state "$id")" rejected
touch -d '20 minutes ago' "$DAHAE_JOBS/out/$TOK5"; prune_old
t  "result file gone after 10 minutes"    test ! -e "$DAHAE_JOBS/out/$TOK5"

# domain-check: the server asks for its own IP; the answer is the A and AAAA records
id=$(uuid7); submit "$id" "id=$id\nkind=domain-check\narg=myshop.co.kr\ntoken=$TOK5\n"
t  "domain-check reports a match"         grep -q '"match":true' "$DAHAE_JOBS/out/$TOK5"
t  "domain-check reports the server IP"   grep -q '"server_ip":"203.0.113.7"' "$DAHAE_JOBS/out/$TOK5"
t  "domain-check lists the AAAA record"   grep -q '"aaaa":\["2001:db8::1"\]' "$DAHAE_JOBS/out/$TOK5"
id=$(uuid7); t  "domain-check takes a domain only" refuse "$id" "id=$id\nkind=domain-check\narg=localhost\ntoken=$TOK5\n"

# offsite-list, heartbeat
id=$(uuid7); submit "$id" "id=$id\nkind=offsite-list\ntoken=$TOK5\n"
t  "offsite-list runs restore-offsite"    argv_has "restore-offsite YES=1"
id=$(uuid7); submit "$id" "id=$id\nkind=heartbeat\narg=https://hc-ping.com/abc-123\n"
t  "heartbeat sets the ping address"      argv_has "heartbeat https://hc-ping.com/abc-123 YES=1"
id=$(uuid7); submit "$id" "id=$id\nkind=heartbeat\narg=off\n"
t  "heartbeat off"                        argv_has "heartbeat off YES=1"
id=$(uuid7); t  "heartbeat http refused"  refuse "$id" "id=$id\nkind=heartbeat\narg=http://hc-ping.com/x\n"

# out/ is a root folder: a group-writable one is refused
chmod 777 "$DAHAE_JOBS/out"
if [ "$(stat -c %a "$DAHAE_JOBS/out")" = 777 ]; then nt "writable out/ refused" dirs_ok; else echo "skip: mode bits cannot be set here"; fi
chmod 755 "$DAHAE_JOBS/out"
expire_slot; clear_slot

# ---- shared fixtures (deploy/testdata/jobs/cases.txt): the same files the installer and the Rust tests read ----
FIX="$ROOT/deploy/testdata/jobs"
while read -r file want rest <&3; do
  case "$file" in ''|\#*) continue ;; esac
  id=$(uuid7); old=$(uuid7 $(( $(now_ms) - 960000 ))); fut=$(uuid7 $(( $(now_ms) + 60000 )))
  case "$(cat "$FIX/$file")" in *@OLD@*) name=$old ;; *@FUTURE@*) name=$fut ;; *) name=$id ;; esac
  sed -e "s/@ID@/$id/g" -e "s/@OLD@/$old/g" -e "s/@FUTURE@/$fut/g" "$FIX/$file" > "$DAHAE_JOBS/inbox/$name.job"
  before=$(argv_lines); intake_all
  if [ "$want" = refuse ]; then
    t  "fixture $file refused"  eq "$(argv_lines)" "$before"
    t  "fixture $file rejected" eq "$(state "$name")" rejected
  else
    t  "fixture $file runs: $rest" eq "$(tail -n1 "$SB/argv.log")" "$rest"
  fi
done 3< "$FIX/cases.txt"

echo "agent self-test: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
