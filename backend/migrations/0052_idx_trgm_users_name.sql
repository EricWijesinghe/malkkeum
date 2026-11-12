-- no-transaction
-- Admin search (ILIKE %q%) on customer names. Needs pg_trgm (0040).
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS users_name_trgm ON users USING gin (name gin_trgm_ops);
