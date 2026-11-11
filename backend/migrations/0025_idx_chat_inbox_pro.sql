-- no-transaction
-- Partner chat inbox: threads by pro, newest first.
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS chat_threads_pro_inbox_idx ON chat_threads (audience, pro_id, last_message_at DESC);
