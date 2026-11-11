-- no-transaction
-- Customer chat inbox: threads by user, newest first.
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS chat_threads_user_inbox_idx ON chat_threads (audience, user_id, last_message_at DESC);
