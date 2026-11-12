#!/usr/bin/env bash
# Self-hosted runner hook (WSL): release the build slot taken by job-started.sh.
hb="$HOME/.malkkeum-slot-hb"
[ -f "$hb" ] && kill "$(cat "$hb")" 2>/dev/null; rm -f "$hb"
d=/mnt/d/Temp/malkkeum-locks/slot1
[ -f "$d/heartbeat" ] && rm -rf "$d"  # only a slot CI holds, never a local build's
echo "[build-slot] CI job released slot1"
