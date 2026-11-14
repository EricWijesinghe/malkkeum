-- Single-use WebSocket tickets (realtime_ticket.rs): a 30s opaque credential that replaces the access token in the
-- socket URL, which proxies and access logs would otherwise record. Only the SHA-256 of a ticket is stored; a ticket
-- is spent by DELETE, so two replicas cannot both accept it.
CREATE TABLE realtime_tickets (
    token_hash TEXT PRIMARY KEY,
    subject    UUID NOT NULL,
    role       TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX realtime_tickets_expires_idx ON realtime_tickets (expires_at);
