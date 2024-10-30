-- read phone number as a text and then detects its type, city and reports them.
CREATE OR REPLACE PROCEDURE phone (phone_number text)
LANGUAGE plpgsql
AS $$
BEGIN
    IF phone_number LIKE '0912%' THEN
        RAISE info 'mobile phone number';
        elseif phone_number LIKE '021%' THEN
        RAISE info 'city=tehran,city code=021,last 8 digits=%', substring(phone_number, 4, 8);
        elseif phone_number LIKE '031%' THEN
        RAISE info 'city=esfahan,city code=031,last 8 digits=%', substring(phone_number, 4, 8);
    END IF;
END
$$;

-- reports films that are rented between given dates
CREATE OR REPLACE FUNCTION renteds (IN begin_date date, IN end_date date)
    RETURNS TABLE (
        title varchar(255),
        film_id int)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN query
    SELECT
        film.title,
        film.film_id
    FROM
        rental,
        inventory,
        film
    WHERE
        rental.rental_id = inventory.inventory_id
        AND inventory.film_id = film.film_id
        AND rental.rental_date > begin_date
        AND rental.rental_date < end_date;
END
$$;

-- reports customers that rent films rented between given dates but do not return them
CREATE OR REPLACE FUNCTION bad_customers (IN begin_date date, IN end_date date)
    RETURNS TABLE (
        customer_id smallint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN query
    SELECT
        rental.customer_id
    FROM
        renteds (begin_date, end_date),
        inventory,
        rental,
        film
    WHERE
        rental.rental_id = inventory.inventory_id
        AND inventory.film_id = renteds.film_id
        AND rental.return_date IS NULL;
END
$$;

-- log table collects the status of rentals
CREATE TABLE IF NOT EXISTS rental_logs (
    customer_id smallint,
    duration interval
);

-- procedure will be called on insert or update of rental table to calculate the rent duration.
CREATE OR REPLACE FUNCTION on_rental_procedure ()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    film_duration interval;
    actual_duration interval;
BEGIN
    SELECT
        film.rental_duration INTO film_duration
    FROM
        film,
        inventory
    WHERE
        inventory.inventory_id = NEW.inventory_id
        AND inventory.film_id = film.film_id;
    SELECT
        NEW.return_date - NEW.rental_date INTO actual_duration;
    IF actual_duration > film_duration THEN
        INSERT INTO rental_logs
        VALUES (
            NEW.customer_id,
            actual_duration);
    END IF;
END
$$;

-- trigger that check the rent duration for rental_logs tbale.
CREATE TRIGGER on_rental
    BEFORE INSERT OR UPDATE ON rental
    EXECUTE PROCEDURE on_rental_procedure ();

-- update every film row to increase rent duration.
CREATE OR REPLACE PROCEDURE increase_duration (inc int)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE
        film
    SET
        rental_duration = rental_duration + inc;
END
$$;

