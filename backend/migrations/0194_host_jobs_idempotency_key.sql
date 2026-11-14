-- The client's Idempotency-Key for a queued job: one key queues one job, even when the request is retried.
ALTER TABLE host_jobs ADD COLUMN idempotency_key TEXT UNIQUE;
