#!/usr/bin/env bash
# Starts local Postgres (port 5433) and the API in dev mode. Creates backend/.env on first run.
# Postgres binaries: PG_BIN (or on PATH); data directory: PGDATA. Both can live in scripts/local.env.
set -euo pipefail
source "$(dirname "$0")/env.sh"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
pg() { if [ -n "${PG_BIN:-}" ]; then "$PG_BIN/$1" "${@:2}"; else "$@"; fi; }
if ! pg pg_isready -h localhost -p 5433 >/dev/null 2>&1; then
  : "${PGDATA:?Postgres is not running on :5433; set PGDATA (scripts/local.env) so it can be started}"
  pg pg_ctl -D "$PGDATA" -l "$PGDATA/server.log" -o "-p 5433" start >/dev/null
fi
ENV="$ROOT/backend/.env"
if [ ! -f "$ENV" ]; then
  cat > "$ENV" <<EOV
DATABASE_URL=postgres://postgres:localdev@localhost:5433/cleaning
JWT_SECRET=$(openssl rand -hex 32)
DATA_KEY=$(openssl rand -hex 32)
BIND_ADDR=0.0.0.0:8080
PUBLIC_BASE_URL=http://127.0.0.1:8080
UPLOAD_DIR=$ROOT/backend/data/uploads
DEV_MODE=1
ALLOWED_ORIGINS=http://localhost:5173
SEED_ADMIN_EMAIL=admin@local.test
SEED_ADMIN_PASSWORD=change-me-now-please
EOV
fi
set -a; source "$ENV"; set +a
# `scripts/dev-api.sh demo load|clear`: sample data in the dev database (DATABASE_URL above), then exit.
if [ "${1:-}" = demo ]; then cd "$ROOT/backend" && exec cargo run -q -p api -- "$@"; fi
# Smoke runs ~25 sign-ins from one IP: lift the auth limit for local runs (production keeps 20/min).
export RATE_LIMIT_AUTH_PER_MIN="${RATE_LIMIT_AUTH_PER_MIN:-1000}"
cd "$ROOT/backend" && exec cargo run -q -p api
