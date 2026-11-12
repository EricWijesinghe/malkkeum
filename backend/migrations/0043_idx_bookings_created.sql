-- no-transaction
-- Admin 30-day counters filter bookings by created_at.
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS bookings_created_idx ON bookings (created_at);
