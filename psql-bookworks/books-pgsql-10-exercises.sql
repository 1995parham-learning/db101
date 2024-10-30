/**	PostgreSQL Quirks
	================================================
	This works:
		SELECT cast('tomorrow' as date) AS birthday;
	Set Auto Number after INSERTS:
		SELECT setval(pg_get_serial_sequence('customers', 'id'), max(id)) FROM customers;
	================================================ */

/**	Chapter2: Working with Table Design
	================================================
	================================================ */

/*	2.01: View Table
	================================================
	================================================ */

	SELECT
		id, givenname, familyname,
		street, town, state, postcode
	FROM customers;

/*	2.02: Add townid Foreign Key
	================================================
	================================================ */

	ALTER TABLE customers
	ADD townid INT REFERENCES towns(id);

	ALTER TABLE customers
	ADD CONSTRAINT fk_customers_town FOREIGN KEY(townid)
		REFERENCES towns(id);

/*	2.03: View Foreign Table Data
	================================================
	================================================ */

	SELECT
		id, givenname, familyname,
		town, state, postcode,				--	existing data
		(SELECT id FROM towns AS t WHERE	--	new data
			t.name=customers.town
			AND t.postcode=customers.postcode
			AND t.state=customers.state
		) AS reference
	FROM customers;

/*	2.04: Update Customers Table to include Foreign Key
	================================================
	================================================ */

	UPDATE customers
	SET townid=(
		SELECT id FROM towns AS t
		WHERE t.name=customers.town
			AND t.postcode=customers.postcode
			AND t.state=customers.state
	);

/*	2.05: Select from Joined Tables
	================================================
	================================================ */

	SELECT
		c.id, c.email, c.familyname, c.givenname,
		c.street,
		--	original values
			c.town, c.state, c.postcode,
		c.townid,
		--	from towns table
			t.name AS town, t.state, t.postcode,
		c.dob, c.phone, c.spam, c.height
	FROM customers AS c LEFT JOIN towns AS t ON c.townid=t.id;

/*	2.06: Create customerdetails View
	================================================
	================================================ */

	CREATE VIEW customerdetails AS
	SELECT
		c.id, c.email, c.familyname, c.givenname,
		c.street,
		--	c.town, c.state, c.postcode,
		c.townid,
		t.name AS town, t.state, t.postcode,
		c.dob, c.phone, c.spam, c.height
	FROM customers AS c LEFT JOIN towns AS t ON c.townid=t.id;

/*	02.07a	Drop Old Customer Address Columns
	================================================
	================================================ */

	ALTER TABLE customers
	DROP COLUMN town, DROP COLUMN state, DROP COLUMN postcode;

/*	02.08a	Change the Town via the townid
	================================================
	================================================ */

	--	Get old values
		SELECT * FROM customerdetails WHERE id=42;

	--	Change Town
		UPDATE customers SET townid=12345 WHERE id=42;
		SELECT * FROM customerdetails WHERE id=42;

	--	Restore, if you like
		UPDATE customers SET townid=0 WHERE id=42;		--	use original townid value
		SELECT * FROM customerdetails WHERE id=42;

/*	2.09: Add countryid to towns Table
	================================================
	================================================ */

	ALTER TABLE towns
	ADD countryid CHAR(2)
	CONSTRAINT fk_town_country REFERENCES countries(id);

/*	2.10: Set countryid to au
	================================================
	================================================ */

	UPDATE towns SET countryid='au';

/*	2.11: Modify View
	================================================
	================================================ */

	DROP VIEW IF EXISTS customerdetails;

	CREATE VIEW customerdetails AS
	SELECT
		c.id, c.email, c.familyname, c.givenname,
		c.street,
		c.townid, t.name AS town, t.state, t.postcode,
		n.name AS country,
		c.dob, c.phone, c.spam, c.height
	FROM
		customers AS c
		LEFT JOIN towns AS t ON c.townid=t.id
		LEFT JOIN countries AS n ON t.countryid=n.id;

/*	2.12: Coalesce NULL quantities in saleitems
	================================================
	================================================ */

	SELECT
		id, saleid, bookid,
		coalesce(quantity, 1) AS quantity, price
	FROM saleitems
	ORDER BY saleid, id;

/*	2.13: Replace NULLs in saleitems
	================================================
	================================================ */

	UPDATE saleitems
	SET quantity=1
	WHERE quantity IS NULL;

/*	2.14: Add NOT NULL to saleitems.quantity
	================================================
	================================================ */

	ALTER TABLE saleitems
	ALTER COLUMN quantity SET NOT NULL;

/*	2.15: Add DEFAULT 1 for saleitems.quantity
	================================================
	================================================ */

	ALTER TABLE saleitems
	ALTER COLUMN quantity SET DEFAULT 1;

/*	2.16: Add CHECK Positive saleitems.quantity
	================================================
	================================================ */

	ALTER TABLE saleitems
	ADD CHECK (quantity>0);

/*	2.17: Combine Changes
	================================================
	================================================ */

	ALTER TABLE saleitems
		ALTER COLUMN quantity SET NOT NULL,
		ALTER COLUMN quantity SET DEFAULT 1,
		ADD CHECK (quantity>0);

/*	2.18: N/A
	================================================
	================================================ */

/*	2.19: Non-Negative Prices
	================================================
	================================================ */

	ALTER TABLE books ADD CHECK (price>=0);

/*	2.20: Check authors.born<authors.died
	================================================
	================================================ */

	ALTER TABLE authors ADD CHECK (born<died);

/*	2.21: Create Index on books.title
	================================================
	================================================ */

	CREATE INDEX ix_books_title
	ON books(title);

/*	2.22: Create Index on authors.name
	================================================
	================================================ */

	CREATE INDEX ix_authors_name
	ON authors(familyname, givenname, othernames);

/*	2.23: Create Index on authorid Foreign Key
	================================================
	================================================ */

	CREATE INDEX ix_books_authors
	ON books(authorid);

/*	2.24: Find Duplicate Customer Names
	================================================
	================================================ */

	--	Count Distinct Names
		SELECT familyname, givenname, count(*) AS number
		FROM customers
		GROUP BY familyname, givenname;

	--	Filter Duplicates
		SELECT familyname, givenname, count(*) AS number
		FROM customers
		GROUP BY familyname, givenname
		HAVING count(*)>1;


/*	2.25: Find Duplicate Customer phones
	================================================
	================================================ */

	SELECT phone, count(*) AS number
	FROM customers
	GROUP BY phone
	HAVING count(*)>1;

/*	2.26: Unique Index on customers.phone
	================================================
	================================================ */

	CREATE UNIQUE INDEX uq_customers_phone
	ON customers(phone);

/**	Chapter3: Table Relationships and Joins
	================================================
	================================================ */

/*	3.01: books (INNER) JOIN authors
	================================================
	================================================ */

	SELECT
		b.id, b.title,				--  etc
		a.givenname, a.familyname	--	etc
	FROM books AS b JOIN authors AS a ON b.authorid=a.id;

/*	3.02: books LEFT (OUTER) JOIN authors
	================================================
	================================================ */

	SELECT
		b.id, b.title,				--  etc
		a.givenname, a.familyname	--	etc
	FROM books AS b LEFT JOIN authors AS a ON b.authorid=a.id;


/*	3.03: Counting JOINs
	================================================
	JOIN 				Calculation
	------------------------------------------------
	INNER JOIN 			INNER JOIN
	Child OUTER JOIN	INNER JOIN + Unmatched Children= Children
	Parent OUTER JOIN	INNER JOIN + Unmatched Parents
	Full OUTER JOIN		INNER JOIN + Unmatched Children + Unmatched Parents
	================================================ */

	--	Child Inner Join
		SELECT count(*) FROM books WHERE authorid IS NOT NULL;

	--	Unmatched Children
		SELECT count(*) FROM books WHERE authorid IS NULL;

	--	Unmatched Parents
		SELECT count(*) FROM authors
		WHERE id NOT IN(SELECT authorid FROM books WHERE authorid IS NOT NULL);

/*	3.04: NOT IN Quirk
	================================================
	================================================ */

	--	IN VIC, QLD
		SELECT * FROM customerdetails
		WHERE state IN ('VIC', 'QLD');

	--	NOT IN VIC, QLD
		SELECT * FROM customerdetails
		WHERE state NOT IN ('VIC', 'QLD');

	--	With NULL
		SELECT * FROM customerdetails
		WHERE state IN ('VIC', 'QLD', NULL);

		SELECT * FROM customerdetails
		WHERE state='VIC' OR state='QLD' OR state=NULL;

	--	However, NOT IN with NULL fails:
		SELECT * FROM customerdetails
		WHERE state NOT IN ('VIC', 'QLD', NULL);

		SELECT * FROM customerdetails
		WHERE state<>'VIC' AND state<>'QLD' AND state<>NULL;

/*	3.05: DROP & CREATE bookdetails VIEW
	================================================
	================================================ */

	--	Drop old version
		DROP VIEW IF EXISTS bookdetails;

	--	(Re) create view
		CREATE VIEW bookdetails AS
		SELECT
			b.id, b.title, b.published, b.price,
			a.givenname, a.othernames, a.familyname,
			a.born, a.died, a.gender, a.home
		FROM
			books AS b
			LEFT JOIN authors AS a ON b.authorid=a.id
		;

	--	Read View
		SELECT * FROM bookdetails;

/*	3.06: One-Maybe Customers & VIP
	================================================
	================================================ */

	SELECT * FROM customers ORDER BY id;
	SELECT * FROM vip ORDER BY id;

	--	All Customers & VIP
		SELECT c.*, v.*
		FROM customers AS c LEFT JOIN vip AS v ON c.id=v.id;

	--	VIP Customers
		SELECT c.*
		FROM customers AS c JOIN vip AS v ON c.id=v.id;

/*	3.07: Many to Many Tables
	================================================
	================================================ */

	--	books & genres
		SELECT * FROM books;
		SELECT * FROM genres;

	--	bookgenres
		SELECT * FROM bookgenres;

	--	joined
		SELECT *
		FROM
			bookgenres AS bg
			JOIN books AS b ON bg.bookid=b.id
			JOIN genres AS g ON bg.genreid=g.id
		;

		SELECT *
		FROM
			books AS b
			JOIN bookgenres AS bg ON b.id=bg.bookid
			JOIN genres AS g ON bg.genreid=g.id
		;

/*	3.08: Summarising genres
	================================================
	string_agg(genre, ', ') AS genres
	================================================ */

	WITH cte AS (
		SELECT b.id, b.title, g.genre
		FROM
			bookgenres AS bg
			JOIN books AS b ON bg.bookid=b.id
			JOIN genres AS g ON bg.genreid=g.id
	)
	SELECT
		id, title,
		count(*) AS ncategories,	--	not really needed
		string_agg(genre, ', ') AS genres
	FROM cte
	GROUP BY id, title
	ORDER BY id;

/*	3.09: Combining the Joins
	================================================
	================================================ */

	SELECT
		b.id, b.title, b.published, b.price,
		g.genre,
		a.givenname, a.othernames, a.familyname,
				a.born, a.died, a.gender, a.home
	FROM
		authors AS a
		RIGHT JOIN books AS b ON a.id=b.authorid
		LEFT JOIN bookgenres AS bg ON b.id=bg.bookid
		JOIN genres AS g ON bg.genreid=g.id
	;

	SELECT
		b.id, b.title, b.published, b.price,
		g.genre,
		a.givenname, a.othernames, a.familyname,
		a.born, a.died, a.gender, a.home
	FROM
		books AS b
		LEFT JOIN bookgenres AS bg ON b.id=bg.bookid
		JOIN genres AS g ON bg.genreid=g.id
		LEFT JOIN authors AS a ON b.authorid=a.id
	;

