-- passengers that has a same driver for all of their rides since 1995-02-20
SELECT
    *
FROM
    passengers
WHERE
    EXISTS (
        SELECT
            id
        FROM
            drivers
        WHERE
            id = ALL (
                SELECT
                    driver_id
                FROM
                    rides
                WHERE
                    event_name = 'ride_accepted'
                    AND passenger_id = passengers.id
                    AND created_at > '1995-02-10'));

-- passengers who their name start with a T and have at least one canceled rides
SELECT
    *
FROM
    passengers
WHERE
    id = ANY (
        SELECT
            passenger_id
        FROM
            rides
        WHERE
            event_name = 'ride_cancelled'
            AND driver_id IS NULL)
    AND first_name LIKE 'T%';

