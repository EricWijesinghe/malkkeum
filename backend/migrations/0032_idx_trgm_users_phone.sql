-- no-transaction
-- Admin search (LIKE %q%) on customer phones. Needs pg_trgm (0019).
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS users_phone_trgm ON users USING gin (phone gin_trgm_ops);
