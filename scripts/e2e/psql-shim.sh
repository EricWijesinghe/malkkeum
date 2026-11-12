#!/usr/bin/env bash
# Stands in for psql when scripts/smoke.py runs against an installed stack: smoke calls
# `psql -h localhost -p 5433 -U postgres -d cleaning -qc <statement>`; run that statement in the stack's db container.
set -euo pipefail
[ "$(id -u)" = 0 ] || exec sudo "$0" "$@"
cd /opt/malkkeum
exec docker compose --env-file .env exec -T db psql -v ON_ERROR_STOP=1 -U app -d cleaning -qc "${!#}"