/*	3.10: Joining with the bookdetails View
	================================================
	================================================ */

	SELECT
		bd.id, bd.title, bd.published, bd.price,
		g.genre,
		bd.givenname, bd.othernames, bd.familyname,
		bd.born, bd.died, bd.gender, bd.home
	FROM
		bookdetails AS bd
		LEFT JOIN bookgenres AS bg ON bd.id=bg.bookid
		JOIN genres AS g ON bg.genreid=g.id;

/*	3.11: Joining with Summarised Genres
	================================================
	================================================ */

	WITH cte AS (
		SELECT bg.bookid, string_agg(g.genre, ', ') AS genres
		FROM bookgenres AS bg JOIN genres AS g ON bg.genreid=g.id
		GROUP BY bg.bookid
	)
	SELECT *
	FROM bookdetails AS b JOIN cte ON b.id=cte.bookid;

/*	3.12: Filtering the Genres
	================================================
	================================================ */

	WITH cte AS (
		SELECT bg.bookid, string_agg(g.genre, ', ') AS genres
		FROM bookgenres AS bg JOIN genres AS g ON bg.genreid=g.id
		WHERE g.genre IN('Fantasy', 'Science Fiction')
		GROUP BY bg.bookid
	)
	SELECT *
	FROM bookdetails AS b JOIN cte ON b.id=cte.bookid;

/*	3.13: Books and Multiple AUthors
	================================================
	================================================ */

	SELECT *
	FROM
		multibooks AS b
		JOIN authorship AS ba ON b.id=ba.bookid
		JOIN multiauthors AS a ON ba.authorid=a.id;

/*	3.14: Combining Multiple Authors
	================================================
	================================================ */

	WITH cte AS (
		SELECT
			ba.bookid,
			string_agg(a.givenname||' '||a.familyname, ' & ') AS authors
		FROM authorship AS ba JOIN multiauthors AS a ON ba.authorid=a.id
		GROUP BY ba.bookid
	)
	SELECT b.id, b.title, cte.authors
	FROM multibooks AS b JOIN cte ON b.id=cte.bookid
	ORDER BY b.id;

/*	3.15: Adding an Author
	================================================
	================================================ */

	--	Check whether author exists
		SELECT * FROM authors WHERE familyname='Christie';

	--	Don’t run this yet:
		INSERT INTO authors(givenname, othernames, familyname,
			born, died, gender, home)
		VALUES('Agatha', 'Mary Clarissa', 'Christie',
			'1890-09-15', '1976-01-12', 'f',
			'Tourquay, Devon, England');

/*	3.16: Getting the new ID
	================================================
	Take note of the id!
	================================================ */

	INSERT INTO authors(givenname, othernames, familyname,
		born, died, gender, home)
	VALUES('Agatha', 'Mary Clarissa', 'Christie',
		'1890-09-15', '1976-01-12', 'f',
		'Tourquay, Devon, England')
	RETURNING id;					--	Take note of this!

/*	3.17: Adding a Book
	================================================
	================================================ */

	SELECT * FROM authors WHERE familyname='Christie';

	--	Use the author’s id:
		INSERT INTO books(authorid, title, published, price)
		VALUES (0, 'The Mysterious Affair at Styles', 1920, 16.00);	--	use id value from above

/*	3.18: Adding a Sale
	================================================
	================================================ */

	INSERT INTO sales(customerid, ordered)
	VALUES (42, current_timestamp)
	RETURNING id;					--	Take note of this!

/*	3.19: Adding Sale Items
	================================================
	================================================ */

	INSERT INTO saleitems(saleid, bookid, quantity)
	VALUES
		(0, 123, 3),		--	use id value from above
		(0, 456, 1),
		(0, 789, 2);

/*	3.20: Get Book Prices
	================================================
	================================================ */

	UPDATE saleitems
	SET price=(SELECT price FROM books WHERE books.id=saleitems.bookid)
	WHERE saleid=0;				--	use id value from above

/*	3.21: Completing the Sale
	================================================
	Need to add VIP discount and Tax
	================================================ */

	--	Don’t run yet
		SELECT sum(quantity*price)
		FROM saleitems
		WHERE saleid=0;			--	use id value from above

/*	3.22: Including Tax & VIP Discount
	================================================
	================================================ */

	--	Tax (10%)
		SELECT sum(quantity*price) * (1 + 0.10)
		FROM saleitems
		WHERE saleid=0;			--	use id value from above

	--	VIP Discount
		SELECT 1 - discount FROM vip WHERE id = 42 ;

	--	Nearly Complete: some discounts are null
		SELECT
			sum(quantity*price)
			* (1 + 0.1)
			* (SELECT  1 - discount FROM vip WHERE id = 42)
		FROM saleitems
		WHERE saleid=0;			--	use id value from above

	--	Coalesce NULL discounts
		SELECT
			sum(quantity*price)
			* (1 + 0.1)
			* coalesce((SELECT  1 - discount FROM vip WHERE id = 42), 1)
		FROM saleitems
		WHERE saleid=0;			--	use id value from above

/*	3.23: Completed Sale
	================================================
	================================================ */

	UPDATE sales
	SET total = (
		SELECT
			sum(quantity*price)
			* (1 + 0.1)
			* coalesce((SELECT  1 - discount FROM vip WHERE id=42), 1)
		FROM saleitems
		WHERE saleid=0			--	use id value from above
	)
	WHERE id=0;					--	use id value from above

	SELECT * FROM sales ORDER BY id DESC;
	SELECT * FROM saleitems ORDER BY id DESC;

/**	Chapter4: Working with Calculated Data
	================================================
	================================================ */

/*	4.01: Basics
	================================================
	================================================ */

	--	Calculating on Columns
		SELECT
			height/2.54,				--	single column
			givenname||' '||familyname	--	multiple columns
		FROM customers;

	--	Hard-Coded & Subqueries
		SELECT
			'active',									--	hard-coded
			(SELECT name FROM towns WHERE id=townid)	--	sub query
		FROM customers;

	--	Built-in Functions
		SELECT
			upper(familyname)			--	upper case function
		FROM customers;

/*	4.02: Using Aliases
	================================================
	-	You can alias non-calculated columns
	-	You can alias to a column name
	================================================ */

	SELECT
		id AS customer,
		height/2.54 AS height,
		givenname||' '||familyname AS fullname,
		'active' AS status,
		(SELECT name FROM towns WHERE id=townid) AS town,
		length(email) AS length
	FROM customers;

/*	4.03: Aliases with Double Quotes
	================================================
	================================================ */

	SELECT
		ordered AS "order",
		shipped AS "shipped date"
	FROM sales;

/*	4.04: AS is Optional
	================================================
	================================================ */

	SELECT
		id customer,
		height/2.54 height,
		givenname||' '||familyname fullname,
		'active' status,
		(SELECT name FROM towns WHERE id=townid) town,
		length(email) length
	FROM customers;

/*	4.05: Forgetting a Comma
	================================================
	================================================ */

	SELECT
		id,
		email
		givenname, familyname,
		height,
		dob
	FROM customers;


/*	4.06: Can’t use Alias in WHERE Clause
	================================================
	================================================ */

	SELECT id, title, price, price*0.1 AS tax
	FROM books
	WHERE tax<1.5;

	SELECT
		id, title,
		price*1.1 AS price	--	adjust to include tax
	FROM books
	WHERE price<15;			--	original price

/*	4.07: Calculating with NULLS
	================================================
	================================================ */

	SELECT
		id, givenname, familyname,
		height/2.54 AS height		--	sometimes NULL
	FROM customers;

/*	4.08: NULLs Ruin the Rest of the Calculation
	================================================
	================================================ */

	SELECT
		id, givenname, othernames, familyname,
		givenname||' '||othernames||' '||familyname AS fullname
	FROM authors;

/*	4.09: Coalesce Phone Numbers
	================================================
	================================================ */

	SELECT
		id, givenname, familyname,
		phone
	FROM employees;

	SELECT
		id, givenname, familyname,
		coalesce(phone, '1300975711')	--	coalesce to main number
	FROM employees;

/*	4.10: Coalesce Missing Strings
	================================================
	================================================ */

	SELECT
		id, givenname, othernames, familyname,
		coalesce(givenname||' ', '')
			||coalesce(othernames||' ', '')
			||familyname AS fullname
	FROM authors;

/*	4.11: Calculations in WHERE clause
	================================================
	================================================ */

	SELECT *
	FROM books
	WHERE length(title)<24;

	--	Case-Sensitive String Comparison
		SELECT *
		FROM books
		WHERE lower(title) LIKE '%journey%';

/*	4.12: Using Aggregate Subqueries
	================================================
	================================================ */

	SELECT *
	FROM customers
	WHERE height<(SELECT avg(height) FROM customers);

/*	4.13: Calculations in ORDER BY clause
	================================================
	================================================ */

	SELECT *
	FROM books
	ORDER BY length(title);

	--	Include Calculation in SELECT Clause
		SELECT id, authorid, title, length(title) AS len, published, price
		FROM books
		ORDER BY len;

/*	4.14: Emulate NULLS FIRST | LAST
	================================================
	================================================ */

	SELECT *
	FROM customers
	ORDER BY coalesce(height, 0);	--	NULLS FIRST

	SELECT *
	FROM customers
	ORDER BY coalesce(height, 1000);	--	NULLS LAST

/*	4.15: Casting Withing Major Type
	================================================
	================================================ */

	--	shorter dates & numbers
		SELECT
			cast(ordered as date) AS ordered_date,
			cast(total AS integer) AS whole_dollars
		FROM sales;

	--	shorter strings
		SELECT cast(title AS varchar(16)) AS short_title
		FROM books;

	--	broader dates & numbers
		SELECT
			cast(dob as timestamp) as long_dob,
			cast(height as decimal(5,2)) as long_height
		FROM customers;

/*	4.16: Concatenating Numbers
	================================================
	================================================ */

	SELECT id || ': ' || email
	FROM customers;

/*	4.17: Concatenating Dates
	================================================
	================================================ */

	SELECT
		id || ': ' || email || coalesce('  Born: ' || dob, '')
	FROM customers;

/*	4.18: Casting from Strings
	================================================
	================================================ */

	--	Integers
		SELECT * FROM sorting
		ORDER BY numberstring;
		SELECT * FROM sorting
		ORDER BY cast(numberstring as int);

	--	Dates
		SELECT * FROM sorting
		ORDER BY datestring;
		SELECT * FROM sorting
		ORDER BY cast(datestring as date);


/*	04.19 Unsuccessful Casts
	================================================
	PostgreSQL:
		cast_int(string varchar,planB int default null) returns int
	================================================ */

	DROP FUNCTION IF EXISTS cast_int;
	CREATE FUNCTION cast_int(string varchar, planB int default null) RETURNS INT AS $$
		BEGIN
			RETURN floor(cast(string as numeric));
		EXCEPTION
			WHEN OTHERS THEN return planB;
		END
	$$ LANGUAGE plpgsql;


	--	This works:
		SELECT cast('23' as int);

	--	This doesn’t:
		SELECT cast('hello' as int);

	--	This works:
		SELECT cast_int('hello', 42);

/*	4.20: Basic Arithmetic
	================================================
	================================================ */

	SELECT
		3*5 AS multiplication,
		4+7 AS addition,
		8-11 AS subtraction,
		20/3 AS division,
		20%3 AS remainder,
		24/3*5 AS associativity,
		1+2*3 AS precedence,
		2*(3+4) + 5*(8-5) AS distributive
	;

