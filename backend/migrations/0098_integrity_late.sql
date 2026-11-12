-- Integrity checks on columns added after 0040 (sqlx runs migrations in version order).
-- A settlement is gross minus the platform fee plus the tip (0076, all to the partner), never negative.
ALTER TABLE settlements
    ADD CONSTRAINT settlements_money_consistent CHECK (gross >= 0 AND fee >= 0 AND net = gross - fee + tip) NOT VALID;
ALTER TABLE settlements VALIDATE CONSTRAINT settlements_money_consistent;
