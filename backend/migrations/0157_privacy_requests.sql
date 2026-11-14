-- PIPA customer requests handled by staff (열람 export, 삭제). Holds ids and outcome only, never the customer's
-- details, so the record outlives the anonymised account. customer_id has no foreign key on purpose.
CREATE TABLE privacy_requests (
    id           BIGSERIAL PRIMARY KEY,
    kind         TEXT NOT NULL CHECK (kind IN ('export','delete')),
    customer_id  UUID NOT NULL,
    staff_id     UUID REFERENCES staff(id) ON DELETE SET NULL,
    status       TEXT NOT NULL CHECK (status IN ('done','failed')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX privacy_requests_created_idx ON privacy_requests (created_at DESC);
