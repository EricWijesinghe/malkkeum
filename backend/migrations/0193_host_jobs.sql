-- Server jobs an owner queues from the console. The row is the API's record of the request; the live state
-- (queued, running, ok, failed) comes from the server agent's status files, read back on each list.
CREATE TABLE host_jobs (
    id             UUID PRIMARY KEY,
    kind           TEXT NOT NULL,
    arg            TEXT NOT NULL DEFAULT '',
    progress_token TEXT NOT NULL UNIQUE,
    requested_by   UUID NOT NULL REFERENCES staff (id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX host_jobs_created_idx ON host_jobs (created_at DESC);
