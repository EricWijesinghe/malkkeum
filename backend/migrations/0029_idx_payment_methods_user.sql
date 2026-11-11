-- no-transaction
-- Saved cards by customer (live cards only). FK support for payment_methods.user_id.
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS payment_methods_user_idx ON payment_methods (user_id) WHERE deleted_at IS NULL;
