-- Core schema. Money is BIGINT won (VAT incl.). Timestamps are UTC.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone       TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL DEFAULT '',
    email       TEXT,
    locale      TEXT NOT NULL DEFAULT 'ko',
    welcome_issued BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ
);

CREATE TABLE pros (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone       TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL DEFAULT '',
    team_name   TEXT NOT NULL DEFAULT '',
    status      TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','verified','suspended')),
    fee_bps     INT  NOT NULL DEFAULT 2000,
    locale      TEXT NOT NULL DEFAULT 'ko',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE team_members (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pro_id      UUID NOT NULL REFERENCES pros(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    phone       TEXT NOT NULL,
    role        TEXT NOT NULL CHECK (role IN ('owner','member')),
    invite_status TEXT NOT NULL DEFAULT 'invited' CHECK (invite_status IN ('invited','active','removed')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (pro_id, phone)
);

CREATE TABLE staff (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         TEXT NOT NULL UNIQUE,
    name          TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    role          TEXT NOT NULL CHECK (role IN ('admin','consultant')),
    active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE otp_codes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone       TEXT NOT NULL,
    code_hash   TEXT NOT NULL,
    attempts    INT  NOT NULL DEFAULT 0,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX otp_codes_phone_idx ON otp_codes (phone, created_at DESC);

CREATE TABLE refresh_tokens (
    token_hash  TEXT PRIMARY KEY,
    subject     UUID NOT NULL,
    role        TEXT NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ
);

CREATE TABLE addresses (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind          TEXT NOT NULL CHECK (kind IN ('home','office')),
    label         TEXT NOT NULL,
    road_address  TEXT NOT NULL,
    detail        TEXT NOT NULL DEFAULT '',
    district_code TEXT NOT NULL,
    size_pyeong   SMALLINT NOT NULL CHECK (size_pyeong BETWEEN 1 AND 500),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at    TIMESTAMPTZ
);
CREATE INDEX addresses_user_idx ON addresses (user_id) WHERE deleted_at IS NULL;

CREATE TABLE services (
    code        TEXT PRIMARY KEY,
    pricing     JSONB NOT NULL,
    needs_preparation BOOLEAN NOT NULL DEFAULT FALSE,
    max_pyeong  SMALLINT,
    content     JSONB NOT NULL DEFAULT '{}'::jsonb,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order  INT NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE slot_capacity (
    start_hour  SMALLINT PRIMARY KEY,
    capacity    INT
);

CREATE TABLE settings (
    key         TEXT PRIMARY KEY,
    value       JSONB NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE coupons (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    amount          BIGINT NOT NULL CHECK (amount > 0),
    service_code    TEXT REFERENCES services(code),
    campaign        TEXT,
    issued_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ NOT NULL,
    used_booking_id UUID
);
CREATE INDEX coupons_user_idx ON coupons (user_id);

CREATE TABLE payment_methods (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider      TEXT NOT NULL,
    billing_key   TEXT NOT NULL,
    display_name  TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at    TIMESTAMPTZ
);

CREATE SEQUENCE booking_number_seq;

CREATE TABLE bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    number          TEXT NOT NULL UNIQUE,
    user_id         UUID NOT NULL REFERENCES users(id),
    service_code    TEXT NOT NULL REFERENCES services(code),
    unit_index      SMALLINT,
    address         JSONB NOT NULL,
    district_code   TEXT NOT NULL,
    visit_date      DATE NOT NULL,
    start_hour      SMALLINT NOT NULL,
    minutes         INT,
    status          SMALLINT NOT NULL CHECK (status BETWEEN -1 AND 3),
    answers         JSONB,
    estimate        BIGINT,
    final_price     BIGINT,
    deposit         BIGINT,
    list_price      BIGINT,
    discount        BIGINT NOT NULL DEFAULT 0,
    paid_amount     BIGINT NOT NULL DEFAULT 0,
    balance_paid    BOOLEAN NOT NULL DEFAULT FALSE,
    coupon_id       UUID REFERENCES coupons(id),
    team_name       TEXT,
    pro_id          UUID REFERENCES pros(id),
    assignee_id     UUID REFERENCES team_members(id),
    accepted_at     TIMESTAMPTZ,
    visit_notes     JSONB NOT NULL DEFAULT '{}'::jsonb,
    team_memo       TEXT NOT NULL DEFAULT '',
    reschedule      JSONB,
    cancelled_at    TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX bookings_user_idx ON bookings (user_id, visit_date);
CREATE INDEX bookings_status_idx ON bookings (status, visit_date);
CREATE INDEX bookings_slot_idx ON bookings (visit_date, start_hour) WHERE status >= 0;
CREATE INDEX bookings_open_jobs_idx ON bookings (visit_date) WHERE pro_id IS NULL AND status IN (0, 1);

CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID NOT NULL REFERENCES bookings(id),
    amount          BIGINT NOT NULL CHECK (amount > 0),
    kind            TEXT NOT NULL CHECK (kind IN ('full','deposit','balance')),
    status          TEXT NOT NULL CHECK (status IN ('pending','paid','failed','refunded','partially_refunded')),
    refunded_amount BIGINT NOT NULL DEFAULT 0,
    provider        TEXT NOT NULL,
    provider_tx_id  TEXT,
    failure_code    TEXT,
    idempotency_key TEXT NOT NULL UNIQUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX payments_booking_idx ON payments (booking_id);

CREATE TABLE chat_threads (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    audience        TEXT NOT NULL CHECK (audience IN ('customer','partner')),
    user_id         UUID REFERENCES users(id),
    pro_id          UUID REFERENCES pros(id),
    booking_id      UUID REFERENCES bookings(id),
    topic           TEXT NOT NULL,
    unread_member   INT NOT NULL DEFAULT 0,
    unread_staff    INT NOT NULL DEFAULT 0,
    closed          BOOLEAN NOT NULL DEFAULT FALSE,
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK ((audience = 'customer' AND user_id IS NOT NULL) OR (audience = 'partner' AND pro_id IS NOT NULL))
);
CREATE UNIQUE INDEX chat_threads_booking_uidx ON chat_threads (audience, booking_id) WHERE booking_id IS NOT NULL;
CREATE INDEX chat_threads_inbox_idx ON chat_threads (audience, unread_staff DESC, last_message_at DESC);

CREATE TABLE chat_messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id   UUID NOT NULL REFERENCES chat_threads(id) ON DELETE CASCADE,
    sender      TEXT NOT NULL CHECK (sender IN ('customer','partner','staff','system')),
    sender_id   UUID,
    kind        TEXT NOT NULL CHECK (kind IN ('text','system','card','photo','quote')),
    body        JSONB NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX chat_messages_thread_idx ON chat_messages (thread_id, created_at);

CREATE TABLE content_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kind        TEXT NOT NULL CHECK (kind IN ('notice','tip','faq','banner','legal')),
    slug        TEXT,
    title       JSONB NOT NULL,
    body        JSONB NOT NULL DEFAULT '{}'::jsonb,
    image_url   TEXT,
    link        TEXT,
    sort_order  INT NOT NULL DEFAULT 0,
    starts_at   TIMESTAMPTZ,
    ends_at     TIMESTAMPTZ,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX content_items_kind_idx ON content_items (kind, sort_order);

CREATE TABLE partner_prefs (
    pro_id      UUID PRIMARY KEY REFERENCES pros(id) ON DELETE CASCADE,
    services    TEXT[] NOT NULL DEFAULT '{}',
    districts   TEXT[] NOT NULL DEFAULT '{}',
    weekdays    SMALLINT[] NOT NULL DEFAULT '{0,1,2,3,4}',
    day_parts   TEXT[] NOT NULL DEFAULT '{morning,afternoon}',
    days_off    DATE[] NOT NULL DEFAULT '{}',
    notify      JSONB NOT NULL DEFAULT '{"direct":true,"quotes":true,"chat":true,"quiet_night":true}'::jsonb
);

CREATE TABLE quotes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL REFERENCES bookings(id),
    pro_id      UUID NOT NULL REFERENCES pros(id),
    amount      BIGINT NOT NULL CHECK (amount > 0),
    note        TEXT NOT NULL DEFAULT '',
    state       TEXT NOT NULL DEFAULT 'waiting' CHECK (state IN ('waiting','selected','rejected','closed','withdrawn')),
    seen_by_pro BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (booking_id, pro_id)
);

CREATE TABLE completion_reports (
    booking_id    UUID PRIMARY KEY REFERENCES bookings(id),
    before_photos TEXT[] NOT NULL,
    after_photos  TEXT[] NOT NULL,
    checklist     JSONB NOT NULL,
    submitted_by  UUID NOT NULL,
    submitted_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (cardinality(before_photos) >= 1 AND cardinality(after_photos) >= 1)
);

CREATE TABLE settlements (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pro_id      UUID NOT NULL REFERENCES pros(id),
    booking_id  UUID NOT NULL UNIQUE REFERENCES bookings(id),
    gross       BIGINT NOT NULL,
    fee         BIGINT NOT NULL,
    net         BIGINT NOT NULL,
    payout_date DATE,
    state       TEXT NOT NULL CHECK (state IN ('waiting_balance','pending','paid','held')),
    paid_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX settlements_pro_idx ON settlements (pro_id, state);

CREATE TABLE payout_accounts (
    pro_id        UUID PRIMARY KEY REFERENCES pros(id) ON DELETE CASCADE,
    bank          TEXT NOT NULL,
    account_enc   TEXT NOT NULL,
    account_last4 TEXT NOT NULL,
    holder        TEXT NOT NULL,
    verified_at   TIMESTAMPTZ
);

CREATE TABLE reviews (
    booking_id  UUID PRIMARY KEY REFERENCES bookings(id),
    user_id     UUID NOT NULL REFERENCES users(id),
    pro_id      UUID REFERENCES pros(id),
    rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    body        TEXT NOT NULL DEFAULT '',
    hidden      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE push_tokens (
    token       TEXT PRIMARY KEY,
    owner_role  TEXT NOT NULL,
    owner_id    UUID NOT NULL,
    platform    TEXT NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX push_tokens_owner_idx ON push_tokens (owner_role, owner_id);

CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_role  TEXT NOT NULL,
    owner_id    UUID NOT NULL,
    kind        TEXT NOT NULL,
    data        JSONB NOT NULL,
    read_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX notifications_owner_idx ON notifications (owner_role, owner_id, created_at DESC);

CREATE TABLE audit_log (
    id          BIGSERIAL PRIMARY KEY,
    actor_role  TEXT NOT NULL,
    actor_id    UUID,
    action      TEXT NOT NULL,
    target      TEXT NOT NULL,
    data        JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
