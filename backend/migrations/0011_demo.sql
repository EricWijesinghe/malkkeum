-- Demo sample data registry. `api demo load` lists every row it inserts (table name + primary key as
-- text) so `api demo clear` deletes exactly those rows. Real data never appears here.
CREATE TABLE demo_rows (
    tbl         TEXT NOT NULL,
    row_key     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (tbl, row_key)
);
