-- no-transaction
-- Admin search (ILIKE %q%) on booking numbers. Needs pg_trgm (0019).
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS bookings_number_trgm ON bookings USING gin (number gin_trgm_ops);
