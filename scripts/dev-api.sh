#!/usr/bin/env bash
# Starts local Postgres (F:) and the API in dev mode. Creates backend/.env on first run.
set -euo pipefail
source "$(dirname "$0")/env.sh"
PG=/f/tools/pgsql/bin
"$PG/pg_isready.exe" -h localhost -p 5433 >/dev/null 2>&1 || "$PG/pg_ctl.exe" -D F:/tools/pgdata -l F:/tools/pgdata/server.log -o "-p 5433" start >/dev/null
ENV=/f/EC/backend/.env
if [ ! -f "$ENV" ]; then
  cat > "$ENV" <<EOV
DATABASE_URL=postgres://postgres:localdev@localhost:5433/cleaning
JWT_SECRET=$(openssl rand -hex 32)
DATA_KEY=$(openssl rand -hex 32)
BIND_ADDR=0.0.0.0:8080
PUBLIC_BASE_URL=http://127.0.0.1:8080
UPLOAD_DIR=F:/EC/backend/data/uploads
DEV_MODE=1
ALLOWED_ORIGINS=http://localhost:5173
SEED_ADMIN_EMAIL=admin@local.test
SEED_ADMIN_PASSWORD=change-me-now-please
EOV
fi
set -a; source "$ENV"; set +a
# Smoke runs ~25 sign-ins from one IP: lift the auth limit for local runs (production keeps 20/min).
export RATE_LIMIT_AUTH_PER_MIN="${RATE_LIMIT_AUTH_PER_MIN:-1000}"
cd /f/EC/backend && exec cargo run -q -p api