/*	4.21: Mathematical Functions
	================================================
	================================================ */

	SELECT
		pi() AS pi,
		sin(radians(45)) AS sin45,
		sqrt(2) AS root2,			--	√2
		log10(3) AS log3,
		ln(10) AS ln10,				--	Natural Logarithm
		power(4,3) AS four_cubed	--	4³
	;

/*	4.22: Approximation Functions
	================================================
	================================================ */

	SELECT
		ceiling(200/7.0) AS ceiling,
		floor(200/7.0) AS floor,
		round(200/7.0, 0) AS rounded_integer,
		round(200/7.0, 2) AS rounded_decimal
	;

/*	4.23: Casting to narrow number type
	================================================
	================================================ */

	SELECT
		cast(234.567 AS int) AS castint,
		cast(234.567 AS decimal(5,2)) AS castdec
	;

/*	4.24: Formatting Numbers
	================================================
	================================================ */

	SELECT
		to_char(total, 'FM999G999G999D00') AS local_number,
		to_char(total, 'FML999G999G999D00') AS local_currency
	FROM sales;

	SELECT to_char(total, 'FM$999,999,999.00') FROM sales;

/*	4.25: String Literal
	================================================
	================================================ */

	SELECT 'hello';

/*	4.26: Case Sensitivity Test
	================================================
	================================================ */

	SELECT * FROM customers WHERE 'a'='A';

/*	4.27: Concatenation
	================================================
	================================================ */

	SELECT
		id,
		givenname||' '||familyname AS fullname
	FROM customers;

	SELECT
		id,
		concat(givenname, ' ', familyname) AS fullname
	FROM customers;

/*	4.28: String Functions
	================================================
	================================================ */

	--	Length
		SELECT *, length(familyname) AS len
		FROM customers;

	--	Position
		SELECT *, position(' ' in title) AS space FROM books;

	--	replace(original, search, replace)
		SELECT *, replace(title, ' ', '-') AS hyphens
		FROM books;

	--	Upper / Lower Case
		SELECT
			*,
			upper(title) AS upper,
			lower(title) AS lower
		FROM books;

	--	Initial Caps
		SELECT *, initcap(title) AS initcaps FROM books;

	--	Trim
		WITH vars AS (
			SELECT ' abcdefghijklmnop ' AS string
		)
		SELECT
			string,
			ltrim(string) AS ltrim,
			rtrim(string) AS rtrim,
			trim(string) AS trim,
			ltrim(rtrim(string)) AS same
		FROM vars;

/*	4.29: Substrings
	================================================
	================================================ */

	WITH vars AS (
		SELECT 'abcdefghijklmnop' AS string
	)
	SELECT
		substr(string, 3, 5) AS substr,
		substring('abcdefghijklmnop', 3, 5) AS substring
	FROM vars;

	WITH vars AS (
		SELECT 'abcdefghijklmnop' AS string
	)
	SELECT
	--	Left
		left('abcdefghijklmnop', 4) AS lstring,
		substr(string, 1, 4) AS lstring_too,
	--	Right
		right('abcdefghijklmnop', 4) AS rstring
	FROM vars;

/*	4.30: Date Literals
	================================================
	================================================ */

	SELECT *
	FROM customers
	WHERE dob<'1980-01-01';

/*	4.31: Current Date & Time
	================================================
	================================================ */

	SELECT
		current_timestamp AS now,
		current_date AS today,
		cast(current_timestamp as date) AS same
	;

/*	4.32: Sorting by date/time
	================================================
	================================================ */

	SELECT *
	FROM sales
	ORDER BY ordered;

/*	4.33: Grouping by Shortened date/time
	================================================
	================================================ */

	WITH cte AS (
		SELECT cast(ordered as date) AS ordered, total
		FROM sales
	)
	SELECT ordered, sum(total)
	FROM cte
	GROUP BY ordered
	ORDER BY ordered;

/*	4.34: Extracting Parts of a Date / Time
	================================================
	extract(part from datetime)
	================================================ */

	WITH chelyabinsk AS (
		SELECT timestamp '2013-02-15 09:20:00' AS datetime
	)
	SELECT
		datetime,
		EXTRACT(year FROM datetime) AS year,
		EXTRACT(month FROM datetime) AS month,
		EXTRACT(day FROM datetime) AS day,
		EXTRACT(dow FROM datetime) AS weekday,
		EXTRACT(hour FROM datetime) AS hour,
		EXTRACT(minute FROM datetime) AS minute,
		EXTRACT(second FROM datetime) AS second
	FROM chelyabinsk;

/*	4.35: Date Formatting
	================================================
	to_char(data, format)
	================================================ */

	WITH vars AS (SELECT timestamp '1969-07-20 20:17:40' AS moonshot)
	SELECT
		moonshot,
		to_char(moonshot, 'FMDay, DDth FMMonth YYYY') AS fulldate,
		to_char(moonshot, 'Dy DD Mon YYYY') AS shortdate
	FROM vars;

/*	4.36: Adding Dates
	================================================
	================================================ */

	SELECT
		date '2015-10-31' + interval '4 months' AS afterthen,
		current_timestamp + interval '4 months' AS afternow,
		current_timestamp + interval '4' month	--	also OK
	;

/*	4.37: Subtracting Dates
	================================================
	================================================ */

	SELECT
		dob,
		age(dob) AS interval,
		date_part('year', age(dob)) AS years,
		extract(year from age(dob)) AS samething
	FROM customers;

/*	4.38: The CASE Expression
	================================================
	================================================ */

	SELECT
		id, title,
		CASE
			WHEN price<13 THEN 'cheap'
			WHEN price<=17 THEN 'reasonable'
			WHEN price>17 THEN 'expensive'
			--	ELSE NULL	--	default
			--	ELSE ''		--	alternative
		END AS price
	FROM books;

/*	4.39: Discrete Values
	================================================
	================================================ */

	SELECT
		c.id,
		givenname||' '||familyname AS name,
		CASE status
			WHEN 1 THEN 'Gold'
			WHEN 2 THEN 'Silver'
			WHEN 3 THEN 'Bronze'
		END AS status
	FROM customers AS c LEFT JOIN VIP ON c.id=vip.id;

/*	4.40: CASE Using IN(…)
	================================================
	================================================ */

	SELECT
		id, givenname, familyname,
		CASE
			WHEN state IN('QLD', 'NSW', 'VIC', 'TAS') THEN 'East'
			WHEN state IN ('NT', 'SA') THEN 'Central'
			ELSE 'Elsewhere'
		END AS region
	FROM customerdetails;

/*	4.41: Coalesce and CASE
	================================================
	================================================ */

	SELECT
		id, givenname, familyname,
		coalesce(phone, '-') AS coalesced,
		CASE
			WHEN phone IS NOT NULL THEN phone
			ELSE '-'
		END AS cased
	FROM customers;

/*	4.42: Nested CASE - Calculate Age
	================================================
	-	Shipped: Compare shipped to ordered
		-	14 days ⇒ Shipped Late
		-	Else Shipped
	-	Not Shipped: Compare Today to ordered
		-	< 7 days ⇒ Current
		-	< 14 days ⇒ Due
		-	Else Overdue
	================================================ */

	SELECT
		id, customerid, total,
		cast(ordered as date) AS ordered, shipped,
		current_date - cast(ordered as date) AS ordered_age,
		shipped - cast(ordered as date) AS shipped_age
	FROM sales
	WHERE ordered IS NOT NULL;

/*	4.43: Select shipped or not shipped
	================================================
	================================================ */

	WITH salesdata AS (
		SELECT
			id, customerid, total,
			cast(ordered as date) AS ordered, shipped,
			current_date - cast(ordered as date) AS ordered_age,
			shipped - cast(ordered as date) AS shipped_age
		FROM sales
		WHERE ordered IS NOT NULL
	)
	SELECT
		salesdata.*,
		CASE
			WHEN shipped IS NOT NULL THEN
				'Shipped Late or Shipped'
			ELSE
				'Current or Due or Overdue'
		END AS status
	FROM salesdata;

	WITH salesdata AS (
		SELECT
			id, customerid, total,
			cast(ordered as date) AS ordered, shipped,
			current_date - cast(ordered as date) AS ordered_age,
			shipped - cast(ordered as date) AS shipped_age
		FROM sales
		WHERE ordered IS NOT NULL
	)
	SELECT
		salesdata.*,
		CASE
			WHEN shipped IS NOT NULL THEN
				CASE
					WHEN shipped_age>14 THEN 'Shipped Late'
					ELSE 'Shipped'
				END
			ELSE
				CASE
					WHEN ordered_age<7 THEN 'Current'
					WHEN ordered_age<14 THEN 'Due'
					ELSE 'Overdue'
				END
		END AS status
	FROM salesdata;

/**	Chapter5: Aggregating Data
	================================================
	Clause Order:

	SELECT …
	FROM …
	WHERE …
	GROUP BY …
	--	SELECT
	ORDER BY …
	================================================ */

/*	5.01: Basic Summmaries
	================================================
	================================================ */

	SELECT
	--	Count Rows:
		count(*) AS nbooks,
	--	Count Values in a column:
		count(price) AS prices,
	--	Cheapest & Most Expensive
		min(price) AS cheapest, max(price) AS priciest
	FROM books;

/*	5.02: Numerical Statistics
	================================================
	================================================ */

	SELECT
	--	Count Rows:
		count(*) AS ncustomers,
	--	Count Values in a column:
		count(phone) AS phones,
	--	Height Statistics
		stddev_samp(height) AS sd
	FROM customers;

/*	05.03 Statistics on Dates
	================================================
	================================================ */

	SELECT
	--	Count Values in a column:
		count(dob) AS dobs,
	--	Earliest & Latest
		min(dob) AS earliest, max(dob) AS latest
	FROM customers;

/*	5.04: Understanding Aggregates
	================================================
	================================================ */

	SELECT
		count(*) AS rows,
		count(phone) AS phones
	FROM customers;

	SELECT
		count(*) AS rows,
		count(phone) AS phones
	FROM customers
	GROUP BY ()
	;

/*	5.05: Mixing Aggregates and Non-Aggregates
	================================================
	================================================ */

	SELECT
		id,		--	oops
		count(*) AS rows,
		count(phone) AS phones
	FROM customers;

/*	5.06: Grouping
	================================================
	================================================ */

	SELECT
		town, state,			--	grouping columns
		count(phone) AS phones,	--	summaries for each group:
		min(dob) AS oldest
	FROM customerdetails
	GROUP BY town, state;

/*	5.07: Aggregating Distinct Values
	================================================
	Distinct town names don’t necessarily imply
	distinct towns.
	================================================ */

	SELECT
		count(state) AS addresses,
		count(DISTINCT state) AS states
	FROM customerdetails;

	SELECT count(DISTINCT town) FROM customerdetails;

/*	5.08: Aggregate Filters
	================================================
	Only PostgreSQL supports FILTER(WHERE …)
	================================================ */

	SELECT
		count(*) FILTER (WHERE dob<'1980-01-01') AS older,
		count(*) FILTER (WHERE dob>='1980-01-01') AS younger
	FROM customers;

	SELECT
		count(CASE WHEN dob<'1980-01-01' THEN 1 END) AS old,
		count(CASE WHEN dob>='1980-01-01' THEN 1 END) AS young
	FROM customers;

/*	5.09: Aggregate Filters and SUM()
	================================================
	================================================ */

	--	New Standard
		SELECT
			sum(total),
			sum(total) FILTER (WHERE ordered <'2024-01-01') AS older,		--	use a date in the last six months
			sum(total) FILTER (WHERE ordered>='2024-01-01') AS newer			--	use the same date
		FROM sales;

	--	Alternative
		SELECT
			sum(total),
			sum(CASE WHEN ordered<'2024-01-01' THEN total END) AS older,		--	use a date in the last six months
			sum(CASE WHEN ordered>='2024-01-01' THEN total END) AS newer		--	use the same date
		FROM sales;

