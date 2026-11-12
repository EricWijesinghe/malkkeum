#!/usr/bin/env bash
# Backup and restore drill. Dumps a source database the way deploy/install.sh does (pg_dump --clean
# --if-exists, gzip), seals the dump with the app's own offsite encryption (api backup-seal), opens it
# again (api backup-open), restores into a fresh database and compares the row count of every public
# table. Exits 0 only when the bytes survive the round trip and every count matches.
#
# Usage:
#   PG_URL=postgres://postgres:localdev@localhost:5433 SRC_DB=malkkeum_dbaudit DATA_KEY=<64 hex> \
#     bash scripts/ci/backup-drill.sh [path/to/api]
# Needs pg_dump and psql at the server's major version, and a built api binary. Read-only on SRC_DB;
# writes one database named malkkeum_drill_<pid>, dropped on exit.
set -euo pipefail

PG_URL="${PG_URL:?set PG_URL to the server URL without a database name}"
SRC_DB="${SRC_DB:?set SRC_DB to the database to back up}"
: "${DATA_KEY:?set DATA_KEY (64 hex chars, same key as the API)}"
API="${1:-${API:-api}}"
DST_DB="malkkeum_drill_$$"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"; psql "$PG_URL/postgres" -qc "DROP DATABASE IF EXISTS $DST_DB" >/dev/null 2>&1 || true' EXIT

# The api reads its whole config on start, so give it the drill's own URL and a throwaway JWT secret.
export DATABASE_URL="$PG_URL/$SRC_DB"
export JWT_SECRET="${JWT_SECRET:-drill-only-secret-drill-only-secret-0000}"

log() { printf '[drill] %s\n' "$*"; }
fail() { log "FAIL: $*"; exit 1; }

COUNTS_SQL="SELECT table_name, (xpath('/row/c/text()',
  query_to_xml(format('SELECT count(*) AS c FROM %I', table_name), false, true, '')))[1]::text
  FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY 1"

START=$(date +%s)
log "dump $SRC_DB"
pg_dump "$PG_URL/$SRC_DB" --clean --if-exists | gzip > "$WORK/db.sql.gz"

log "seal with the app's offsite key"
"$API" backup-seal "$WORK/db.sql.gz" "$WORK/db.sql.gz.enc" >/dev/null
log "open with the app's offsite key"
"$API" backup-open "$WORK/db.sql.gz.enc" "$WORK/restored.sql.gz" >/dev/null
cmp -s "$WORK/db.sql.gz" "$WORK/restored.sql.gz" || fail "opened file differs from the dump"

log "restore into $DST_DB"
psql "$PG_URL/postgres" -v ON_ERROR_STOP=1 -qc "CREATE DATABASE $DST_DB" >/dev/null
gunzip -c "$WORK/restored.sql.gz" | psql "$PG_URL/$DST_DB" -v ON_ERROR_STOP=1 -q >/dev/null

log "compare row counts"
psql "$PG_URL/$SRC_DB" -At -F ' ' -c "$COUNTS_SQL" > "$WORK/src.counts"
psql "$PG_URL/$DST_DB" -At -F ' ' -c "$COUNTS_SQL" > "$WORK/dst.counts"
diff "$WORK/src.counts" "$WORK/dst.counts" || fail "row counts differ between source and restore"
TOTAL=$(awk '{ s += $2 } END { print s + 0 }' "$WORK/src.counts")
[ "$TOTAL" -gt 0 ] || fail "source has no rows: load demo data first so the drill proves something"

ELAPSED=$(( $(date +%s) - START ))
log "ok: $(wc -l < "$WORK/src.counts") tables, $TOTAL rows restored identically in ${ELAPSED}s"
