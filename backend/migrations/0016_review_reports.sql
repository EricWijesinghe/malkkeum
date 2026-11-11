-- User reports on reviews (Google Play UGC policy, Apple 1.2). One report per user per review.
-- report_pending marks a review auto-hidden by reports and waiting for a staff decision.
CREATE TABLE review_reports (
    booking_id  UUID NOT NULL REFERENCES reviews(booking_id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason      TEXT NOT NULL CHECK (reason IN ('spam', 'offensive', 'personal_info', 'other')),
    note        TEXT NOT NULL DEFAULT '' CHECK (char_length(note) <= 300),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (booking_id, reporter_id)
);

ALTER TABLE reviews ADD COLUMN report_pending BOOLEAN NOT NULL DEFAULT FALSE;
CREATE INDEX reviews_report_pending_idx ON reviews (created_at) WHERE report_pending;

-- Staff can stop a customer from posting reviews (abusive authors).
ALTER TABLE users ADD COLUMN review_blocked BOOLEAN NOT NULL DEFAULT FALSE;