/*	5.10: Grouping by Calculated Values
	================================================
	Remember, SELECT is evaluated after GROUP BY
	================================================ */

	SELECT EXTRACT(month FROM dob) as monthnumber, count(*) AS howmany
	FROM customerdetails
	GROUP BY EXTRACT(month FROM dob)
	ORDER BY monthnumber;

/*	5.11: Grouping by Month Name
	================================================
	================================================ */

	SELECT
		EXTRACT(month FROM dob) as monthnumber,
		to_char(dob, 'Month') AS monthname,
		count(*) AS howmany
	FROM customerdetails
	GROUP BY EXTRACT(month FROM dob), to_char(dob, 'Month')
	ORDER BY monthnumber;

/*	5.12: Grouping with a CTE
	================================================
	================================================ */

	WITH cte AS (
		SELECT
			EXTRACT(month FROM dob) as monthnumber,
			to_char(dob, 'Month') AS monthname
		FROM customerdetails
	)
	SELECT monthname, count(*)
	FROM cte
	GROUP BY monthnumber, monthname
	ORDER BY monthnumber;

/*	5.13: Grouping with CASE
	================================================
	================================================ */

	--	Basic
		SELECT count(*)
		FROM customers
		GROUP BY CASE
			WHEN dob<'1980-01-01' THEN 'older'
			WHEN dob IS NOT NULL then 'younger'
		END;

	--	Include CASE in SELECT
		SELECT
			CASE
				WHEN dob<'1980-01-01' THEN 'older'
				WHEN dob IS NOT NULL then 'younger'
			END AS agegroup,
			count(*)
		FROM customers
		GROUP BY CASE
			WHEN dob<'1980-01-01' THEN 'older'
			WHEN dob IS NOT NULL then 'younger'
		END;

	--	Using a CTE
		WITH cte AS (
			SELECT
				*,
				CASE
					WHEN dob<'1980-01-01' THEN 'older'
					WHEN dob IS NOT NULL then 'younger'
				END AS agegroup FROM customers
		)
		SELECT agegroup, count(*)
		FROM cte
		GROUP BY agegroup;

/*	5.14: Revisiting Delivery Status
	================================================
	================================================ */

	WITH salesdata AS (
		SELECT
			ordered, shipped, total,
			current_date - cast(ordered as date) AS ordered_age,
			shipped - cast(ordered as date) AS shipped_age
		FROM sales
	)
	SELECT
		ordered, shipped, total,
		CASE
			WHEN shipped IS NOT NULL THEN
				CASE
					WHEN shipped_age>14 THEN 'Shipped Late'
					ELSE 'Shipped'
				END
			ELSE
				CASE
					WHEN ordered_age<7 THEN 'Current'
					WHEN ordered_age<14 THEN 'Due'
					ELSE 'Overdue'
				END
		END AS status
	FROM salesdata;

/*	5.15: Sumarising Sales Status
	================================================
	The second SELECT statement has been put into
	an additional CTE.
	================================================ */

	WITH
		salesdata AS (
			SELECT
				ordered, shipped, total,
				current_date - cast(ordered as date) AS ordered_age,
				shipped - cast(ordered as date) AS shipped_age
			FROM sales
		),
		statuses AS (
			SELECT
				ordered, shipped, total,
				CASE
					WHEN shipped IS NOT NULL THEN
						CASE
							WHEN shipped_age>14 THEN 'Shipped Late'
							ELSE 'Shipped'
						END
					ELSE
						CASE
							WHEN ordered_age<7 THEN 'Current'
							WHEN ordered_age<14 THEN 'Due'
							ELSE 'Overdue'
						END
				END AS status
			FROM salesdata
		)
	SELECT status, count(*) AS number
	FROM statuses
	GROUP BY status;

/*	5.16: Ordering by Strings
	================================================
	================================================ */

	WITH
		salesdata AS (
			SELECT
				ordered, shipped, total,
				current_date - cast(ordered as date) AS ordered_age,
				shipped - cast(ordered as date) AS shipped_age
			FROM sales
		),
		statuses AS (
			SELECT
				ordered, shipped, total,
				CASE
					WHEN shipped IS NOT NULL THEN
						CASE
							WHEN shipped_age>14 THEN 'Shipped Late'
							ELSE 'Shipped'
						END
					ELSE
						CASE
							WHEN ordered_age<7 THEN 'Current'
							WHEN ordered_age<14 THEN 'Due'
							ELSE 'Overdue'
						END
				END AS status
			FROM salesdata
		)
	SELECT status, count(*) AS number
	FROM statuses
	GROUP BY status
	ORDER BY POSITION(status IN 'Shipped,Shipped Late,Current,Due,Overdue')
	;

/*	5.17: Group Concatenation
	================================================
	string_agg(column, delimiter)
	================================================ */

	SELECT
		a.id, a.givenname, a.familyname,
		string_agg(b.title, '; ') AS works
	FROM authors AS a LEFT JOIN books AS b ON a.id=b.authorid
	GROUP BY a.id, a.givenname, a.familyname;

/*	5.18: Prepare sales Data for Subgrouping & Grouping Sets
	================================================
	We’ll be summarising:
		month
		customer id
		customer state
	of sales

	Alias c.id AS customerid
	================================================ */

	SELECT
		to_char(s.ordered, 'YYYY-MM') AS ordered,
		s.total, c.id AS customerid, c.state
	FROM sales AS s JOIN customerdetails AS c
		ON s.customerid=c.id
	WHERE s.ordered IS NOT NULL;

/*	5.19: Creating a salesdata View
	================================================
	Alias c.id AS customerid
	================================================ */

	DROP VIEW IF EXISTS salesdata;

	CREATE VIEW salesdata AS
	SELECT
		to_char(s.ordered, 'YYYY-MM') AS ordered,
		s.total, c.id AS customerid, c.state
	FROM sales AS s JOIN customerdetails AS c
		ON s.customerid=c.id
	WHERE s.ordered IS NOT NULL;

/*	5.20: Summaries to be UNIONed later
	================================================
	================================================ */

	--	state, customerid, ordered summaries
		SELECT state, customerid, ordered, count(*) AS nsales, sum(total) AS total
		FROM salesdata
		GROUP BY state, customerid, ordered
		ORDER BY state, customerid, ordered;

	--	state, customerid summaries
		SELECT
			state, customerid, NULL, count(*) AS nsales,
			sum(total) AS total
		FROM salesdata
		GROUP BY state, customerid
		ORDER BY state, customerid;

	--	state summaries
		SELECT
			state, NULL, NULL, count(*) AS nsales,
			sum(total) AS total
		FROM salesdata
		GROUP BY state
		ORDER BY state;

	--	grand total
		SELECT
			NULL, NULL, NULL, count(*) AS nsales,
			sum(total) AS total
		FROM salesdata
		--	GROUP BY ()
		;

/*	5.21: UNION Summaries
	================================================
	================================================ */

	--	All Group summaries
		SELECT
			state, customerid, ordered, count(*) AS nsales, sum(total) AS total
		FROM salesdata
		GROUP BY state, customerid, ordered
	--	state, ordered summaries
		UNION
		SELECT state, customerid, NULL, count(*), sum(total)
		FROM salesdata
		GROUP BY state, customerid
	--	state summaries
		UNION
		SELECT state, NULL, NULL, count(*), sum(total)
		FROM salesdata
		GROUP BY state
	--	grand total
		UNION
		SELECT NULL, NULL, NULL, count(*), sum(total)
		FROM salesdata

	--	Sort
		ORDER BY state, customerid, ordered;

/*	5.22: UNION with Sorting Columns
	================================================
	================================================ */

	--	All Group summaries
		SELECT
			state, customerid, ordered, count(*) AS nsales, sum(total) AS total,
			0 AS state_level, 0 AS id_level, 0 AS ordered_level
		FROM salesdata
		GROUP BY state, customerid, ordered

	--	state, ordered summaries
		UNION
		SELECT
			state, customerid, NULL, count(*), sum(total),
			0, 0, 1
		FROM salesdata
		GROUP BY state, customerid

	--	state summaries
		UNION
		SELECT
			state, NULL, NULL, count(*), sum(total),
			0, 1, 1
		FROM salesdata
		GROUP BY state

	--	grand total
		UNION
		SELECT
			NULL, NULL, NULL, count(*), sum(total),
			1, 1, 1
		FROM salesdata

	--	Sort
	ORDER BY
		state_level, state,
		id_level, customerid,
		ordered_level, ordered;

/*	5.23: UNION Summaries with CTE
	================================================
	================================================ */

	WITH cte AS (
		SELECT
			state, customerid, ordered, count(*) AS nsales, sum(total) AS total,
			0 AS state_level, 0 AS id_level, 0 AS ordered_level
		FROM salesdata
		GROUP BY state, customerid, ordered
		UNION
		SELECT
			state, customerid, NULL, count(*), sum(total),
			0, 0, 1
		FROM salesdata
		GROUP BY state, customerid
		UNION
		SELECT
			state, NULL, NULL, count(*), sum(total),
			0, 1, 1
		FROM salesdata
		GROUP BY state
		UNION
		SELECT
			NULL, NULL, NULL, count(*), sum(total),
			1, 1, 1
		FROM salesdata
	)
	SELECT state, customerid, ordered, nsales, total
	FROM cte
	ORDER BY
		state_level, state,
		id_level, customerid,
		ordered_level, ordered;

/*	5.24: GROUPING SETS
	================================================
	SELECT columns
	FROM table
	GROUP BY GROUPING SETS ((set),(set));
	================================================ */

	SELECT state, customerid, ordered, count(*)
	FROM salesdata
	GROUP BY GROUPING SETS ((state, customerid, ordered),(state, customerid),(state),());

/*	5.25: CUBE
	================================================
	================================================ */

	SELECT state, customerid, ordered, count(*), sum(total)
	FROM salesdata
	GROUP BY CUBE (state, customerid, ordered);

/*	5.26: ROLLUP
	================================================
	================================================ */

	SELECT state, customerid, ordered, count(*), sum(total)
	FROM salesdata
	GROUP BY ROLLUP (state, customerid, ordered);

/*	5.27: Sorting with grouping()
	================================================
	================================================ */

	SELECT state, customerid, ordered, count(*), sum(total)
	FROM salesdata
	GROUP BY ROLLUP (state, customerid, ordered)
	ORDER BY
		grouping(state), state,
		grouping(customerid), customerid,
		grouping(ordered), ordered;

/*	5.28: Renaming Totals
	================================================
	================================================ */

	SELECT
		coalesce(state, 'National Total') AS state,
		coalesce(cast(customerid as varchar), state||' Total') AS customerid,
		coalesce(ordered, 'Total for '||cast(customerid as varchar)) AS ordered,
		count(*), sum(total)
	FROM salesdata
	GROUP BY ROLLUP (state, customerid, ordered)
	ORDER BY
		grouping(state), state,
		grouping(customerid), customerid,
		grouping(ordered), ordered;

/*	5.29: Calculating the Mean
	================================================
	================================================ */

	SELECT avg(height) AS mean FROM customers;

/*	5.30: Generating a Frequency Table
	================================================
	The round() function has varied behaviours.
	================================================ */

	SELECT floor(height+0.5) AS height
	FROM customers
	WHERE height IS NOT NULL;

	WITH heights AS (
		SELECT floor(height+0.5) AS height
		FROM customers
		WHERE height IS NOT NULL
	)
	SELECT height, count(*) AS frequency
	FROM heights
	GROUP BY height
	ORDER BY height;

