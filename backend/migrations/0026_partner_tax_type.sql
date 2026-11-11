-- Partner tax type decides 사업소득 withholding on payouts. 'freelancer' (사업소득자) is withheld 3.3%,
-- 'business' (사업자등록, issues 세금계산서/현금영수증) is not. 'unset' is withheld until the owner classifies the partner.
ALTER TABLE pros ADD COLUMN tax_type TEXT NOT NULL DEFAULT 'unset' CHECK (tax_type IN ('unset', 'freelancer', 'business'));
-- Snapshot at payout creation, so a later reclassification never changes money already approved.
-- Payouts made before this rule existed were paid without a recorded withholding: 'untracked' keeps them at zero.
ALTER TABLE payouts ADD COLUMN tax_type TEXT NOT NULL DEFAULT 'untracked' CHECK (tax_type IN ('untracked', 'unset', 'freelancer', 'business'));
