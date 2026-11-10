-- Payment recovery and abuse limits.

-- A checkout can end 'refunded': money arrived after the slot or coupon went away and was given back.
ALTER TABLE checkouts DROP CONSTRAINT IF EXISTS checkouts_status_check;
ALTER TABLE checkouts ADD CONSTRAINT checkouts_status_check
    CHECK (status IN ('pending','awaiting_deposit','paid','failed','expired','cancelled','refunded'));
ALTER TABLE checkouts ADD COLUMN refund_reason TEXT;
-- Lease stamp for the reconciler: a checkout is re-checked with the provider at most once per cooldown.
ALTER TABLE checkouts ADD COLUMN reconciled_at TIMESTAMPTZ;
CREATE INDEX checkouts_recon_idx ON checkouts (created_at) WHERE status IN ('pending','awaiting_deposit','expired');

-- One row per accepted upload; counted for the per-user daily quota.
CREATE TABLE uploads (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_role  TEXT NOT NULL,
    owner_id    UUID NOT NULL,
    file        TEXT NOT NULL,
    bytes       BIGINT NOT NULL CHECK (bytes > 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX uploads_owner_idx ON uploads (owner_role, owner_id, created_at DESC);
