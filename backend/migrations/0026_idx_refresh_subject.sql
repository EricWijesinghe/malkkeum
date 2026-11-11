-- no-transaction
-- Session revocation (logout everywhere, account deletion) by subject.
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS refresh_tokens_subject_idx ON refresh_tokens (subject) WHERE revoked_at IS NULL;
