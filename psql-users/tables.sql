CREATE TABLE IF NOT EXISTS users (
    id serial PRIMARY KEY,
    first_name text NOT NULL,
    last_name text NOT NULL,
    created_at timestamp NOT NULL DEFAULT now(),
    phone text NOT NULL
);

