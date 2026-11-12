-- 세금계산서 (electronic tax invoice) requests from business customers. Created at checkout (payment_id NULL,
-- state 'pending'), queued for the owner once the checkout settles ('requested'), then issued by the owner on 홈택스
-- and marked 'issued' with the NTS approval number. Business details are not personal data, so they are stored plain.
CREATE TABLE tax_invoice_requests (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    checkout_id       UUID NOT NULL REFERENCES checkouts(id),
    payment_id        UUID REFERENCES payments(id),
    business_number   TEXT NOT NULL,
    company_name      TEXT NOT NULL,
    representative    TEXT NOT NULL DEFAULT '',
    business_type     TEXT NOT NULL DEFAULT '',
    business_item     TEXT NOT NULL DEFAULT '',
    address           TEXT NOT NULL DEFAULT '',
    email             TEXT NOT NULL,
    state             TEXT NOT NULL CHECK (state IN ('pending', 'requested', 'issued', 'cancelled')),
    approval_number   TEXT,
    issued_on         DATE,
    exported_at       TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- One live request per checkout.
CREATE UNIQUE INDEX tax_invoice_live_per_checkout ON tax_invoice_requests (checkout_id) WHERE state IN ('pending', 'requested', 'issued');
CREATE INDEX tax_invoice_state_idx ON tax_invoice_requests (state, created_at DESC);
