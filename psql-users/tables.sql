create table
  if not exists users (
    id serial primary key,
    first_name text not null,
    last_name text not null,
    created_at timestamp not null default now (),
    phone text not null
  );
