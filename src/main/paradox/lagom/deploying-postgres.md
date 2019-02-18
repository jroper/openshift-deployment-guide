---
database.name=shopping_cart
database.user=shopping_cart
database.script=schemas/shopping-cart.sql
database.secret=postgres-shopping-cart
---
# Deploying Postgres

The Lagom shopping cart sample app uses Postgres as its database. Lets deploy and configure that first.

## Database schema

Lagom will automatically create the database tables you need for you if they are not there. However, this is not the recommended way to run Lagom in production, since it's generally considered bad practice to allow an application database account to perform DDL statements. Instead, we're going to manually create the database schema needed.

The shopping cart application uses Akka persistence with the [Akka persistence JDBC](https://github.com/dnvriend/akka-persistence-jdbc) backend. This requires two tables, a journal table, which contains all the events for your entities, and a snapshot table, which contains snapshots of the state every so many events. The schema for these tables on Postgres can be found in the [Akka persistence JDBC repository](https://github.com/dnvriend/akka-persistence-jdbc/blob/master/src/test/resources/schema/postgres/postgres-schema.sql), and looks like this:

```sql
CREATE TABLE IF NOT EXISTS journal (
  ordering BIGSERIAL,
  persistence_id VARCHAR(255) NOT NULL,
  sequence_number BIGINT NOT NULL,
  deleted BOOLEAN DEFAULT FALSE,
  tags VARCHAR(255) DEFAULT NULL,
  message BYTEA NOT NULL,
  PRIMARY KEY(persistence_id, sequence_number)
);

CREATE UNIQUE INDEX journal_ordering_idx ON journal(ordering);

CREATE TABLE IF NOT EXISTS snapshot (
  persistence_id VARCHAR(255) NOT NULL,
  sequence_number BIGINT NOT NULL,
  created BIGINT NOT NULL,
  snapshot BYTEA NOT NULL,
  PRIMARY KEY(persistence_id, sequence_number)
);
```

You can find this schema already saved in the project, in `schemas/shopping-cart.sql`. We'll load this script using the `psql` client when we come to create the schema.

@@include[deploying-postgres.md](../includes/deploying-postgres.md)