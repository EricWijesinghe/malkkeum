-- Console setup wizard: integration keys entered by the owner, encrypted with DATA_KEY (AES-GCM).
-- One row per wizard card (portone, solapi, push, kakao, google, apple).
CREATE TABLE integration_settings (
    section     text PRIMARY KEY,
    secret      text NOT NULL,          -- crypto::encrypt(JSON object of field -> value)
    last_test   jsonb,                  -- {"ok": bool, "code": text, "at": timestamptz}
    updated_at  timestamptz NOT NULL DEFAULT now(),
    updated_by  uuid REFERENCES staff (id) ON DELETE SET NULL
);
