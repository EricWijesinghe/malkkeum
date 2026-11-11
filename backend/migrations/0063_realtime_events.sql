-- Cross-node realtime payloads too large for pg_notify (8000-byte limit). Only the id travels on
-- the channel; the receiving node reads the row. Rows live minutes and are pruned by ops::prune.
CREATE TABLE realtime_events (
    id          uuid PRIMARY KEY,
    payload     jsonb NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX realtime_events_created_idx ON realtime_events (created_at);
