-- Tips are paid through the same payments table as the job, so the kind check must allow them.
ALTER TABLE payments DROP CONSTRAINT payments_kind_check;
ALTER TABLE payments ADD CONSTRAINT payments_kind_check CHECK (kind IN ('full','deposit','balance','tip')) NOT VALID;
ALTER TABLE payments VALIDATE CONSTRAINT payments_kind_check;

-- A settlement is gross minus the platform fee plus the tip (0076, all to the partner), never negative.
ALTER TABLE settlements
    ADD CONSTRAINT settlements_money_consistent CHECK (gross >= 0 AND fee >= 0 AND net = gross - fee + tip) NOT VALID;
ALTER TABLE settlements VALIDATE CONSTRAINT settlements_money_consistent;
