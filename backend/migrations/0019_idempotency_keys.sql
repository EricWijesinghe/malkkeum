-- Idempotency-Key replay (24h). status/body stay NULL while the first request is still running.
CREATE TABLE idempotency_keys (
    scope        TEXT NOT NULL,
    key          TEXT NOT NULL,
    request_hash TEXT NOT NULL,
    status       SMALLINT,
    body         TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (scope, key)
);
CREATE INDEX idempotency_keys_created_idx ON idempotency_keys (created_at);
