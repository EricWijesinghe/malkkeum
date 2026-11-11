-- Peak surcharges (weekend, public holiday, Seollal/Chuseok, evening hours). The owner config lives in
-- the existing `settings` table under key 'peak_pricing' (domain::peak::PeakConfig).

-- Surcharge applied at booking time, stored so the receipt and settlement never recompute it.
ALTER TABLE bookings ADD COLUMN peak_surcharge BIGINT NOT NULL DEFAULT 0 CHECK (peak_surcharge >= 0);
