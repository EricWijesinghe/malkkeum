-- Integrity pass: money is never negative, phone numbers have one shape, counters and enum-like
-- text are constrained, and the one dangling reference (coupons.used_booking_id) gets a foreign key.
-- Each CHECK/FK is added NOT VALID (no full scan under the write lock) and then VALIDATEd here.
-- Financial and booking references stay NO ACTION on purpose: history is soft-deleted (deleted_at),
-- never cascaded. Only reversible references use ON DELETE SET NULL / CASCADE.

-- Money (won). NULL passes a CHECK, so optional prices stay optional.
ALTER TABLE bookings
    ADD CONSTRAINT bookings_money_nonneg CHECK (estimate >= 0 AND final_price >= 0 AND deposit >= 0
        AND list_price >= 0 AND discount >= 0 AND paid_amount >= 0) NOT VALID;
ALTER TABLE bookings VALIDATE CONSTRAINT bookings_money_nonneg;

ALTER TABLE payments
    ADD CONSTRAINT payments_refund_bounds CHECK (refunded_amount >= 0 AND refunded_amount <= amount) NOT VALID;
ALTER TABLE payments VALIDATE CONSTRAINT payments_refund_bounds;

-- settlements money consistency needs settlements.tip (0076): see 0098.

ALTER TABLE pros
    ADD CONSTRAINT pros_fee_bps_range CHECK (fee_bps BETWEEN 0 AND 10000) NOT VALID;
ALTER TABLE pros VALIDATE CONSTRAINT pros_fee_bps_range;

ALTER TABLE chat_threads
    ADD CONSTRAINT chat_threads_unread_nonneg CHECK (unread_member >= 0 AND unread_staff >= 0) NOT VALID;
ALTER TABLE chat_threads VALIDATE CONSTRAINT chat_threads_unread_nonneg;

-- Phone shape: Korean mobile, digits only (auth::normalize_phone). Empty or NULL means "not bound"
-- (team members removed, pros deleted); users deleted by PIPA keep the 'deleted:<uuid>' marker.
ALTER TABLE users
    ADD CONSTRAINT users_phone_format CHECK (phone IS NULL OR phone LIKE 'deleted:%' OR phone ~ '^01[016789][0-9]{7,8}$') NOT VALID;
ALTER TABLE users VALIDATE CONSTRAINT users_phone_format;
ALTER TABLE pros
    ADD CONSTRAINT pros_phone_format CHECK (phone IS NULL OR phone ~ '^01[016789][0-9]{7,8}$') NOT VALID;
ALTER TABLE pros VALIDATE CONSTRAINT pros_phone_format;
ALTER TABLE team_members
    ADD CONSTRAINT team_members_phone_format CHECK (phone = '' OR phone ~ '^01[016789][0-9]{7,8}$') NOT VALID;
ALTER TABLE team_members VALIDATE CONSTRAINT team_members_phone_format;

-- Closed sets written by code (owner roles as Recipient::as_str, push platforms as accepted by /me/push).
ALTER TABLE push_tokens
    ADD CONSTRAINT push_tokens_owner_role_check CHECK (owner_role IN ('customer','pro','member','staff')) NOT VALID,
    ADD CONSTRAINT push_tokens_platform_check CHECK (platform IN ('android','ios','windows','web')) NOT VALID;
ALTER TABLE push_tokens VALIDATE CONSTRAINT push_tokens_owner_role_check;
ALTER TABLE push_tokens VALIDATE CONSTRAINT push_tokens_platform_check;

ALTER TABLE notifications
    ADD CONSTRAINT notifications_owner_role_check CHECK (owner_role IN ('customer','pro','member','staff')) NOT VALID;
ALTER TABLE notifications VALIDATE CONSTRAINT notifications_owner_role_check;

-- The coupon's redemption points at a real booking; the booking going away un-redeems it.
ALTER TABLE coupons
    ADD CONSTRAINT coupons_used_booking_fkey FOREIGN KEY (used_booking_id) REFERENCES bookings(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE coupons VALIDATE CONSTRAINT coupons_used_booking_fkey;

-- pg_trgm backs the admin search indexes (migration 0041+); contrib ships with the official postgres image.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
