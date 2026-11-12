-- Regular cleaning subscriptions. A subscription plans visits (one row per visit date); a visit becomes a
-- paid booking when it is charged the day before (routes in subscriptions.rs / the charge pass).

CREATE TABLE subscriptions (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    service_code       TEXT NOT NULL REFERENCES services(code),
    unit_index         SMALLINT,
    address_id         UUID NOT NULL REFERENCES addresses(id),
    payment_method_id  UUID NOT NULL REFERENCES payment_methods(id),
    preferred_pro_id   UUID REFERENCES pros(id),
    cadence_weeks      SMALLINT NOT NULL CHECK (cadence_weeks IN (1, 2, 4)),
    weekday            SMALLINT NOT NULL CHECK (weekday BETWEEN 0 AND 6),
    start_hour         SMALLINT NOT NULL,
    anchor_date        DATE NOT NULL,
    status             TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled')),
    -- Why it is paused: 'customer', 'staff' or 'payment' (set when repeated charges fail).
    paused_reason      TEXT,
    -- Discount in percent, copied from the owner's policy when the subscription is created.
    discount_percent   SMALLINT NOT NULL DEFAULT 0 CHECK (discount_percent BETWEEN 0 AND 30),
    consecutive_failures INT NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    cancelled_at       TIMESTAMPTZ
);
CREATE INDEX subscriptions_user_idx ON subscriptions (user_id);
CREATE INDEX subscriptions_pro_idx ON subscriptions (preferred_pro_id) WHERE preferred_pro_id IS NOT NULL;
CREATE INDEX subscriptions_active_idx ON subscriptions (status) WHERE status = 'active';

CREATE TABLE subscription_visits (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id  UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    visit_date       DATE NOT NULL,
    start_hour       SMALLINT NOT NULL,
    -- planned: not yet charged. booked: charged and a booking exists. skipped / cancelled: by the customer or staff.
    -- missed: the charge window passed without a successful charge.
    state            TEXT NOT NULL DEFAULT 'planned' CHECK (state IN ('planned', 'booked', 'skipped', 'cancelled', 'missed')),
    booking_id       UUID REFERENCES bookings(id),
    charge_attempts  INT NOT NULL DEFAULT 0,
    retry_at         TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (subscription_id, visit_date)
);
CREATE INDEX subscription_visits_due_idx ON subscription_visits (visit_date) WHERE state = 'planned';

ALTER TABLE bookings ADD COLUMN subscription_id UUID REFERENCES subscriptions(id);
-- bookings_subscription_idx is built concurrently in 0098 (bookings is a big table).
