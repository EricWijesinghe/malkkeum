-- Optional customer tip after a completed job. One tip per booking; the amount is paid to the partner in full.
CREATE TABLE booking_tips (
    booking_id      UUID PRIMARY KEY REFERENCES bookings(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id),
    pro_id          UUID NOT NULL REFERENCES pros(id),
    amount          BIGINT NOT NULL CHECK (amount > 0),
    payment_key     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tips are carried on the settlement so partner earnings show them separately from the job net.
ALTER TABLE settlements ADD COLUMN tip BIGINT NOT NULL DEFAULT 0 CHECK (tip >= 0);
