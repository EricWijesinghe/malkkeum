-- Tips are paid through the same payments table as the job, so the kind check must allow them.
ALTER TABLE payments DROP CONSTRAINT payments_kind_check;
ALTER TABLE payments ADD CONSTRAINT payments_kind_check CHECK (kind IN ('full','deposit','balance','tip'));
