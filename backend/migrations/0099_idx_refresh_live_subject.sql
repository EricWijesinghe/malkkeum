-- no-transaction
-- Signed-in devices and revocation: live (unrevoked, unrotated) refresh rows by subject (0080).
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS refresh_tokens_live_subject_idx ON refresh_tokens (subject) WHERE revoked_at IS NULL AND rotated_at IS NULL;
