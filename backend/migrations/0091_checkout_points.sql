-- Points the customer asked to pay on a checkout. `amount` stays the full booking total; the PG
-- charges `amount - points`. The spend itself is written when the checkout is fulfilled.
ALTER TABLE checkouts ADD COLUMN points bigint NOT NULL DEFAULT 0 CHECK (points >= 0);
