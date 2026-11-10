-- AI support agent: per-thread pause switch and a usage ledger (one row per Messages API call).
ALTER TABLE chat_threads ADD COLUMN ai_paused BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE ai_usage (
    id                  BIGSERIAL PRIMARY KEY,
    thread_id           UUID REFERENCES chat_threads(id) ON DELETE SET NULL,
    model               TEXT NOT NULL,
    outcome             TEXT NOT NULL CHECK (outcome IN ('answered','handoff')),
    input_tokens        INT NOT NULL DEFAULT 0,
    output_tokens       INT NOT NULL DEFAULT 0,
    cache_read_tokens   INT NOT NULL DEFAULT 0,
    cache_write_tokens  INT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ai_usage_thread_idx ON ai_usage (thread_id, created_at);
CREATE INDEX ai_usage_created_idx ON ai_usage (created_at);
