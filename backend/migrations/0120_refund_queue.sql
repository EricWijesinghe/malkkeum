-- Payment integrity: durable compensating refunds, and one PortOne payment per checkout.

-- 0121/0122 add UNIQUE indexes on the PortOne payment id. Refuse to go on while live data already
-- breaks that rule: such rows are a payment reused across bookings and need a human decision
-- (refund or cancel the extra booking) before the server can start.
DO $$
DECLARE
    dup_payments bigint;
    dup_checkouts bigint;
BEGIN
    SELECT count(*) INTO dup_payments FROM (
        SELECT provider_tx_id FROM payments
        WHERE provider = 'portone' AND provider_tx_id IS NOT NULL AND provider_tx_id NOT LIKE 'dev:%'
        GROUP BY provider_tx_id HAVING count(*) > 1) d;
    SELECT count(*) INTO dup_checkouts FROM (
        SELECT provider_payment_id FROM checkouts
        WHERE provider_payment_id IS NOT NULL AND provider_payment_id NOT LIKE 'dev:%'
        GROUP BY provider_payment_id HAVING count(*) > 1) d;
    IF dup_payments > 0 OR dup_checkouts > 0 THEN
        RAISE EXCEPTION 'migration 0120: % PortOne payment id(s) back several payments rows and % back several checkouts', dup_payments, dup_checkouts
            USING HINT = 'List them: SELECT provider_tx_id, array_agg(booking_id) FROM payments WHERE provider = ''portone'' GROUP BY 1 HAVING count(*) > 1 (and the same on checkouts.provider_payment_id). Settle each in the PortOne and admin consoles (refund or cancel the extra booking), then rename the id on the extra rows (append '':dup:'' and the row id) and restart.';
    END IF;
END $$;

-- One row per compensating refund. Written before the provider is called, so a failed or ambiguous
-- refund is retried by the reconciler (next_at is both the backoff and the lease) and one
-- (provider, tx, amount) is never refunded twice.
CREATE TABLE refund_queue (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider    TEXT NOT NULL,
    tx_id       TEXT NOT NULL,
    amount      BIGINT NOT NULL CHECK (amount > 0),
    checkout_id UUID REFERENCES checkouts(id),
    attempts    INT NOT NULL DEFAULT 0,
    next_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    done_at     TIMESTAMPTZ,
    last_error  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, tx_id, amount)
);
CREATE INDEX refund_queue_due_idx ON refund_queue (next_at) WHERE done_at IS NULL;
CREATE INDEX refund_queue_checkout_idx ON refund_queue (checkout_id) WHERE checkout_id IS NOT NULL;

-- 'refund_pending': the payment is being given back but the provider has not confirmed it yet.
ALTER TABLE checkouts DROP CONSTRAINT IF EXISTS checkouts_status_check;
ALTER TABLE checkouts ADD CONSTRAINT checkouts_status_check
    CHECK (status IN ('pending','awaiting_deposit','paid','failed','expired','cancelled','refund_pending','refunded')) NOT VALID;
ALTER TABLE checkouts VALIDATE CONSTRAINT checkouts_status_check;
