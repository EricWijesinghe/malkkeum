-- no-transaction
-- Staff activity log: newest first, cursor-paged on (created_at, id).
CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_log_created_idx ON audit_log (created_at DESC, id DESC);
