
echo "Installing Postgres"

#new-app
oc new-app postgresql
#new-app

#create-admin-password
oc create secret generic postgresql-admin-password --from-literal=password="$(openssl rand -base64 24)"
#create-admin-password

#patch
oc patch deploymentconfig postgresql --patch '{"spec": {"template": {"spec": {"containers": [
  {"name": "postgresql", "env": [
    {"name": "POSTGRESQL_ADMIN_PASSWORD", "valueFrom":
      {"secretKeyRef": {"name": "postgresql-admin-password", "key": "password"}}
    }
  ]}
]}}}}'
#patch

waitForApp app=postgresql 1

#port-forward
oc port-forward svc/postgresql 15432:5432 &
#port-forward

trap 'kill $(jobs -p)' EXIT

echo Sleeping for 5 seconds while port forward is established...
sleep 5

#create-user-password
oc create secret generic postgres-shopping-cart --from-literal=username=shopping_cart --from-literal=password="$(openssl rand -base64 24)"
#create-user-password

#create-ddl
psql -h localhost -p 15432 -U postgres <<DDL
CREATE DATABASE shopping_cart;
REVOKE CONNECT ON DATABASE shopping_cart FROM PUBLIC;
CREATE USER shopping_cart WITH PASSWORD '$(oc get secret postgres-shopping-cart -o jsonpath='{.data.password}' | base64 --decode)';
GRANT CONNECT ON DATABASE shopping_cart TO shopping_cart;

\connect shopping_cart;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO shopping_cart;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO shopping_cart;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, USAGE ON SEQUENCES TO shopping_cart;

\include schemas/shopping-cart.sql;
DDL
#create-ddl
