-- Launch safety. Entry/door codes move out of visit_notes into an encrypted column (crypto.rs), cleared
-- 24h after the job ends (retention.rs). Partner check-in/out timestamps feed no-show detection.
ALTER TABLE bookings
    ADD COLUMN access_code_enc TEXT,
    ADD COLUMN checked_in_at TIMESTAMPTZ,
    ADD COLUMN checked_out_at TIMESTAMPTZ;

-- Claims, incidents and disputes. One row per case; notes are internal (staff only).
CREATE TABLE cases (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id    UUID REFERENCES bookings(id),
    kind          TEXT NOT NULL CHECK (kind IN ('damage', 'loss', 'complaint', 'no_show', 'safety', 'payment_dispute')),
    source        TEXT NOT NULL CHECK (source IN ('manual', 'ai', 'no_show')),
    reporter_role TEXT NOT NULL CHECK (reporter_role IN ('customer', 'partner', 'staff', 'system')),
    reporter_id   UUID,
    status        TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'rejected')),
    assignee_id   UUID REFERENCES staff(id),
    summary       TEXT NOT NULL CHECK (char_length(summary) BETWEEN 1 AND 2000),
    photos        JSONB NOT NULL DEFAULT '[]',
    outcome       JSONB,
    sla_due_at    TIMESTAMPTZ NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at   TIMESTAMPTZ
);
CREATE INDEX cases_queue_idx ON cases (status, sla_due_at);
CREATE INDEX cases_booking_idx ON cases (booking_id);

CREATE TABLE case_notes (
    id         BIGSERIAL PRIMARY KEY,
    case_id    UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    author_id  UUID REFERENCES staff(id),
    body       TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX case_notes_case_idx ON case_notes (case_id, created_at);
