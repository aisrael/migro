-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE foo (
    id SERIAL NOT NULL UNIQUE PRIMARY KEY
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE foo;
