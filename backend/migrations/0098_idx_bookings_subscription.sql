-- no-transaction
-- Bookings of a subscription (FK support for bookings.subscription_id, added in 0066).
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS bookings_subscription_idx ON bookings (subscription_id) WHERE subscription_id IS NOT NULL;
