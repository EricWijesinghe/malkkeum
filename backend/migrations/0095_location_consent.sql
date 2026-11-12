-- 위치기반서비스 이용약관 (위치정보법) consent joins the append-only consent log as kind 'location'.
ALTER TABLE user_consents DROP CONSTRAINT user_consents_kind_check;
ALTER TABLE user_consents ADD CONSTRAINT user_consents_kind_check
    CHECK (kind IN ('terms','privacy','overseas_transfer','marketing','location')) NOT VALID;
ALTER TABLE user_consents VALIDATE CONSTRAINT user_consents_kind_check;
