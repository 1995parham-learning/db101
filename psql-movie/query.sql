CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT
    store.store_id,
    category.name,
    count(film.film_id)
FROM
    store,
    rental,
    film,
    inventory,
    staff,
    film_category,
    category
WHERE
    store.store_id = staff.store_id
    AND rental.staff_id = staff.staff_id
    AND rental.inventory_id = inventory.inventory_id
    AND inventory.film_id = film_category.film_id
    AND film_category.film_id = category.category_id
GROUP BY
    store.store_id,
    category.name
ORDER BY
    store_id;

SELECT
    *
FROM
    crosstab ('select store.store_id, category.category_id, count(film.film_id) from store, rental, film, inventory, staff, film_category, category where
  store.store_id = staff.store_id and rental.staff_id = staff.staff_id and
  rental.inventory_id = inventory.inventory_id and inventory.film_id = film_category.film_id and
  film_category.film_id = category.category_id
  group by store.store_id, category.category_id order by store_id', 'select category_id from category limit 2')
    AS (store int, cat1 int, cat2 int);

SELECT
    film.film_id,
    payment.yyear,
    payment.mmonth,
    payment.dday,
    sum(payment.amount)
FROM
    film,
    rental,
    (
        SELECT
            amount,
            rental_id,
            extract(year FROM payment_date) AS yyear,
            extract(month FROM payment_date) AS mmonth,
            extract(day FROM payment_date) AS dday
        FROM
            payment) AS payment,
    inventory
WHERE
    film.film_id = inventory.film_id
    AND inventory.inventory_id = rental.inventory_id
    AND payment.rental_id = rental.rental_id
GROUP BY
    film.film_id,
    payment.yyear,
    payment.mmonth,
    payment.dday
ORDER BY
    film.film_id;

SELECT
    film.film_id,
    payment.yyear,
    payment.mmonth,
    payment.dday,
    sum(payment.amount)
FROM
    film,
    rental,
    (
        SELECT
            amount,
            rental_id,
            extract(year FROM payment_date) AS yyear,
            extract(month FROM payment_date) AS mmonth,
            extract(day FROM payment_date) AS dday
        FROM
            payment) AS payment,
    inventory
WHERE
    film.film_id = inventory.film_id
    AND inventory.inventory_id = rental.inventory_id
    AND payment.rental_id = rental.rental_id
GROUP BY
    ROLLUP (film.film_id, payment.yyear, payment.mmonth, payment.dday)
ORDER BY
    film.film_id;

SELECT
    film.film_id,
    payment.yyear,
    payment.mmonth,
    payment.dday,
    sum(payment.amount)
FROM
    film,
    rental,
    (
        SELECT
            amount,
            rental_id,
            extract(year FROM payment_date) AS yyear,
            extract(month FROM payment_date) AS mmonth,
            extract(day FROM payment_date) AS dday
        FROM
            payment) AS payment,
    inventory
WHERE
    film.film_id = inventory.film_id
    AND inventory.inventory_id = rental.inventory_id
    AND payment.rental_id = rental.rental_id
GROUP BY
    CUBE (film.film_id,
        payment.yyear,
        payment.mmonth,
        payment.dday)
ORDER BY
    film.film_id;

SELECT
    film.title,
    category.name,
    film.length,
    rank() OVER (PARTITION BY category.name ORDER BY length)
FROM
    category,
    film,
    film_category
WHERE
    film.film_id = film_category.film_id
    AND film_category.category_id = category.category_id;