/*	5.31: Calculating the Mode
	================================================
	================================================ */

	WITH
		heights AS (
			SELECT floor(height+0.5) AS height
			FROM customers
			WHERE height IS NOT NULL
		),	--	don't forget to add a comma here
		frequency_table AS (
			SELECT height, count(*) AS frequency
			FROM heights
			GROUP BY height
		)
	SELECT *
	FROM frequency_table;

	WITH
		heights AS (
			SELECT floor(height+0.5) AS height
			FROM customers
			WHERE height IS NOT NULL
		),	--	don't forget to add a comma here
		frequency_table AS (
			SELECT height, count(*) AS frequency
			FROM heights
			GROUP BY height
		),	--	don't forget to add a comma here
		limits AS (
			SELECT max(frequency) AS max FROM frequency_table
		)
	SELECT height, frequency
	FROM frequency_table, limits
	WHERE frequency_table.frequency=limits.max
	ORDER BY height;

/*	5.32: Calculating the Median: Window Function
	================================================
	================================================ */

	SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY height)
	FROM customers
	WHERE height IS NOT NULL;

/*	5.33: Standard Deviation
	================================================
	Sample:		stddev_samp()
	Population:	stddev_pop
	================================================ */

	SELECT
		stddev_samp(height) AS sample,
		stddev_pop(height) AS population
	FROM customers;

/**	Chapter6: Using Views and Friends
	================================================
	================================================ */

/*	6.01: Creating a View
	================================================
	================================================ */

	--	SELECT statement
		SELECT
			b.id, b.title, b.published,
			coalesce(a.givenname||' ', '')
				|| coalesce(othernames||' ', '')
				|| a.familyname AS author,
			b.price, b.price*0.1 AS tax, b.price*1.1 AS inc
		FROM books AS b LEFT JOIN authors AS a ON b.authorid=a.id
		WHERE b.price IS NOT NULL;

	--	Create VIEW
		DROP VIEW IF EXISTS aupricelist;

		CREATE VIEW aupricelist AS
		SELECT
			b.id, b.title, b.published,
			coalesce(a.givenname||' ', '')
				|| coalesce(othernames||' ', '')
				|| a.familyname AS author,
			b.price, b.price*0.1 AS tax, b.price*1.1 AS inc
		FROM books AS b LEFT JOIN authors AS a ON b.authorid=a.id
		WHERE b.price IS NOT NULL;

/*	6.02: Reading a View
	================================================
	================================================ */

	SELECT * FROM aupricelist;

	--	Using the WHERE clause
		SELECT *
		FROM aupricelist
		WHERE published BETWEEN 1700 AND 1799;

	--	Using ORDER BY
		SELECT *
		FROM aupricelist
		ORDER BY title;

/*	6.03: Table Valued Function
	================================================
	================================================ */

	DROP FUNCTION IF EXISTS pricelist(taxrate decimal(4,2));

	CREATE FUNCTION pricelist(taxrate decimal(4,2))
	RETURNS TABLE (
		id int, title varchar, published int, author text,
		price decimal(5,2), tax decimal(4,2), inc decimal(5,2)
	)
	LANGUAGE plpgsql AS $$
	BEGIN
		RETURN QUERY
		SELECT
			b.id, b.title, b.published,
			coalesce(a.givenname||' ', '') || coalesce(othernames||' ', '')
				|| a.familyname AS author,
			b.price, b.price*taxrate/100 AS tax,
			b.price*(1+taxrate/100) AS inc
		FROM books as b LEFT JOIN authors a ON b.authorid=a.id
		WHERE b.price IS NOT NULL;
	END; $$;

	--	15% tax:
		SELECT * FROM pricelist(15);

/*	6.04: Temporary Tables
	================================================
	================================================ */

	CREATE TEMPORARY TABLE somebooks (
		id INT PRIMARY KEY,
		title VARCHAR(255),
		author VARCHAR(255),
		price DECIMAL(4,2)
	);

/*	6.05: Populating a Temporary Table
	================================================
	================================================ */

	INSERT INTO somebooks(id, title, author, price)
	SELECT id, title, author, price
	FROM aupricelist
	WHERE price IS NOT NULL;

/*	6.06: Create & Populate
	================================================
	================================================ */

	DROP TABLE IF EXISTS otherbooks;

	CREATE TEMPORARY TABLE otherbooks AS
		SELECT id, title, author, price
		FROM aupricelist
		WHERE price IS NULL
	;

	SELECT id, title, author, price
	INTO TEMPORARY otherbooks
	FROM aupricelist
	WHERE price IS NULL;

/*	6.07: Computed Columns
	================================================
	================================================ */

	ALTER TABLE sales
	ADD COLUMN ordered_date date GENERATED ALWAYS AS (cast(ordered as date)) STORED;

/**	Chapter7: Working with Subqueries and Common Table Expressions
	================================================
	================================================ */

/*	7.01: Types of Results
	================================================
	================================================ */

	--	Single Value
		SELECT id FROM books WHERE title='Frankenstein';

	--	Column
		SELECT email FROM customerdetails WHERE state='VIC';

	--	Multiple Rows & Columns: Virtual Table
		SELECT givenname, familyname, email
		FROM customerdetails WHERE state='VIC';

/*	7.02: FROM (subquery)
	================================================
	================================================ */

	--	Sales for “Frankenstein”
		SELECT *
		FROM saleitems
		WHERE bookid=(SELECT id FROM books WHERE title='Frankenstein');

	--	Books by 18th Century Authors
		SELECT *
		FROM books
		WHERE authorid IN (
			SELECT id FROM authors WHERE born BETWEEN '1700-01-01' AND '1799-12-31'
		);

/*	7.03: Non-Correlated Subqueries
	================================================
	================================================ */

	--	Books by Female Authors
		SELECT *
		FROM books
		WHERE authorid IN(
			SELECT id FROM authors WHERE gender='f'
		);

	--	Oldest Customers (Aggregate Subquery)
		SELECT *
		FROM customers
		WHERE dob=(SELECT min(dob) FROM customers);

/*	7.04: Correlated Subquery
	================================================
	Book Authors (yes, there’s another way to do this)
	================================================ */

	SELECT
		id, title, (
			SELECT coalesce(givenname||' ', '')
				|| coalesce(othernames||' ', '')
				|| familyname
			FROM authors
			WHERE authors.id=books.authorid
		) AS author
	FROM books;

/*	7.05: Subquery in the SELECT clause
	================================================
	================================================ */

	SELECT
		id, title, (
			SELECT coalesce(givenname||' ', '')
				|| coalesce(othernames||' ', '')
				|| familyname
			FROM authors
			WHERE authors.id=books.authorid
		) AS author,
		(SELECT born FROM authors WHERE authors.id=books.authorid) AS born,
		(SELECT died FROM authors WHERE authors.id=books.authorid) AS died
	FROM books;

	--	Using a JOIN
		SELECT
			b.id, b.title,
			coalesce(a.givenname||' ', '')
				|| coalesce(a.othernames||' ', '')
				|| a.familyname AS author,
			a.born, a.died
		FROM books AS b LEFT JOIN authors AS a ON b.authorid=a.id;

/*	7.06: Non-Correlated Aggregate Subquery in SELECT
	================================================
	================================================ */

	SELECT
		id, givenname, familyname,
		height,
		height-(SELECT avg(height) FROM customers) AS diff
	FROM customers;

/*	7.07: Correlated Aggregate Subquery in SELECT
	================================================
	================================================ */

	SELECT
		id, ordered, total,
		(SELECT sum(total) FROM sales AS ss
		WHERE ss.ordered<=sales.ordered) AS running_total
	FROM sales
	ORDER BY id;

/*	7.08: Non Correlated Aggregate Subqueries in WHERE clause
	================================================
	================================================ */

	--	Oldest Customers
		SELECT *
		FROM customers
		WHERE dob=(SELECT min(dob) FROM customers);

	--	Shorter Customers
		SELECT *
		FROM customers
		WHERE height<(SELECT avg(height) FROM customers);

/*	7.09: Big Spenders
	================================================
	================================================ */

	--	Big Sales
		SELECT * FROM sales WHERE total>160;

	--	Big Spenders
		SELECT *
		FROM customers
		WHERE id IN(SELECT customerid FROM sales WHERE total>160);

	--	Using ANY()
		SELECT *
		FROM customers
		WHERE id=ANY(SELECT customerid FROM sales WHERE total>=160);

	--	Using a JOIN
		SELECT DISTINCT customers.*
		FROM customers JOIN sales ON customers.id=sales.customerid
		WHERE sales.total>=160;

	--	More details in the JOIN
		SELECT *
		FROM customers JOIN sales ON customers.id=sales.customerid
		WHERE sales.total>=160;

/*	7.10: Customers with largest total sales
	================================================
	================================================ */

	SELECT *
	FROM customers
	WHERE id IN(
		SELECT customerid FROM sales
		GROUP BY customerid HAVING sum(total)>=2000
	);

/*	7.11: Last Orders, Please
	================================================
	================================================ */

	--	Last order date by customerid
		SELECT max(ordered) FROM sales GROUP BY customerid;

	--	Last order by customer
		SELECT * FROM sales
		WHERE ordered IN(SELECT max(ordered) FROM sales GROUP BY customerid);

	--	Include Customer Details
		SELECT *
		FROM sales JOIN customers ON sales.customerid=customers.id
		WHERE ordered IN(SELECT max(ordered) FROM sales GROUP BY customerid);

/*	7.12: Duplicate Customers
	================================================
	================================================ */

	--	Duplicate Names
		SELECT
			givenname||' '||familyname AS fullname,
			count(*) as occurrences
		FROM customers
		GROUP BY familyname, givenname
		HAVING count(*)>1;

	--	With Customer Details
		SELECT *
		FROM customers
		WHERE givenname||' '||familyname IN (
			SELECT givenname||' '||familyname FROM customers
			GROUP BY familyname, givenname
			HAVING count(*)>1
		);

/*	7.13: Aggregating Price Groups
	================================================
	================================================ */

	--	Price Groups
		SELECT
			id, title,
			CASE
				WHEN price<13 THEN 'cheap'
				WHEN price<=17 THEN 'reasonable'
				WHEN price>17 THEN 'expensive'
			END AS price_group
		FROM books;

	--	This works, but …
		SELECT
		--	id, title,
			CASE
				WHEN price<13 THEN 'cheap'
				WHEN price<=17 THEN 'reasonable'
				WHEN price>17 THEN 'expensive'
			END AS price_group,
			count(*) as num_books
		FROM books
		GROUP BY CASE
			WHEN price<13 THEN 'cheap'
			WHEN price<=17 THEN 'reasonable'
			WHEN price>17 THEN 'expensive'
		END;

	--	Using a Subquery
		SELECT price_group, count(*) AS num_books
		FROM (
			SELECT
				id, title,
				CASE
					WHEN price<13 THEN 'cheap'
					WHEN price<=17 THEN 'reasonable'
					WHEN price>17 THEN 'expensive'
				END AS price_group
			FROM books
		) AS sq
		GROUP BY price_group;

