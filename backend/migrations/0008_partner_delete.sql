-- Partner self-service account deletion (App Store guideline 5.1.1(v)). The row stays for
-- settlement and booking history; personal fields are wiped.
ALTER TABLE pros ADD COLUMN deleted_at timestamptz;
