# DB 101

## Introduction

This repository contains examples for working with databases and writing queries.
All examples are written for PostgreSQL and are Docker-based for easy setup.
You can also try [pgcli](https://github.com/dbcli/pgcli) for a better PostgreSQL experience.

## Getting Started

Each project is self-contained with its own `docker-compose.yml`. To run any example:

```bash
cd <project-directory>
docker-compose up -d
```

Connect to the database:

```bash
# Using psql
psql -h localhost -U postgres -d pgsql

# Or using pgcli (recommended)
pgcli -h localhost -U postgres -d pgsql
```

Default credentials for all projects: `postgres` / `postgres`

## Projects

### [psql-users](./psql-users/)

**Difficulty:** Beginner

A basic example showing how to write SQL files and mount them into PostgreSQL Docker containers.

**Concepts covered:**

- Basic table creation with `CREATE TABLE`
- Data types: `serial`, `text`, `timestamp`
- Primary keys and `NOT NULL` constraints
- Default values with `DEFAULT now()`
- Docker volume mounting for SQL initialization

---

### [psql-rides](./psql-rides/)

**Difficulty:** Intermediate

A ride-sharing system model (similar to Snapp/Uber) with drivers, passengers, and ride tracking.

**Concepts covered:**

- Custom enumeration types with `CREATE TYPE ... AS ENUM`
- Foreign key relationships with `REFERENCES`
- Event sourcing pattern for ride lifecycle
- Subqueries with `EXISTS` and `ALL`
- Pattern matching with `LIKE`
- `ANY` operator for array/subquery comparisons

**Schema:**

```
passengers (id, first_name, last_name, national_id)
drivers (id, first_name, last_name, national_id)
rides (id, passenger_id, driver_id, event_name, created_at)
```

**Example queries:**

- Find passengers who always had the same driver
- Find passengers with cancelled rides matching a name pattern

---

### [psql-roles](./psql-roles/)

**Difficulty:** Intermediate

An example demonstrating PostgreSQL's role-based access control system.

**Concepts covered:**

- Role creation with `CREATE ROLE`
- Role attributes: `LOGIN`, `SUPERUSER`, `CREATEROLE`
- Password management and expiration with `VALID UNTIL`
- Role inheritance with `GRANT ... TO`
- Permission management with `GRANT SELECT`
- Role modification with `ALTER ROLE`
- Row-level security (RLS) with `ENABLE ROW LEVEL SECURITY`
- Security policies with `CREATE POLICY`
- Bypassing RLS with `BYPASSRLS`

---

### [psql-persons](./psql-persons/)

**Difficulty:** Beginner

An example for schema evolution and database views.

**Concepts covered:**

- Basic table creation
- Schema evolution with `ALTER TABLE ADD COLUMN`
- Conditional modifications with `IF EXISTS` / `IF NOT EXISTS`
- Creating views with `CREATE VIEW`
- Data abstraction through views

---

### [psql-tags](./psql-tags/)

**Difficulty:** Intermediate

An example demonstrating PostgreSQL array data types for flexible data modeling.

**Concepts covered:**

- Array columns with `varchar[]` and `double precision[]`
- Array initialization with `'{}'::varchar[]`
- Array manipulation with `array_append()`
- Array membership checking with `ANY()`
- Many-to-many relationships using arrays (denormalized approach)

**Schema:**

```
tags (id, name, created_at, updated_at)
rooms (id, tag_ids[], coordinates[], created_at, updated_at)
```

---

### [psql-movie](./psql-movie/)

**Difficulty:** Advanced

A comprehensive example using the DVD rental sample database for advanced reporting and procedural programming.

**Concepts covered:**

**Stored Procedures & Functions:**

- `CREATE PROCEDURE` with PL/pgSQL
- `CREATE FUNCTION` with `RETURNS TABLE`
- Conditional logic with `IF/ELSIF`
- `RAISE INFO` for debugging output
- Calling functions within functions

**Triggers:**

- `CREATE TRIGGER` on INSERT/UPDATE
- Trigger functions with `RETURNS TRIGGER`
- Accessing `NEW` record in triggers
- Audit logging patterns

**Advanced Reporting:**

- `ROLLUP` for hierarchical aggregations
- `CUBE` for multi-dimensional aggregations
- `crosstab()` for pivot tables (requires `tablefunc` extension)
- Window functions with `RANK() OVER (PARTITION BY ... ORDER BY ...)`
- Date extraction with `EXTRACT()`
- Subqueries in FROM clause

**Setup:** This project requires downloading the DVD rental sample database. Run `./data-source.sh` first.

---

### [psql-bookworks](./psql-bookworks/)

**Difficulty:** Intermediate

A large sample database for books and publishing, sourced from [sample-db.net](https://sample-db.net).

**Concepts covered:**

- Working with large, realistic datasets
- Complex multi-table schemas
- Exercise queries for practice
- Geographic data (countries, towns)

**Included SQL files:**

- `books-pgsql-10-script.sql` - Main schema and data
- `books-pgsql-10-countries.sql` - Countries reference data
- `books-pgsql-10-towns.sql` - Towns reference data
- `books-pgsql-10-exercises.sql` - Practice queries

## Quick Reference

| Project        | Key Topics                      | Difficulty   |
| -------------- | ------------------------------- | ------------ |
| psql-users     | Basic DDL, Docker setup         | Beginner     |
| psql-persons   | ALTER TABLE, Views              | Beginner     |
| psql-tags      | Arrays, array_append, ANY       | Intermediate |
| psql-rides     | Enums, Foreign Keys, Subqueries | Intermediate |
| psql-roles     | RBAC, RLS, Policies             | Intermediate |
| psql-bookworks | Large datasets, Practice        | Intermediate |
| psql-movie     | Procedures, Triggers, OLAP      | Advanced     |

## PostgreSQL Features Index

| Feature                       | Project                  |
| ----------------------------- | ------------------------ |
| CREATE TABLE                  | psql-users, psql-persons |
| ALTER TABLE                   | psql-persons             |
| CREATE VIEW                   | psql-persons             |
| CREATE TYPE (ENUM)            | psql-rides               |
| Foreign Keys                  | psql-rides               |
| Arrays                        | psql-tags                |
| Subqueries (EXISTS, ALL, ANY) | psql-rides               |
| Roles & Permissions           | psql-roles               |
| Row-Level Security            | psql-roles               |
| Stored Procedures             | psql-movie               |
| User-Defined Functions        | psql-movie               |
| Triggers                      | psql-movie               |
| ROLLUP / CUBE                 | psql-movie               |
| Window Functions              | psql-movie               |
| crosstab (Pivot)              | psql-movie               |
