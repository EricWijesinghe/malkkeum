#!/usr/bin/env bash
# Runs one heavy command (cargo / flutter build or test) in one of 2 shared build slots, so parallel
# Malkkeum work never overloads this PC (another project shares it). Waits while free commit
# charge is under 6 GB. Usage:  scripts/build-slot.sh cargo test -p api
set -uo pipefail
LOCKS=D:/Temp/malkkeum-locks
SLOTS=2
MIN_FREE_KB=$((6 * 1024 * 1024))
export CARGO_BUILD_JOBS=2
# Each git worktree gets its own cargo target so branches never link each other's builds.
top=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
case "$top" in
  /f/EC|F:/EC) ;;
  *) export CARGO_TARGET_DIR="F:/EC/targets/$(basename "$top")" ;;
esac
mkdir -p "$LOCKS"

free_commit_kb() {
  powershell.exe -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreeVirtualMemory" 2>/dev/null | tr -dc '0-9'
}

slot=""
while [ -z "$slot" ]; do
  for i in $(seq 1 $SLOTS); do
    d="$LOCKS/slot$i"
    # A slot whose owner died is freed (owner pid stored inside).
    if [ -d "$d" ] && ! kill -0 "$(cat "$d/pid" 2>/dev/null || echo 0)" 2>/dev/null; then rm -rf "$d"; fi
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
