## Deployment topology

Before we talk about how to deploy Postgres, we first need to decide how we're going to structure our databases. Microservices should have isolated data stores, that is to say, they should not share the same database tables, and ideally, this should be enforced. To implement this with Postgres, there are three different levels of isolation.

1. One database server per service - this is the highest level of isolation. In this setup, a new Postgres pod is deployed for each service that needs it. This pod can be sized exactly according to the services needs, and it shares no resources, CPU or memory, with Postgres pods for other services, and so is completely isolated.
2. One database per service on a single database server. In this setup, a single Postgres pod is provisioned, and multiple databases are created on it, one for each service. Additionally, a user is created for each service, and this user is granted access only to the database for that service. This allows a moderate level of isolation, different databases can be configured to use different volume mounts and are reasonably portable between database services, however, they will share CPU and RAM and hence can impact each other.
3. One database schema per service on a single database. In this setup, a single Postgres pod is provisioned, with a single database, and multiple schemas are created in that database. Additionally, a user is created for each service, and this user is granted access only to the schema for that service. This allows the least level of isolation, since being on the same database, there is no isolation other than access isolation between the stores.

Which setup is appropriate for you depends on your use case and organisation, and in most cases, a combination of multiple setups might be used. Sharing a single pod might be good to start with to minimise resource usage, but as load grows on the services, you might need to split out into multiple pods. A large organisation may also decide to isolate by teams, so each team uses at least one pod, with potentially many databases on each pod if the team manages multiple services.

For the purpose of this guide, we only have one service accessing the database, so it doesn't really matter which option we go with. However, we'll use a setup that makes it easy to add additional databases to the database pod.

We will need to generate a number of passwords. A simple way to generate a secure password, if you have openssl installed, is to use that. For example, to generate a secure 33 character password, you can use this command:

```sh
openssl rand -base64 24
```

## Creating a Postgres pod

OpenShift provides images for deploying Postgres out of the box, making it very straight forward to run Postgres. Detailed documentation on using it can be found [here](https://docs.openshift.com/container-platform/latest/using_images/db_images/postgresql.html). We'll create an ephemeral database service called `postgresql`:

@@snip[postgresql.sh](scripts/postgresql.sh) { #new-app }

@@@note
The database we've just created is using ephemeral persistence, meaning that if the pod is restarted, all data will be lost. Read [the documentation](https://docs.openshift.com/container-platform/latest/using_images/db_images/postgresql.html) for details on how to deploy persistent databases.
@@@

The above database will fail to provision, because the Postgres image requires that an environment variable be set for the Postgres admin password. While we could have specified that when we created the app, this would have hard coded it in the spec for the pod, making it readable to anyone that could read pods. Instead, we're going to create a Kubernetes secret containing it, and then we'll update the deployment to use that secret.

First, create the secret with a random password:

@@snip[postgresql.sh](scripts/postgresql.sh) { #create-admin-password }

Now patch the deployment config just created to use the admin password configured in the service.

@@snip[postgresql.sh](scripts/postgresql.sh) { #patch }

Now watch the database come up (you may see the old database terminate as the new deployment config is applied):

```sh
oc get pods -w
```

### Creating the Postgres database

We now need to create the database, database user, database user password, and the schema. The first thing we'll do is create the password, again using the secret API:

@@snip[postgresql.sh](scripts/postgresql.sh) { #create-user-password }

To create our database, we'll need to access Postgres. There are two ways to do this, the first is using port forwarding, where you open a port on your local machine, and then use the `psql` client installed on your local machine to connect to it. The second is to shell into the Postgres pod using `oc rsh`, and use the `psql` client installed on the pod to connect to Postgres. The first approach is a little simpler, since the `psql` client on your local machine can access SQL scripts locally on your machine, whereas to run a script when you shell into the pod, you will first need to copy the script there using `oc rsync`.

First, start the port forward:

@@snip[postgresql.sh](scripts/postgresql.sh) { #port-forward }

This has started it in the background, it will output some logs when the tunnel is established, and each time it receives a new connection.

Now we can just run the `psql` command to connect as the Postgres admin user. The Postgres image we're using is configured to trust all connections from localhost, and since the port forward command results in connections to it being made on the database as localhost, we can connect as any user without a password. We'll directly feed it a script to create a database, a user, and grant that user access to just read/write operations on the database, so they won't be able to execute any DDL statements. Finally, we'll connect to the database and run the database schema script mentioned before:

@@snip[postgresql.sh](scripts/postgresql.sh) { #create-ddl }

In the above here document, you can see we've loaded the secret that we just created from the secrets API.

Once the schema has been created, you can terminate the port forwarding session by killing it:

```sh
kill %1
```
