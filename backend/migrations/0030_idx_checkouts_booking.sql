-- no-transaction
-- FK support for checkouts.booking_id (checkouts are looked up by booking on refunds).
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS checkouts_booking_idx ON checkouts (booking_id) WHERE booking_id IS NOT NULL;
