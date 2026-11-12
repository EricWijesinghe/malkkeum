-- 현금영수증 requests. A row is created when the customer asks at checkout (payment_id NULL, state 'pending')
-- and is linked to the payment when the checkout settles. The identity number is encrypted like payout accounts.
CREATE TABLE cash_receipts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    checkout_id     UUID NOT NULL REFERENCES checkouts(id),
    payment_id      UUID REFERENCES payments(id),
    purpose         TEXT NOT NULL CHECK (purpose IN ('PERSONAL', 'CORPORATE')),
    identity_type   TEXT NOT NULL CHECK (identity_type IN ('PHONE', 'BUSINESS')),
    identity_enc    TEXT NOT NULL,
    identity_last4  TEXT NOT NULL,
    state           TEXT NOT NULL CHECK (state IN ('pending', 'issued', 'failed', 'cancelled')),
    issue_number    TEXT,
    receipt_url     TEXT,
    failure_reason  TEXT,
    attempts        INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    issued_at       TIMESTAMPTZ,
    cancelled_at    TIMESTAMPTZ
);
-- One live request per checkout, and one live receipt per payment.
CREATE UNIQUE INDEX cash_receipts_live_per_checkout ON cash_receipts (checkout_id) WHERE state IN ('pending', 'issued');
CREATE UNIQUE INDEX cash_receipts_live_per_payment ON cash_receipts (payment_id) WHERE payment_id IS NOT NULL AND state IN ('issued', 'failed');
CREATE INDEX cash_receipts_created_idx ON cash_receipts (created_at DESC);
