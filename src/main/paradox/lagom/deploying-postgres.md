---
database.name=shopping_cart
database.user=shopping_cart
database.script=schemas/shopping-cart.sql
database.secret=postgres-shopping-cart
---
# Deploying Postgres

The Lagom shopping cart sample app uses Postgres as its database. Lets deploy and configure that first.

@@include[deploying-postgres.md](../includes/deploying-postgres.md)