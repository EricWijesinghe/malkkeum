-- Single-use registration tickets for PortOne billing keys. A new card is saved only if PortOne reports
-- the key was issued for this customer and this ticket (routes/me.rs register_method), then the ticket is consumed.
CREATE TABLE billing_issues (
    id           UUID PRIMARY KEY,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at   TIMESTAMPTZ NOT NULL,
    consumed_at  TIMESTAMPTZ
);
CREATE INDEX billing_issues_open_idx ON billing_issues (user_id, created_at DESC) WHERE consumed_at IS NULL;

-- One live card per PortOne billing key, across all customers.
CREATE UNIQUE INDEX payment_methods_billing_key_live ON payment_methods (billing_key) WHERE deleted_at IS NULL;
