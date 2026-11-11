-- no-transaction
-- Admin search (ILIKE %q%) on customer names. Needs pg_trgm (0019).
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS users_name_trgm ON users USING gin (name gin_trgm_ops);
