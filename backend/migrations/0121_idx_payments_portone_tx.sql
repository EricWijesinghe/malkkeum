-- no-transaction
-- One PortOne payment backs at most one payments row, so it can never pay for two bookings (0120 checks for duplicates first).
-- Legacy dev fakes (`dev:paid` reused across checkouts) are left out; new dev ids are per checkout.
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS payments_portone_tx_uidx ON payments (provider, provider_tx_id) WHERE provider = 'portone' AND provider_tx_id NOT LIKE 'dev:%';
