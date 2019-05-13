# Prerequisites

The sample application in this guide depends on a Postgres database, and a Kafka installation.

## Postgres

If you have an existing Postgres database, you can use that. @ref[Appendix A - Deploying Postgres](deploying-postgres.md) describes one way of deploying Postgres to a OpenShift environment if you don't.

For this guide, we will assume the following:

* A Postgres service called `postgresql` is available in the same namespace as the service being deployed.
* That service has a database configured with the schema described in `schemas/shopping-cart.sql` created.
* A Kubernetes secret named `postgres-shopping-cart` has been configured containing the `username` and `password` that the service can use to connect to Postgres.

If you're unsure of how to configure any of the above, see the @ref[appendix](deploying-postgres.md) to see how we set it up.

## Kafka

If you have an existing Kafka installation, you can use that. [Lightbend](https://www.lightbend.com) provides a [commercially supported](https://www.lightbend.com/lightbend-platform) Strimzi installation, we recommend when going to production that you use that. The documentation for using the Lightbend supported Strimzi release can be found [here](https://developer.lightbend.com/docs/fast-data-platform/current/index.html#strimzi-operator-kafka). For development and evaluation purposes though, we provide a quick guide in getting a non production ready Kafka installation setup in @ref[Appendix B - Deploying Kafka](deploying-kafka.md).

This guide assumes that there's a Kafka service with name `strimzi-kafka-brokers` with a TCP port called `clients` for client connections in the same namespace as the service being deployed.
