-- Points on a checkout are never negative and never more than its total (`amount`, see 0091):
-- the PG charges `amount - points`, which must not go below zero.
ALTER TABLE checkouts
    ADD CONSTRAINT checkouts_points_within_amount CHECK (points >= 0 AND points <= amount) NOT VALID;
ALTER TABLE checkouts VALIDATE CONSTRAINT checkouts_points_within_amount;
