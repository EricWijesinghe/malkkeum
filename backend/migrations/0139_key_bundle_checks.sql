-- Result of the last keys-bundle upload test (routes/keys.rs). One row. verified_at is set only when an
-- uploaded bundle opens with the passphrase and holds the live DATA_KEY and JWT_SECRET.
CREATE TABLE key_bundle_checks (
    id          SMALLINT PRIMARY KEY CHECK (id = 1),
    verified_at TIMESTAMPTZ NOT NULL
);