/*	7.14: Nested FROM Subqueries
	================================================
	================================================ */

	--	Duplicate Names
		SELECT familyname, givenname
		FROM customers
		GROUP BY familyname, givenname HAVING count(*)>1;

	--	Joined with customers Table
		SELECT
			c.id, c.givenname, c.familyname, c.email
		FROM customers AS c JOIN (
			SELECT familyname, givenname
			FROM customers
			GROUP BY familyname, givenname HAVING count(*)>1
		) AS n ON c.givenname=n.givenname AND c.familyname=n.familyname;

	--	Summarised (better as CTE, later)
		SELECT
			givenname, familyname,
			string_agg(email, ', ') AS email,
			string_agg(cast(id AS varchar(3)), ', ') AS ids
		FROM (	--	previous SELECT as subquery
			SELECT c.id, c.givenname, c.familyname, c.email
			FROM customers AS c JOIN (
				SELECT familyname, givenname
				FROM customers
				GROUP BY familyname, givenname HAVING count(*)>1
			) AS n ON c.givenname=n.givenname AND
				c.familyname=n.familyname
		) AS sq
		GROUP BY familyname, givenname;

/*	7.15: WHERE EXISTS(non-correlated subquery)
	================================================
	… WHERE EXISTS (SELECT 1 WHERE 1=1)
	================================================ */

	--	Trival Example (all rows)
		SELECT * FROM authors
		WHERE EXISTS (SELECT 1 WHERE 1=1);

	--	Trival Example (no rows)
		SELECT * FROM authors
		WHERE EXISTS (SELECT 1 WHERE 1=0);

	--	Also Trivial ∵ return all books
		SELECT * FROM authors
		WHERE EXISTS (SELECT 1/0 FROM books WHERE price<15);

/*	7.16: WHERE EXISTS (correlated subquery)
	================================================
	================================================ */

	--	authors with books
		SELECT * FROM authors
		WHERE EXISTS (
			SELECT 1 FROM books WHERE books.authorid=authors.id
		);

	--	same with IN(…)
		SELECT * FROM authors
		WHERE id IN(SELECT authorid FROM books);

	--	NOT IN(…) fails (NOT IN quirk)
		SELECT * FROM authors
		WHERE id NOT IN(SELECT authorid FROM books);

	--	authors without books
		SELECT * FROM authors
		WHERE NOT EXISTS (
			SELECT 1 FROM books WHERE books.authorid=authors.id
		);


/*	7.17: Lateral Joins: Unsuccessful Use Cases
	================================================
	================================================ */

	--	Can’t use aliases in other column calculations
		SELECT
			id, title,
			price, price*0.1 AS tax, price+tax AS inc
		FROM books;

	--	Can’t use alias in WHERE clause (except SQLite)
		SELECT
			id, title,
			price, price*0.1 AS tax
		FROM books
		WHERE tax>1.5;

	--	Can’t get multiple columns in subquery
		SELECT
			id, title,
			(SELECT givenname, othernames, familyname
			FROM authors WHERE authors.id=books.authorid)
		FROM books;

/*	7.18: Using Lateral Join: Calculated Aliases
	================================================
	You can use JOIN LATERAL(SELECT price*0.1) AS sq(tax) ON true
	Requires ON true
	================================================ */
	SELECT
		id, title,
		price, tax, inc
	FROM
		books
		JOIN LATERAL(SELECT price*0.1 AS tax) AS sq ON true
		JOIN LATERAL(SELECT price+tax AS inc) AS sq2 ON true
	WHERE tax>1.5;

/*	7.19: Using Lateral Join: Fetching Multiple Columns
	================================================
	================================================ */

	SELECT
		id, title,
		givenname, othernames, familyname,
		home
	FROM
		books
		LEFT JOIN LATERAL(
			SELECT givenname, othernames, familyname, home
			FROM authors
			WHERE authors.id=books.authorid
		) AS a ON true;

	--	You can also use the simpler:
		SELECT
			books.id, title,
			givenname, othernames, familyname,
			home
		FROM books LEFT JOIN authors ON authors.id=books.authorid;

/*	7.20: Using Lateral Join: Using an Aggregate Query
	================================================
	================================================ */

	SELECT
		id, givenname, familyname, total
	FROM
		customers
		LEFT JOIN LATERAL(
			SELECT sum(total) AS total FROM sales
			WHERE sales.customerid=customers.id
	) AS totals ON true;

/*	7.21: CTE and Price Groups
	================================================
	================================================ */

	--	Using a Subquery
		SELECT price_group, count(*) AS num_books
		FROM (
			SELECT
				id, title,
				CASE
					WHEN price<13 THEN 'cheap'
					WHEN price<=17 THEN 'reasonable'
					WHEN price>17 THEN 'expensive'
				END AS price_group
			FROM books
		) AS sq
		GROUP BY price_group;

	--	Using a CTE
		WITH sq AS (								--	Prepare Data
			SELECT
				id, title,
				CASE
					WHEN price<13 THEN 'cheap'
					WHEN price<=17 THEN 'reasonable'
					WHEN price>17 THEN 'expensive'
				END AS price_group
			FROM books
		)
		SELECT price_group, count(*) AS num_books	--	Use Prepared Data
		FROM sq
		GROUP BY price_group;

/*	7.22: CTE to Prepare Monthly Totals
	================================================
	================================================ */

	WITH salesdata AS (
		SELECT
			to_char(ordered, 'YYYY-MM') AS month,
			total
		FROM sales
	)
	SELECT month, sum(total) AS daily_total
	FROM salesdata
	GROUP BY month
	ORDER BY month;

/**	Chapter8: Window Functions
	================================================
	================================================ */

/*	8.01: Simple Aggregate Window
	================================================
	================================================ */

	--	This won’t work
		SELECT
			id, givenname, familyname,
			count(*)
		FROM customerdetails;

	--	This will:
		SELECT
			id, givenname, familyname,
			count(*) OVER ()
		FROM customerdetails;

	--	Equivalent with subquery
		SELECT
			id, givenname, familyname,
			(SELECT count(*) FROM customers)
		FROM customerdetails;

/*	8.02: Window with OVER(ORDER BY …)
	================================================
	================================================ */

	SELECT
		id, givenname, familyname,
		count(*) OVER (ORDER BY id)
	FROM customerdetails;

	--	Sorted
		SELECT
			id, givenname, familyname,
			count(*) OVER (ORDER BY id) AS running_count
		FROM customerdetails
		ORDER BY id;

/*	8.03: Using Aggregate OVER(): Compare total to Average
	================================================
	================================================ */

	SELECT
		id, ordered, total,
		total-avg(total) OVER () AS difference
	FROM sales;

/*	8.04: Sales by Week Day
	================================================
	================================================ */

	--	Get Week Day: Sunday=0
		SELECT
			EXTRACT(dow FROM ordered) AS weekday_number,
			total
		FROM sales;

	--	Put Weekday query in CTE and summarise
		WITH
			data AS (
				SELECT
					EXTRACT(dow FROM ordered) AS weekday_number,
					total
				FROM sales
			)
		SELECT weekday_number, sum(total) AS total
		FROM data
		GROUP BY weekday_number
		;

	--	Put Summary in CTE and Compare
		WITH
			data AS (
				SELECT
					EXTRACT(dow FROM ordered) AS weekday_number,
					total
				FROM sales
			),
			summary AS (
				SELECT weekday_number, sum(total) AS total
				FROM data
				GROUP BY weekday_number
			)
		SELECT
			weekday_number, total,
			total/sum(total) OVER()
		FROM summary
		ORDER BY weekday_number;

	--	Embellish Proportion
		WITH
			data AS (
				SELECT
					EXTRACT(dow FROM ordered) AS weekday_number,
					total
				FROM sales
			),
			summary AS (
				SELECT weekday_number, sum(total) AS total
				FROM data
				GROUP BY weekday_number
			)
		SELECT
			weekday_number, total,
			to_char(100*total/sum(total) OVER(), '99.9%') AS proportion
		FROM summary
		ORDER BY weekday_number;

/*	8.05: Exploring count(*) OVER(ORDER BY …)
	================================================
	================================================ */

	--	Some duplicate values
		SELECT
			id, givenname, familyname,
			height,
			count(*) OVER (ORDER BY height) AS running_count
		FROM customerdetails
		WHERE height IS NOT NULL
		ORDER BY height;

/*	8.06: The Framing Clause: RANGE vs ROWS
	================================================
	[ROW|RANGE] BETWEEN start AND end
	================================================ */

	--	Default: RANGE …
		SELECT
			id, givenname, familyname,
			height,
			count(*) OVER (
				ORDER BY height
				RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			) AS running_count
		FROM customerdetails
		WHERE height IS NOT NULL
		ORDER BY height;

	--	Alternative: ROWS …
		SELECT
			id, givenname, familyname,
			height,
			count(*) OVER (
				ORDER BY height
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			) AS running_count
		FROM customerdetails
		WHERE height IS NOT NULL
		ORDER BY height;

/*	8.07: Creating a daily_sales View
	================================================
	================================================ */

	DROP VIEW IF EXISTS daily_sales;

	CREATE VIEW daily_sales AS
	SELECT
		ordered_date,
		to_char(ordered_date, 'YYYY-MM') AS ordered_month,
		sum(total) AS daily_total
	FROM sales
	WHERE ordered IS NOT NULL
	GROUP BY ordered_date;

	SELECT * FROM daily_sales ORDER BY ordered_date;

/*	8.08: Sliding Window: One week
	================================================
	Framing Clause
		Expression			Meaning
		UNBOUND PRECEDING	Beginning
		n PRECEDING			Number of rows before the current row
		CURRENT ROW
		n FOLLOWING			Number of rows after the current row
		UNBOUND FOLLOWING	End

	Short Version
		ROWS|RANGE Start	ROWS|RANGE BETWEEN Start AND CURRENT ROW
	================================================ */

	SELECT
		ordered_date, daily_total,
		sum(daily_total) OVER(
			ORDER BY ordered_date
			ROWS 6 PRECEDING
		) AS week_total,
		sum(daily_total) OVER(
			ORDER BY ordered_date
			ROWS UNBOUNDED PRECEDING
		) AS running_total
	FROM daily_sales
	ORDER BY ordered_date;

/*	8.09: Subtotals with PARTITION
	================================================
	================================================ */

	SELECT
		ordered_date, daily_total,
		sum(daily_total) OVER(
			ORDER BY ordered_date
			ROWS 6 PRECEDING
		) AS week_total,
		sum(daily_total) OVER(
			ORDER BY ordered_date
			ROWS UNBOUNDED PRECEDING
		) AS running_total,
		sum(daily_total) OVER(
			PARTITION BY ordered_month
		) AS monthly_total,
		sum(daily_total) OVER(
			PARTITION BY ordered_month
			ORDER BY ordered_date ROWS UNBOUNDED PRECEDING
		) AS month_running_total
	FROM daily_sales
	ORDER BY ordered_date;

/*	8.10: ORDER BY and PARTITION BY Sampler
	================================================
	Clause								Name				What’s Happening
	ORDER BY date …						running_total		Total so far from the beginning to the current row
	PARTITION BY month					month_total			Total for the current group
	ORDER BY month						running_month_total	Running total for each month
	PARTITION BY month ORDER BY date …	month_running_total	Running total within each month
	================================================ */

	SELECT
		ordered_date, daily_total,
		sum(daily_total) OVER(ORDER BY ordered_date ROWS UNBOUNDED PRECEDING) AS running_total,
		sum(daily_total) OVER(PARTITION BY ordered_month) AS month_total,
		sum(daily_total) OVER(ORDER BY ordered_month) AS running_month_total,
		sum(daily_total) OVER(
			PARTITION BY ordered_month
			ORDER BY ordered_date ROWS UNBOUNDED PRECEDING
		) AS month_running_total
	FROM daily_sales
	ORDER BY ordered_date;

