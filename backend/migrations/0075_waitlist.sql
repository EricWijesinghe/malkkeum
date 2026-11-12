-- Waitlist for a full date/hour window. An offer holds the freed slot until offer_expires_at.
CREATE TABLE waitlist_entries (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    service_code      TEXT NOT NULL REFERENCES services(code),
    visit_date        DATE NOT NULL,
    start_hour        SMALLINT NOT NULL CHECK (start_hour BETWEEN 0 AND 23),
    end_hour          SMALLINT NOT NULL CHECK (end_hour BETWEEN 1 AND 24),
    status            TEXT NOT NULL DEFAULT 'waiting'
                      CHECK (status IN ('waiting','offered','accepted','expired','cancelled')),
    joined_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    offered_at        TIMESTAMPTZ,
    offer_expires_at  TIMESTAMPTZ,
    CHECK (start_hour < end_hour)
);
CREATE INDEX waitlist_slot_idx ON waitlist_entries (service_code, visit_date, status, joined_at);
