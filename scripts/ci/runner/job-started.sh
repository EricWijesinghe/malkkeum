#!/usr/bin/env bash
# Self-hosted runner hook (WSL): wait for the PC's single build slot (shared with scripts/build-slot.sh), then hold it
# with a heartbeat file, so CI never builds at the same time as local work. Released by job-completed.sh.
set -u
d=/mnt/d/Temp/malkkeum-locks/slot1
# Same fair queue as build-slot.sh: a ticket <start-ns>-ci, touched while waiting; only the oldest fresh ticket goes.
Q=/mnt/d/Temp/malkkeum-locks/queue; mkdir -p "$Q"
ticket="$Q/$(date +%s%N)-ci"; : > "$ticket"
head_ticket() {
  local t
  # shellcheck disable=SC2012  # ticket names are digits and a dash
  for t in $(ls "$Q" 2>/dev/null | sort); do
    [ -n "$(find "$Q/$t" -mmin +3 2>/dev/null)" ] && { rm -f "$Q/$t"; continue; }
    echo "$t"; return
  done
}
while :; do
  touch "$ticket"
  if [ "$(head_ticket)" = "$(basename "$ticket")" ]; then
    # A CI holder whose heartbeat stopped (crashed runner) is stale; Windows holders are freed by build-slot.sh itself.
    [ -f "$d/heartbeat" ] && [ -n "$(find "$d/heartbeat" -mmin +3 2>/dev/null)" ] && rm -rf "$d"
    mkdir "$d" 2>/dev/null && break
    sleep 20
  else
    sleep 10
  fi
done
rm -f "$ticket"
touch "$d/heartbeat"
# Heartbeat stops by itself when no job is running (runner killed), so the slot can never stay held.
nohup bash -c "while pgrep -f Runner.Worker >/dev/null && [ -d '$d' ]; do touch '$d/heartbeat'; sleep 60; done" >/dev/null 2>&1 &
echo $! > "$HOME/.malkkeum-slot-hb"
echo "[build-slot] CI job holds slot1"
