#!/usr/bin/env bash
# Runs one heavy command (cargo / flutter build or test) in the single shared build slot (builds queue one at a time), so parallel
# Malkkeum work never overloads this PC (another project shares it). Waits while free commit
# charge is under 6 GB. Usage:  scripts/build-slot.sh cargo test -p api
set -uo pipefail
LOCKS=D:/Temp/malkkeum-locks
SLOTS=1
MIN_FREE_KB=$((6 * 1024 * 1024))
export CARGO_BUILD_JOBS=2
# Each worktree gets its own cargo target: a shared one mixes up same-named path crates across worktrees (stale artifacts).
top=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
case "$top" in
  /f/EC|F:/EC) ;;
  *) export CARGO_TARGET_DIR="F:/EC/targets/$(basename "$top")" ;;
esac
mkdir -p "$LOCKS"

# Light steps never wait for the slot: code generation, package fetch, formatting.
case "$*" in
  "flutter gen-l10n"*|"flutter pub get"*|"dart pub get"*|"dart format"*|"cargo fmt"*|python*) exec "$@" ;;
esac

free_commit_kb() {
  powershell.exe -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreeVirtualMemory" 2>/dev/null | tr -dc '0-9'
}

slot=""
while [ -z "$slot" ]; do
  for i in $(seq 1 $SLOTS); do
    d="$LOCKS/slot$i"
    # A slot whose owner died is freed (owner pid stored inside).
    # No pid file after a minute means the owner was killed between mkdir and writing it
    # (kill -0 0 would wrongly succeed, so never probe pid 0).
    if [ -d "$d" ]; then
      owner=$(cat "$d/pid" 2>/dev/null)
      if [ -n "$owner" ]; then kill -0 "$owner" 2>/dev/null || rm -rf "$d"
      elif [ -n "$(find "$d" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then rm -rf "$d"; fi
    fi
    if mkdir "$d" 2>/dev/null; then
      echo $$ > "$d/pid"
      f=$(free_commit_kb); f=${f:-0}
      if [ "$f" -ge "$MIN_FREE_KB" ]; then slot="$d"; break; fi
      rm -rf "$d"
    fi
  done
  [ -z "$slot" ] && sleep 20
done
trap 'rm -rf "$slot"' EXIT
echo "[build-slot] $(basename "$slot"): $*" >&2
"$@"
