CREATE TYPE ride_event AS enum (
    'ride_requested',
    'ride_accepted',
    'ride_boarded',
    'ride_finished',
    'ride_not_accepted',
    'ride_cancelled'
);

CREATE TABLE IF NOT EXISTS passengers (
    id serial PRIMARY KEY,
    first_name text,
    last_name text,
    national_id text
);

CREATE TABLE IF NOT EXISTS drivers (
    id serial PRIMARY KEY,
    first_name text,
    last_name text,
    national_id text
);

CREATE TABLE IF NOT EXISTS rides (
    id bigint,
    passenger_id int DEFAULT NULL REFERENCES passengers (id),
    driver_id int DEFAULT NULL REFERENCES drivers (id),
    event_name ride_event NOT NULL,
    created_at timestamp NOT NULL DEFAULT now()
);

-- passengers
INSERT INTO passengers (first_name, last_name, national_id)
    VALUES ('Test1', 'Passenger', '1234');

INSERT INTO passengers (first_name, last_name, national_id)
    VALUES ('Test2', 'Passenger', '1235');

-- drivers
INSERT INTO drivers (first_name, last_name, national_id)
    VALUES ('Test1', 'Driver', '1234');

INSERT INTO drivers (first_name, last_name, national_id)
    VALUES ('Test2', 'Driver', '1235');

INSERT INTO drivers (first_name, last_name, national_id)
    VALUES ('Test2', 'Passenger', '1235');

-- successfully completed ride
INSERT INTO rides (id, passenger_id, event_name)
    VALUES (1, 1, 'ride_requested');

INSERT INTO rides (id, passenger_id, driver_id, event_name)
    VALUES (1, 1, 1, 'ride_accepted');

INSERT INTO rides (id, passenger_id, driver_id, event_name)
    VALUES (1, 1, 1, 'ride_boarded');

INSERT INTO rides (id, passenger_id, driver_id, event_name)
    VALUES (1, 1, 1, 'ride_finished');

-- not accepted ride
INSERT INTO rides (id, passenger_id, event_name)
    VALUES (2, 1, 'ride_requested');

INSERT INTO rides (id, passenger_id, event_name)
    VALUES (2, 1, 'ride_not_accepted');

-- cancelled ride after request
INSERT INTO rides (id, passenger_id, event_name)
    VALUES (3, 1, 'ride_requested');

INSERT INTO rides (id, passenger_id, event_name)
    VALUES (3, 1, 'ride_cancelled');

-- cancelled ride after accept
INSERT INTO rides (id, passenger_id, event_name)
    VALUES (4, 1, 'ride_requested');

INSERT INTO rides (id, passenger_id, driver_id, event_name)
    VALUES (4, 1, 1, 'ride_accepted');

INSERT INTO rides (id, passenger_id, driver_id, event_name)
    VALUES (4, 1, 1, 'ride_cancelled');

