-- no-transaction
-- Admin search (LIKE %q%) on customer phones. Needs pg_trgm (0040).
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS users_phone_trgm ON users USING gin (phone gin_trgm_ops);
