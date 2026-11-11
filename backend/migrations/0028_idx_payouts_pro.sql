-- no-transaction
-- Partner payout history, and FK support for payouts.pro_id.
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS payouts_pro_idx ON payouts (pro_id, created_at DESC);
