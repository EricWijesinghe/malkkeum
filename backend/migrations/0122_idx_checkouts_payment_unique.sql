-- no-transaction
-- One PortOne payment settles at most one checkout (0120 checks for duplicates first; legacy dev fakes are left out).
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS checkouts_payment_uidx ON checkouts (provider_payment_id) WHERE provider_payment_id IS NOT NULL AND provider_payment_id NOT LIKE 'dev:%';
