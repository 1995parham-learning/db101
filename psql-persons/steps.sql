-- create a simple table for storing first_name and last_name of persons.
CREATE TABLE IF NOT EXISTS persons (
    first_name text,
    last_name text
);

INSERT INTO persons
    VALUES ('Elahe', 'Dastan');

INSERT INTO persons
    VALUES ('Sara', 'Dastan');

ALTER TABLE IF EXISTS persons
    ADD COLUMN IF NOT EXISTS id text;

INSERT INTO persons
    VALUES ('Negin', 'Amjadi', '0017784646');

CREATE VIEW persons_name_view AS
SELECT
    first_name,
    last_name
FROM
    persons;

