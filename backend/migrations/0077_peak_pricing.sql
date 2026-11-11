-- Owner-configurable peak surcharges (weekend, public holiday, Seollal/Chuseok, evening hours).
-- Singleton row; the config JSON is validated by domain::peak::PeakConfig on write.
CREATE TABLE peak_pricing_settings (
    id          SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    config      JSONB NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Surcharge applied at booking time, stored so the receipt and settlement never recompute it.
ALTER TABLE bookings ADD COLUMN peak_surcharge BIGINT NOT NULL DEFAULT 0 CHECK (peak_surcharge >= 0);
