-- Growth layer: review photos, referral codes and referral claims.
-- Welcome and referral offer settings live in `settings` (no DDL needed).

ALTER TABLE reviews ADD COLUMN photos JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE users ADD COLUMN referral_code TEXT UNIQUE;

-- One referral per friend (PK) and one reward per referred phone (UNIQUE), whatever the account does later.
CREATE TABLE referrals (
    referred_user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    referrer_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_phone   TEXT NOT NULL UNIQUE,
    state            TEXT NOT NULL DEFAULT 'pending' CHECK (state IN ('pending', 'rewarded')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    rewarded_at      TIMESTAMPTZ,
    CHECK (referrer_id <> referred_user_id)
);
CREATE INDEX referrals_referrer_idx ON referrals (referrer_id);

-- Social-proof counter: completed jobs per month.
CREATE INDEX IF NOT EXISTS bookings_completed_idx ON bookings (completed_at) WHERE status = 3;