/*	8.11: Partition by Multiple Columns
	================================================
	================================================ */

	WITH
		customer_sales AS (
			SELECT c.id AS customerid, c.state, c.town, total
			FROM customerdetails AS c JOIN sales AS s
				ON c.id=s.customerid
		),
		totals AS (
			SELECT state, town, customerid, sum(total) AS total
			FROM customer_sales
			GROUP BY state, town, customerid
		)
	SELECT
		state, town, customerid, total AS customer_total,
		sum(total) OVER(PARTITION BY state) AS state_total,
		sum(total) OVER(PARTITION BY state, town) AS town_total
	FROM totals
	ORDER BY state, customerid;

/*	8.12: Ranking Functions: row_number()
	================================================
	================================================ */

	--	Using count(*)
		SELECT
			id, givenname, familyname,
			height,
			count(*) OVER (ORDER BY height ROWS UNBOUNDED PRECEDING) AS running_count
		FROM customers
		WHERE height IS NOT NULL
		ORDER BY height;

	--	Using row_number()
		SELECT
			id, givenname, familyname,
			height,
			row_number() OVER (ORDER BY height) AS running_count
		FROM customers
		WHERE height IS NOT NULL
		ORDER BY height;

/*	8.13: Ranking Sampler
	================================================
	================================================ */

	SELECT
		id, givenname, familyname,
		height,
		row_number() OVER (ORDER BY height) AS row_number,
		count(*) OVER (ORDER BY height) AS count,
		rank() OVER (ORDER BY height) AS rank,
		dense_rank() OVER (ORDER BY height) AS dense_rank
	FROM customers
	WHERE height IS NOT NULL
	ORDER BY height;

/*	8.14: Ranking with PARTITION BY
	================================================
	================================================ */

	SELECT
		id, ordered_date, total,
		row_number() OVER (
			PARTITION BY ordered_date
		) AS row_number
	FROM sales
	ORDER BY ordered;

	--	Ordering the row number
		SELECT
			id, ordered_date, total,
			row_number() OVER (
				PARTITION BY ordered_date ORDER BY ordered
			) AS row_number
		FROM sales
		ORDER BY ordered;

/*	8.15: Use row_number() to hide repeated values
	================================================
	================================================ */

	SELECT
		id,
		CASE
			WHEN row_number() OVER (PARTITION BY ordered_date ORDER BY ordered)=1
				THEN CAST(ordered_date AS varchar(16))
			ELSE ''
		END AS ordered_date,
		row_number() OVER (PARTITION BY ordered_date) AS item,
		total
	FROM sales
	ORDER BY ordered;

/*	8.16: Paging with CTE and row_number
	================================================
	================================================ */

	WITH cte AS (
		SELECT
			id, title, published, author,
			price, tax, inc,
			row_number() OVER(ORDER BY id) AS row_number
		FROM aupricelist
	)
	SELECT *
	FROM cte
	WHERE row_number BETWEEN 40 AND 59
	ORDER BY id;

/*	8.17: Paging Clause: OFFSET … FETCH
	================================================
	================================================ */

	SELECT
		id, title, published, author,
		price, tax, inc,
		row_number() OVER(ORDER BY id) AS row_number
	FROM aupricelist
	ORDER BY id OFFSET 40 ROWS FETCH FIRST 20 ROWS ONLY;

/*	8.17: Paging Clause: LIMIT … OFFSET
	================================================
	================================================ */

	SELECT
		id, title, published, author,
		price, tax, inc,
		row_number() OVER(ORDER BY id) AS row_number
	FROM aupricelist
	ORDER BY id LIMIT 20 OFFSET 40;

/*	8.18: Using dense_rank() to Keep Groups Together
	================================================
	================================================ */

	WITH cte AS (
		SELECT
			id, title, published, author,
			price, tax, inc,
			dense_rank() OVER(ORDER BY price) AS dense_rank
		FROM aupricelist
	)
	SELECT *
	FROM cte
	WHERE dense_rank BETWEEN 5 AND 10
	ORDER BY price;

/*	8.19: ntile() to create Deciles
	================================================
	================================================ */

	SELECT
		id, givenname, familyname, height,
		ntile(10) OVER (order by height) AS decile
	FROM customers
	WHERE height IS NOT NULL;

/*	8.20: A Workaround for ntile()
	================================================
	================================================ */

	WITH data AS (
		SELECT count(*)/20.0 AS bin
		FROM customers WHERE height IS NOT NULL
	)
	SELECT
		id, givenname, familyname, height,
		row_number() OVER(ORDER BY height) AS row_number,
		ntile(20) OVER(ORDER BY height) AS vigintile,

		floor((row_number() OVER(ORDER BY height)-1)/bin)+1 AS row_vigintile,
		floor((rank() OVER(ORDER BY height)-1)/bin)+1 AS rank_vigintile,
		floor((count(*) OVER(ORDER BY height)-1)/bin)+1 AS count_vigintile,

		bin
	FROM customers, data
	WHERE height IS NOT NULL
	ORDER BY height;

/*	8.21: Previous and Next Rows
	================================================
	================================================ */

	SELECT
		ordered_date, daily_total,
		lag(daily_total) OVER (ORDER BY ordered_date) AS previous,
		lead(daily_total) OVER (ORDER BY ordered_date) AS next
	FROM daily_sales
	ORDER BY ordered_date;

/*	8.22: Comparing with Previous Rows
	================================================
	================================================ */

	SELECT
		ordered_date, daily_total,
		lag(daily_total, 7) OVER (ORDER BY ordered_date) AS last_week,
		daily_total - lag(daily_total, 7) OVER (ORDER BY ordered_date) AS difference
	FROM daily_sales
	ORDER BY ordered_date;

/**	Chapter9: More on Common Table Expressions
	================================================
	================================================ */

/*	9.01: CTE for Tax Rate Constant
	================================================
	================================================ */

	WITH vars AS (
		SELECT 0.1 AS taxrate
	)
	SELECT * FROM books, vars;

	WITH vars AS (SELECT 0.1 AS taxrate)
	SELECT
		id, title,
		price, price*taxrate AS tax, price*(1+taxrate) AS total
	FROM books, vars;

/*	9.02: Derived Constants
	================================================
	================================================ */

	WITH vars AS (
		SELECT min(dob) AS oldest, max(dob) AS youngest
		FROM customers
	)
	SELECT *
	FROM customers, vars
	WHERE dob IN(oldest, youngest);

	WITH vars AS (SELECT avg(height) AS average FROM customers)
	SELECT *
	FROM customers, vars
	WHERE height<average;

/*	9.03: Aggregates in the CTE
	================================================
	================================================ */

	--	Last Orders
		SELECT customerid, max(ordered) AS last_order
		FROM sales
		GROUP BY customerid;

	--	More Details
		WITH cte(customerid, last_order) AS (
			SELECT customerid, max(ordered) AS last_order
			FROM sales
			GROUP BY customerid
		)
		SELECT
			customers.id AS customerid,
			customers.givenname, customers.familyname,
			sales.id AS saleid,
			sales.ordered_date, sales.total
		FROM
			sales
			JOIN cte ON sales.customerid=cte.customerid
				AND sales.ordered=cte.last_order
			JOIN customers ON customers.id=cte.customerid
		;

/*	9.04: Customers with Duplicate Names
	================================================
	================================================ */

	WITH names AS (
		SELECT familyname, givenname FROM customers
		GROUP BY familyname, givenname HAVING count(*)>1
	)
	SELECT
		c.id, c.givenname, c.familyname,
		c.email, c.phone
		--	etc
	FROM customers AS c
		JOIN names ON c.givenname=names.givenname
			AND c.familyname=names.familyname
	ORDER BY c.familyname, c.givenname;

/*	9.05: CTE Parameter Names
	================================================
	================================================ */

	WITH vars(oldest, youngest) AS (	--	parameter names
		SELECT min(dob), max(dob)		--	no aliases
		FROM customers
	)
	SELECT *
	FROM customers, vars
	WHERE dob IN(oldest, youngest);

/*	9.06: Summarising Duplicate Names with Multiple CTEs
	================================================
	================================================ */

	WITH names AS (
		SELECT familyname, givenname FROM customers
		GROUP BY familyname, givenname HAVING count(*)>1
	)
	SELECT
		c.id, c.givenname, c.familyname,
		c.email, c.phone
	FROM customers AS c
		JOIN names ON c.givenname=names.givenname
			AND c.familyname=names.familyname
	ORDER BY c.familyname, c.givenname;

	--	Combined Details
		WITH
			names AS (
				SELECT familyname, givenname FROM customers
				GROUP BY familyname, givenname HAVING count(*)>1
			),
			duplicates(givenname, familyname, info) AS (
				SELECT
					c.givenname, c.familyname,
					cast(c.id AS varchar(5)) || ': ' || c.email
				FROM customers AS c
					JOIN names ON c.givenname=names.givenname
						AND c.familyname=names.familyname
			)
		SELECT
			givenname, familyname, count(*),
			string_agg(info, ', ') AS info
		FROM duplicates
		GROUP BY familyname, givenname
		ORDER by familyname, givenname;

/*	9.07: Recursive CTEs - Counter
	================================================
	WITH RECURSIVE cte AS (
		Anchor
		UNION
		Recursive
	)
	================================================ */

	WITH RECURSIVE cte(n) AS (
		--	Anchor
			SELECT 1
		UNION
		--	Recursive Member
			SELECT n+1 FROM cte WHERE n<10
	)
	SELECT * FROM cte;

/*	9.08: Recursive CTE to Generate Dates
	================================================
	WITH RECURSIVE cte AS (
		Anchor
		UNION
		Recursive
	)
	================================================ */

	WITH RECURSIVE dates(d, n) AS (
		SELECT date'2023-01-01', 1
		UNION
		SELECT d+1, n+1 FROM dates
		WHERE d<'2023-05-01' AND n<10000
	)
	SELECT * FROM dates;

/*	9.09: Joining a Sequence CTE to Get Missing Values
	================================================
	WITH RECURSIVE cte AS (
		Anchor
		UNION
		Recursive
	)
	================================================ */

	WITH RECURSIVE
	--	Sequence of years
		allyears(year) AS (
			SELECT 1940
			UNION
			SELECT year+1 FROM allyears WHERE year<2010
		),
	--	Years of Birth
		yobs(id, yob) AS (
			SELECT id, EXTRACT(year FROM dob)
			FROM customers WHERE dob IS NOT NULL
		)
	SELECT allyears.year, count(*) AS nums
	FROM allyears LEFT JOIN yobs ON allyears.year=yobs.yob
	GROUP BY allyears.year
	ORDER BY allyears.year;

/*	9.10: Daily Sales
	================================================
	WITH RECURSIVE cte AS (
		Anchor
		UNION
		Recursive
	)
	================================================ */

	WITH RECURSIVE
	--	Get Date Limits
		vars(first_date, last_date) AS (
			SELECT min(ordered_date), max(ordered_date)
			FROM daily_sales
		),
	--	Get All Dates
		dates(d) AS (
			SELECT first_date FROM vars
			UNION
			SELECT d+1 FROM vars, dates WHERE d<last_date
		)
	SELECT d AS ordered_date, daily_sales.daily_total
	FROM dates LEFT JOIN daily_sales ON dates.d=daily_sales.ordered_date
	ORDER BY dates.d;

/*	9.11: Employees - Self Join
	================================================
	================================================ */

	--	Employees
		SELECT * FROM employees;

	--	Self Join
		SELECT
			e.id AS eid,
			e.givenname, e.familyname,
			s.id AS sid,
			s.givenname||' '||s.familyname AS supervisor
		FROM employees AS e LEFT JOIN employees AS s ON e.supervisorid=s.id
		ORDER BY e.id;

