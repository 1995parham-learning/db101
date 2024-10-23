CREATE DATABASE elahe;

CREATE TABLE persons (
    id int,
    name text,
    username text
);

INSERT INTO persons
    VALUES (1, 'Elahe Dastan', 'eldaa');

INSERT INTO persons
    VALUES (2, 'Sara Dastan', 'sdaa');

INSERT INTO persons
    VALUES (3, 'Negin Amjadi', 'nj');

INSERT INTO persons
    VALUES (4, 'John Duo', 'john');

-- check the following link to know more about
-- creating roles:
-- https://www.postgresql.org/docs/current/sql-createrole.html
-- create a user (role) with name `superman` and superuser access.
CREATE ROLE superman LOGIN superuser PASSWORD 'suerpman';

-- print current user;
SELECT
    CURRENT_USER;

-- create user (role) `the_group` with role creation permission and password expiration time.
CREATE ROLE the_group createrole valid until '25 Apr 2045';

-- create users (roles) testrole1 and testrole2 that only has login access.
CREATE ROLE testrole1 LOGIN PASSWORD 'login1';

CREATE ROLE testrole2 LOGIN PASSWORD 'login2';

-- join testrole1 and testrole2 to the_group role;
GRANT the_group TO testrole1;

GRANT the_group TO testrole2;

-- enable inheritance on testrole1
ALTER ROLE testrole1 inherit;

-- ignore row level security  on testrole1
ALTER ROLE testrole1 bypassrls;

-- change role name
ALTER ROLE testrole2 RENAME TO newtestrole2;

-- grant testrole1 to select on persons;
GRANT SELECT ON persons TO testrole1;

-- enable row level security on persons
ALTER TABLE persons ENABLE ROW LEVEL SECURITY;

-- create policy on persons
CREATE POLICY persons_policy ON persons
    FOR SELECT
        USING (id > 3);

-- delete newtestrole2
DROP ROLE newtestrole2;

