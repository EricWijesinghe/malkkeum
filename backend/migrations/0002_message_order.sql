-- now() is frozen per transaction; messages written together must still sort in insert order.
ALTER TABLE chat_messages ALTER COLUMN created_at SET DEFAULT clock_timestamp();
ALTER TABLE notifications ALTER COLUMN created_at SET DEFAULT clock_timestamp();