/*	9.12: Employees Hierarchy
	================================================
	================================================ */

	WITH RECURSIVE
		cte(id, givenname, familyname, supervisorid, supervisors, n) AS (
		--	anchor
			SELECT
				id, givenname, familyname, supervisorid,
				'',
				1
			FROM employees WHERE supervisorid IS NULL
			UNION ALL
		--	recursive: others (supervisorid NOT NULL)
			SELECT
				e.id, e.givenname, e.familyname, e.supervisorid,
			--	cte.givenname||' '||cte.familyname||' < '|| cte.supervisors,
				cte.givenname||' '||cte.familyname||(CASE WHEN n>1 THEN ' < ' ELSE '' END)|| cte.supervisors,
				n+1
			FROM cte JOIN employees AS e ON cte.id=e.supervisorid
	)
	SELECT * FROM cte
	ORDER BY id;

/*	9.13: Table Literals
	================================================
	================================================ */

	WITH cte(id, value) AS (
		VALUES
			('a', 'apple'),
			('b', 'banana'),
			('c', 'cherry')
	)
	SELECT * FROM cte;

/*	9.14: Table Literals to Test Age Calculation
	================================================
	dob			today
	1940-07-07	2022-12-31
	1943-02-25	2022-12-31
	1942-06-18	2022-12-31
	1940-10-09	2022-12-31
	1940-07-07	2023-07-07
	1943-02-25	2023-02-25
	1942-06-18	2023-06-18
	1940-10-09	2023-10-09
	================================================ */

	WITH dates(dob, today) AS (
		VALUES
			(date'1940-07-07', date'2023-01-01'),
			('1943-02-25', '2023-01-01'),
			('1942-06-18', '2023-01-01'),
			('1940-10-09', '2022-12-31'),
			('1940-07-07', '2023-07-07'),
			('1943-02-25', '2023-02-25'),
			('1942-06-18', '2023-06-18'),
			('1940-10-09', '2023-10-09')
	)
	SELECT
		dob, today,
		extract(year from age(today, dob)) AS age
	FROM dates;

/*	9.15: Using a Table Literal for Sorting
	================================================
	sequence	weekday
	1			Monday
	2			Tuesday
	3			Wednesday
	4			Thursday
	5			Friday
	6			Saturday
	7			Sunday
	================================================ */

	WITH
		data AS (
			SELECT to_char(ordered, 'FMDay') AS weekday, total
			FROM sales
		),
		summary AS (
			SELECT weekday, sum(total) AS total
			FROM data
			GROUP BY weekday
		),
		weekdays(sequence, weekday) AS (
			VALUES
				(1, 'Monday'),
				(2, 'Tuesday'),
				(3, 'Wednesday'),
				(4, 'Thursday'),
				(5, 'Friday'),
				(6, 'Saturday'),
				(7, 'Sunday')
		)
		SELECT
			summary.weekday, summary.total,
			100*total/sum(summary.total) OVER()
		FROM summary JOIN weekdays
			ON summary.weekday=weekdays.weekday
		ORDER BY weekdays.sequence;

/*	9.16: Using a Table Literal as a Lookup
	================================================
	================================================ */

	WITH statuses(status, status_name) AS (
		VALUES
			(1, 'Gold'),
			(2, 'Silver'),
			(3, 'Bronze')
	)
	SELECT *
	FROM
		customers
		LEFT JOIN vip ON customers.id=vip.id
		LEFT JOIN statuses ON vip.status=statuses.status
	;

/*	9.17: Using a Recursive CTE to Split a String
	================================================
	WITH RECURSIVE cte AS (
		Anchor
		UNION
		Recursive
	)
	================================================ */

	WITH RECURSIVE
		cte(fruits) AS (
			VALUES ('Apple,Banana,Cherry,Date,Elderberry,Fig')
		),
		split(fruit, rest) AS (
			SELECT
				substring(fruits, 0, position(',' in fruits)),
				substring(fruits, position(',' in fruits)+1)||','
			FROM cte
			UNION
			SELECT
				substring(rest, 0, position(',' in rest)),
				substring(rest, position(',' in rest)+1)
			FROM split WHERE rest<>''
		)
	SELECT * FROM split;

/*	9.18: Splitting More Complex Data
	================================================
	WITH RECURSIVE cte AS (
		Anchor
		UNION
		Recursive
	)

	name		items
	colours		Red,Orange,Yellow,Green,Blue,Indigo,Violet
	elements	Hydrogen,Helium,Lithium,Beryllium,Boron,Carbon
	numbers		One,Two,Three,Four,Five,Six,Seven,Eight,Nine
	================================================ */

	WITH RECURSIVE
		cte(name, items) AS (
			VALUES
				('colours', 'Red,Orange,Yellow,Green,Blue,Indigo,Violet'),
				('elements', 'Hydrogen,Helium,Lithium,Beryllium,Boron,Carbon'),
				('numbers', 'One,Two,Three,Four,Five,Six,Seven,Eight,Nine')
		),
		split(name, item, rest) AS (
			SELECT
				name,
				substring(items, 0, position(',' in items)),
				substring(items, position(',' in items)+1)||','
			FROM cte
			UNION
			SELECT
				name,
				substring(rest, 0, position(',' in rest)),
				substring(rest, position(',' in rest)+1)
			FROM split WHERE rest<>''
		)
	SELECT *
	FROM split
	ORDER BY name, item;

/**	Chapter 10: More Techniques
	================================================
	Triggers
	Pivot Tables
	Variables
	================================================ */

/*	10.01: Archive Trigger
	================================================
	CREATE TABLE deleted_sales (
		id INT PRIMARY KEY,			--	Auto Incremented
		saleid INT,
		customerid INT,
		items VARCHAR(255),
		deleted_date TIMESTAMP		--	date/time
	);

	DELETE FROM sales WHERE ordered IS NULL;
	================================================ */

	DROP TRIGGER IF EXISTS archive_sales_trigger ON sales;
	DROP FUNCTION IF EXISTS do_archive_sales;

	CREATE FUNCTION do_archive_sales() RETURNS TRIGGER
	LANGUAGE plpgsql AS
	$$BEGIN
		WITH cte(saleid, customerid, items) AS (
			SELECT
				s.id, s.customerid,
				string_agg(si.bookid||':'||si.quantity, ';')
			FROM sales AS s JOIN saleitems AS si
				 ON s.id=si.saleid
			WHERE s.id=old.id
			GROUP BY s.id, s.customerid
		)
		INSERT INTO deleted_sales(saleid, customerid, items,
			deleted_date)
		SELECT saleid, customerid, items, current_timestamp
		FROM cte;
		RETURN old;
	END$$;

	CREATE TRIGGER archive_sales_trigger
		BEFORE DELETE ON sales
		FOR EACH ROW
		EXECUTE FUNCTION do_archive_sales();

/*	10.01b	Archive Trigger - Test
	================================================
	================================================ */

	DELETE FROM sales WHERE ordered IS NULL;

	SELECT * FROM sales;
	SELECT * FROM saleitems;

	SELECT * FROM deleted_sales;

/*	10.02: Manually Pivoting Data: Prepare Statuses
	================================================
	1	status table literal
	-	customerinfo
	-	salesdata
	================================================ */

	WITH
		statuses(status, statusname) AS (
			VALUES
				(1, 'Gold'),
				(2, 'Silver'),
				(3, 'Bronze')
		)
	SELECT * FROM statuses;

/*	10.03: Manually Pivoting Data: Prepare customerinfo
	================================================
	-	status table literal
	2	customerinfo
	-	salesdata
	================================================ */

	WITH
		statuses(status, statusname) As (
			VALUES
				(1, 'Gold'),
				(2, 'Silver'),
				(3, 'Bronze')
		),
		customerinfo(id, state, statusname) AS (
			SELECT customerdetails.id, state, statuses.statusname
			FROM
				customerdetails
				LEFT JOIN vip ON customerdetails.id=vip.id
				LEFT JOIN statuses ON vip.status=statuses.status
		)
	SELECT *
	FROM customerinfo;

/*	10.04: Manually Pivoting Data: Prepare Sales Data
	================================================
	-	status table literal
	-	customerinfo
	3	salesdata
	================================================ */

	WITH
		statuses(status, statusname) As (
			VALUES
				(1, 'Gold'),
				(2, 'Silver'),
				(3, 'Bronze')
		),
		customerinfo(id, state, statusname) AS (
			SELECT customerdetails.id, state, statuses.statusname
			FROM
				customerdetails
				LEFT JOIN vip ON customerdetails.id=vip.id
				LEFT JOIN statuses ON vip.status=statuses.status
		),
		salesdata(state, statusname, total) AS (
			SELECT state, statusname, total
			FROM customerinfo JOIN sales
				ON customerinfo.id=sales.customerid
		)
	SELECT *
	FROM salesdata;

/*	10.05: Manually Pivoting Data: Summarise Sales Data
	================================================
	================================================ */

	WITH
		statuses(status, statusname) As (
			VALUES
				(1, 'Gold'),
				(2, 'Silver'),
				(3, 'Bronze')
		),
		customerinfo(id, state, statusname) AS (
			SELECT customerdetails.id, state, statuses.statusname
			FROM
				customerdetails
				LEFT JOIN vip ON customerdetails.id=vip.id
				LEFT JOIN statuses ON vip.status=statuses.status
		),
		salesdata(state, statusname, total) AS (
			SELECT state, statusname, total
			FROM customerinfo JOIN sales
				ON customerinfo.id=sales.customerid
		)
	SELECT state, sum(total)
	FROM salesdata
	GROUP BY state;

/*	10.06: Manually Pivoting Data: Using CASE
	================================================
	================================================ */

	WITH
		statuses(status, statusname) As (
			VALUES
				(1, 'Gold'),
				(2, 'Silver'),
				(3, 'Bronze')
		),
		customerinfo(id, state, statusname) AS (
			SELECT customerdetails.id, state, statuses.statusname
			FROM
				customerdetails
				LEFT JOIN vip ON customerdetails.id=vip.id
				LEFT JOIN statuses ON vip.status=statuses.status
		),
		salesdata(state, statusname, total) AS (
			SELECT state, statusname, total
			FROM customerinfo JOIN sales
				ON customerinfo.id=sales.customerid
		)
	SELECT
		state,
		sum(CASE WHEN statusname='Gold' THEN total END) AS gold,
		sum(CASE WHEN statusname='Silver' THEN total END)
			AS silver,
		sum(CASE WHEN statusname='Bronze' THEN total END)
			AS bronze
	FROM salesdata
	GROUP BY state;

/*	10.07:	Pivot Table using PIVOT (MSSQL & Oracle Only)
	================================================
	================================================ */

/*	10.09:	UNPIVOT (MSSQL & Oracle Only)
	================================================
	================================================ */

/*	10.10: Using Variables in PostgreSQL
	================================================
	================================================ */

	DO $$
	DECLARE
		cid INT := 42;
		od TIMESTAMP := current_timestamp;
		sid INT;
	BEGIN
		INSERT INTO sales(customerid, ordered)
		VALUES(cid, current_timestamp)
		RETURNING id INTO sid;

		INSERT INTO saleitems(saleid, bookid, quantity)
		VALUES
			(sid, 123, 3),
			(sid, 456, 1),
			(sid, 789, 2);

		UPDATE saleitems AS si
		SET price=(SELECT price FROM books AS b
			WHERE b.id=si.bookid)
		WHERE saleid=sid;

		UPDATE sales
		SET total=(
			SELECT
				sum(price*quantity)
				* (1 + 0.1)
				* coalesce((SELECT  1 - discount FROM vip WHERE id=cid), 1)
			FROM saleitems WHERE saleid=sid
		)
		WHERE id=sid;
	END $$;

	SELECT * FROM sales ORDER BY id DESC;
	SELECT * FROM saleitems ORDER BY id DESC;
