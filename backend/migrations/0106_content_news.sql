-- Content kind `news` ("Dahae News" on the customer home). The kind CHECK from 0001 is replaced;
-- NOT VALID then VALIDATE keeps the lock short (content_items is small, the pattern is the house rule).
ALTER TABLE content_items DROP CONSTRAINT content_items_kind_check;
ALTER TABLE content_items
    ADD CONSTRAINT content_items_kind_check CHECK (kind IN ('notice','tip','faq','banner','legal','news')) NOT VALID;
ALTER TABLE content_items VALIDATE CONSTRAINT content_items_kind_check;
