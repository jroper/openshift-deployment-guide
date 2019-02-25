## Deployment topology

Before we talk about how to deploy Postgres, we first need to decide how we're going to structure our databases. Microservices should have isolated data stores, that is to say, they should not share the same database tables, and ideally, this should be enforced. To implement this with Postgres, there are three different levels of isolation.

1. One database server per service - this is the highest level of isolation. In this setup, a new Postgres pod is deployed for each service that needs it. This pod can be sized exactly according to the services needs, and it shares no resources, CPU or memory, with Postgres pods for other services, and so is completely isolated.
2. One database per service on a single database server. In this setup, a single Postgres pod is provisioned, and multiple databases are created on it, one for each service. Additionally, a user is created for each service, and this user is granted access only to the database for that service. This allows a moderate level of isolation, different databases can be configured to use different volume mounts and a reasonably portable between database services, however, they will share CPU and RAM and hence can impact each other.
3. One database schema per service on a single database. In this setup, a single Postgres pod is provisioned, with a single database, and multiple schemas are created in that database. Additionally, a user is created for each service, and this user is granted access only to the schema for that service. This allows the least level of isolation, since being on the same database, there is no isolation other than access isolation between the stores.

Which setup is appropriate for you depends on your use case and organisation, and in most cases, a combination of multiple setups might be used. Sharing a single pod might be good to start with to minimise resource usage, but as load grows on the services, you might need to split out into multiple pods. A large organisation may also decide to isolate by teams, so each team uses at least one pod, with potentially many databases on each pod if the team manages multiple services.

For the purpose of this guide, we only have one service accessing the database, so it doesn't really matter which option we go with. However, we'll use a setup that makes it easy to add additional databases to the database pod.

We will need to generate a number of passwords. A simple way to generate a secure password, if you have openssl installed, is to use that. For example, to generate a secure 33 character password, you can use this command:

```sh
openssl rand -base64 24
```

## Creating a Postgres pod

OpenShift comes with a template for deploying Postgres out of the box, making it very straight forward to run Postgres. Detailed documentation on using it can be found [here](https://docs.openshift.com/container-platform/latest/using_images/db_images/postgresql.html). We'll create a database service called `postgresql`, and pass the `POSTGRESQL_ADMIN_PASSWORD` environment variable, which will cause it to set up an admin user and create no databases by default:

```sh
export PGPASSWORD=$(openssl rand -base64 24)
oc new-app postgresql -e POSTGRESQL_ADMIN_PASSWORD=$PGPASSWORD
```

@@@warning
This places the PostgreSQL admin password in an environment variable, which is not safe, it is much better to put it in a Kubernetes secret. Unfortunately, the `oc new-app` command [does not allow](https://github.com/openshift/origin/issues/21619) configuring Kubernetes secrets when creating a new app in this way. When going to production, we recommend placing the password in a Kubernetes secret, and then reconfiguring the service after the fact to use the secret rather than placing the password directly in the spec. Reconfiguring is described below.
@@@

Now we can watch the pods to see the `postgresql` pod created:

```sh
oc get pods -w
```

### Reconfigure secrets

Now we'll add the secret to the Kubernetes secret API, and reconfigure the deployment config to consume it from that, so that the admin password secret doesn't appear in the spec for the service. First, create the secret:

```sh
oc create secret generic postgresql-admin-password --from-literal=password=$PGPASSWORD
```

Now patch the deployment config just created to use the admin password configured in the service.

```sh
oc patch deploymentconfig postgresql --patch '{"spec": {"template": {"spec": {"containers": [
  {"name": "postgresql", "env": [
    {"name": "POSTGRESQL_ADMIN_PASSWORD", "value": null, "valueFrom": 
      {"secretKeyRef": {"name": "postgresql-admin-password", "key": "password"}}
    }
  ]}
]}}}}'
```

### Creating the Postgres database

To create our database, we'll need to access Postgres. There are two ways to do this, the first is using port forwarding, where you open a port on your local machine, and then use the `psql` client installed on your local machine to connect to it. The second is to shell into the Postgres pod using `oc rsh`, and use the `psql` client installed on the pod to connect to Postgres. The first approach is a little simpler, since the `psql` client on your local machine can access SQL scripts locally on your machine, whereas to run a script when you shell into the pod, you will first need to copy the script there using `oc rsync`.

You will need two terminal windows to use the port forwarding approach. First, start the port forward:

```sh
oc port-forward svc/postgresql 15432:5432
```

Here we're exposing the `postgresql` service port 5432 on our local machine at port 15432. Now, in the other window, first we setup some our Postgres environment variables, note that we've already set the `PGPASSWORD` environment variable:

```sh
export PGHOST=localhost
export PGPORT=15432
export PGUSER=postgres
```

We'll also generate a new password for the user we're about to create for our application to use:

```
POSTGRES_USER_PASSWORD=$(openssl rand -base64 24)
```

And now we can just run the `psql` command to connect as the Postgres admin user. We'll directly feed it a script to create a database, a user, and grant that user access to just read/write operations on the database, so they won't be able to execute any DDL statements. Finally, we'll connect to the database and run the database schema script mentioned before:

@@@vars
```sql
psql <<DDL
CREATE DATABASE $database.name$;
REVOKE CONNECT ON DATABASE $database.name$ FROM PUBLIC;
CREATE USER $database.user$ WITH PASSWORD '$POSTGRES_USER_PASSWORD';
GRANT CONNECT ON DATABASE $database.user$ TO $database.name$;

\connect $database.name$;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO $database.user$;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $database.user$;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, USAGE ON SEQUENCES TO $database.user$;
  
\include $database.script$;
DDL
```
@@@

Once the schema has been created, you can terminate the port forwarding session in the other window by hitting Ctrl+c. We now need to also put the user password that we just generated in the Kubernetes secrets API, so that the application can access it without having to have it hard coded in its configuration or deployment spec.

@@@vars
```sh
oc create secret generic $database.secret$ --from-literal=username=$database.user$ --from-literal=password="$POSTGRES_USER_PASSWORD"
```
@@@

When we create the deployment spec for the shopping cart service, we'll reference the above configured secret.
