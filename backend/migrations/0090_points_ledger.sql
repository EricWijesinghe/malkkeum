-- Malkkeum points (loyalty, not stored value). Append-only ledger: balances are derived by summing
-- amounts, never stored. Each issued lot (earn/welcome/referral/refund/grant) owns its own id;
-- consumption rows (spend/expire/deduct) point at the lot via lot_id.
CREATE TABLE points_ledger (
    id              uuid PRIMARY KEY,
    user_id         uuid NOT NULL REFERENCES users(id),
    kind            text NOT NULL CHECK (kind IN ('earn','welcome','referral','refund','grant','spend','deduct','expire')),
    amount          bigint NOT NULL CHECK (amount <> 0),
    lot_id          uuid NOT NULL,
    expires_at      timestamptz,
    booking_id      uuid REFERENCES bookings(id),
    idempotency_key text NOT NULL UNIQUE,
    actor_id        uuid,
    reason          text,
    created_at      timestamptz NOT NULL DEFAULT now(),
    CHECK ((kind IN ('earn','welcome','referral','refund','grant')) = (amount > 0)),
    CHECK (kind NOT IN ('earn','welcome','referral','refund','grant') OR expires_at IS NOT NULL)
);

CREATE INDEX points_ledger_user_idx ON points_ledger (user_id, created_at);
CREATE INDEX points_ledger_lot_idx ON points_ledger (lot_id);

CREATE FUNCTION points_ledger_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'points_ledger is append-only';
END
$$;

CREATE TRIGGER points_ledger_no_update BEFORE UPDATE OR DELETE ON points_ledger
    FOR EACH ROW EXECUTE FUNCTION points_ledger_append_only();
