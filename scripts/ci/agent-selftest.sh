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
mkdir -p "$DAHAE_JOBS/inbox" "$DAHAE_JOBS/work/done" "$DAHAE_JOBS/status" "$DAHAE_HOST_DIR"
cat > "$DAHAE_CLI" <<EOF
#!/usr/bin/env bash
printf '%s YES=%s\n' "\$*" "\${DAHAE_YES:-}" >> "$SB/argv.log"
EOF
chmod +x "$DAHAE_CLI"
export DAHAE_JOB_UID="$(id -u)" DAHAE_OWNER_UID="$(id -u)"
# fake docker: records the working folder and argv of every compose call
mkdir -p "$SB/bin"
cat > "$SB/bin/docker" <<EOF
#!/usr/bin/env bash
printf '%s %s\n' "\$PWD" "\$*" >> "$SB/docker.log"
EOF
chmod +x "$SB/bin/docker"
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

echo "agent self-test: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
