-- Marketing campaigns and the advertising send log (정보통신망법 광고성 정보).
-- Campaign sends and lifecycle nudges share marketing_sends, so the weekly frequency cap counts both.
-- dedupe_key makes every send idempotent: a deferred or retried campaign never reaches the same customer twice.
CREATE TABLE campaigns (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 60),
    channel       TEXT NOT NULL CHECK (channel IN ('push', 'sms')),
    title         TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 60),
    body          TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 500),
    audience      JSONB NOT NULL DEFAULT '[]',
    optout_number TEXT,
    status        TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'cancelled')),
    scheduled_at  TIMESTAMPTZ,
    sent_at       TIMESTAMPTZ,
    created_by    UUID,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (channel <> 'sms' OR optout_number IS NOT NULL)
);
CREATE INDEX campaigns_due_idx ON campaigns (scheduled_at) WHERE status = 'scheduled';

CREATE TABLE marketing_sends (
    id          BIGSERIAL PRIMARY KEY,
    dedupe_key  TEXT NOT NULL UNIQUE,
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    channel     TEXT NOT NULL CHECK (channel IN ('push', 'sms')),
    status      TEXT NOT NULL CHECK (status IN ('sent', 'failed', 'skipped_consent')),
    error       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX marketing_sends_user_idx ON marketing_sends (user_id, created_at DESC);
CREATE INDEX marketing_sends_campaign_idx ON marketing_sends (campaign_id, status);
