-- Partner payouts as a state machine: requested -> sent -> paid, or failed (retryable).
-- One row per pro per payout run. The bank account is snapshotted at request time so a later
-- account change by the pro cannot redirect money that was already approved.
CREATE TABLE payouts (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pro_id                UUID NOT NULL REFERENCES pros(id),
    payout_date           DATE NOT NULL,
    amount                BIGINT NOT NULL CHECK (amount > 0),
    items                 INT NOT NULL CHECK (items > 0),
    provider              TEXT NOT NULL CHECK (provider IN ('manual', 'toss')),
    state                 TEXT NOT NULL CHECK (state IN ('requested', 'sent', 'paid', 'failed')),
    bank                  TEXT NOT NULL,
    holder                TEXT NOT NULL,
    account_enc           TEXT NOT NULL,
    account_last4         TEXT NOT NULL,
    -- Sent to the provider as its idempotency key. Rotated only after a definite provider decline,
    -- so a retry can never create a second transfer while an earlier one may still exist.
    idempotency_key       TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    provider_transfer_id  TEXT UNIQUE,
    failure_reason        TEXT,
    attempts              INT NOT NULL DEFAULT 0,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    paid_at               TIMESTAMPTZ
);
CREATE INDEX payouts_state_idx ON payouts (state, created_at DESC);
-- At most one in-flight payout per pro per payout date.
CREATE UNIQUE INDEX payouts_inflight_per_day ON payouts (pro_id, payout_date) WHERE state IN ('requested', 'sent');

-- A settlement belongs to at most one payout (NULL until a run picks it up).
ALTER TABLE settlements ADD COLUMN payout_id UUID REFERENCES payouts(id);
CREATE INDEX settlements_payout_idx ON settlements (payout_id) WHERE payout_id IS NOT NULL;
