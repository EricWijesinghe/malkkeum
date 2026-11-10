-- Social/identity sign-in: phone is bound later, so it is optional on both account kinds.
ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE pros ALTER COLUMN phone DROP NOT NULL;
-- PASS / 본인인증. Only a SHA-256 of the CI is stored, never the raw value.
ALTER TABLE users ADD COLUMN identity_verified_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN ci_hash TEXT UNIQUE;

CREATE TABLE user_identities (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider         TEXT NOT NULL CHECK (provider IN ('kakao','naver','google','apple')),
    provider_user_id TEXT NOT NULL,
    role             TEXT NOT NULL CHECK (role IN ('customer','pro')),
    subject_id       UUID NOT NULL,
    email            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, provider_user_id, role)
);
CREATE INDEX user_identities_subject_idx ON user_identities (subject_id);

-- One-off PortOne checkouts. A draft holds the validated booking request for kind 'booking'.
CREATE TABLE checkouts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    kind                TEXT NOT NULL CHECK (kind IN ('booking','deposit','balance')),
    booking_id          UUID REFERENCES bookings(id),
    draft               JSONB,
    method              TEXT NOT NULL,
    amount              BIGINT NOT NULL CHECK (amount > 0),
    status              TEXT NOT NULL CHECK (status IN ('pending','awaiting_deposit','paid','failed','expired','cancelled')),
    provider_payment_id TEXT,
    virtual_account     JSONB,
    result_booking_id   UUID REFERENCES bookings(id),
    expires_at          TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX checkouts_user_idx ON checkouts (user_id, created_at DESC);
CREATE INDEX checkouts_payment_idx ON checkouts (provider_payment_id) WHERE provider_payment_id IS NOT NULL;
