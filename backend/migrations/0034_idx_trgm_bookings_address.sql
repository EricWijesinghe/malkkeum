-- no-transaction
-- Admin search (ILIKE %q%) on the road address. Needs pg_trgm (0019).
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS bookings_road_address_trgm ON bookings USING gin ((address->>'road_address') gin_trgm_ops);
