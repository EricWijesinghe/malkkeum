-- no-transaction
-- Partner calendar and job lists: bookings by pro and visit date.
-- One CREATE INDEX CONCURRENTLY per file: sqlx sends a file as one simple query, which Postgres runs in an
-- implicit transaction, and CONCURRENTLY refuses to run inside one. If a run dies, the index is left INVALID:
-- DROP INDEX CONCURRENTLY IF EXISTS <name>; then restart the API so the migration runs again.
CREATE INDEX CONCURRENTLY IF NOT EXISTS bookings_pro_visit_idx ON bookings (pro_id, visit_date) WHERE pro_id IS NOT NULL;
