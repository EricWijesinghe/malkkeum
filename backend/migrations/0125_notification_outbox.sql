-- Notification outbox. A notification is written here first (inside the business transaction for
-- accept and completion), then stored in the inbox and pushed. The row is deleted once both are done.
-- Rows left behind (push provider down, crash after commit) are retried by the notify_outbox job with
-- backoff. title and body keep the Korean source text and are translated at delivery.
-- last_error holds a short code, never a provider message.
CREATE TABLE notification_outbox (
    id              BIGSERIAL PRIMARY KEY,
    owner_role      TEXT NOT NULL CHECK (owner_role IN ('customer', 'pro', 'member')),
    owner_id        UUID NOT NULL,
    kind            TEXT NOT NULL,
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    data            JSONB NOT NULL,
    stored          BOOLEAN NOT NULL DEFAULT false,
    attempts        INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ NOT NULL,
    last_error      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX notification_outbox_due_idx ON notification_outbox (next_attempt_at);
