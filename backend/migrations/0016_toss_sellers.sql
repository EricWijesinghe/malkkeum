-- Toss payouts pay a seller, not a bank account: each pro is registered as a Toss seller first.
-- toss_seller_fp fingerprints the bank account the seller was registered with, so a payout is refused
-- (and the seller re-registered) when the account the owner approved no longer matches.
ALTER TABLE pros
    ADD COLUMN toss_seller_id     TEXT UNIQUE,
    ADD COLUMN toss_seller_status TEXT,
    ADD COLUMN toss_seller_fp     TEXT,
    ADD COLUMN toss_seller_rev    INT NOT NULL DEFAULT 0;
