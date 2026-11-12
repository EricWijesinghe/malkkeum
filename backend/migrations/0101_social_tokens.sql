-- Provider refresh tokens, kept only so account deletion can revoke the sign-in at the provider
-- (Apple /auth/revoke, App Store Review 5.1.1(v); Naver token delete). AES-GCM with DATA_KEY (crypto.rs).
-- Goes with its identity row: deleting the identity deletes the token.
CREATE TABLE social_tokens (
    identity_id       UUID PRIMARY KEY REFERENCES user_identities(id) ON DELETE CASCADE,
    -- The provider app the token was issued to (Apple: the bundle id from the identity token's aud).
    client_id         TEXT NOT NULL,
    refresh_token_enc TEXT NOT NULL,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Apple server-to-server notifications already handled, by JWS id (jti). Replays are acknowledged and skipped.
-- No user identifier is stored. Never purged: a seen id must stay seen (retention.rs leaves this table alone).
CREATE TABLE apple_notifications (
    jti         TEXT PRIMARY KEY,
    event_type  TEXT NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Apple account-delete for a partner with an open job or unpaid settlement: the deletion waits until that clears
-- (retention.rs retries it every run).
ALTER TABLE pros ADD COLUMN deletion_requested_at TIMESTAMPTZ;
