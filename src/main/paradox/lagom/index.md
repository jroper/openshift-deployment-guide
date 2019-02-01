# Deploying a Lagom application to OpenShift

For this guide we will be using the Lagom shopping cart sample application. It is available for both Java and Scala, and uses a PostgreSQL database.

This sample application just offers a REST API, it does not off a user interface, so we will interact with it using curl. It comprises two services - a shopping cart service, that manages shopping carts, and an inventory service, that tracks inventory levels. The shopping cart service communicates with the inventory service using Kafka, when a user completes the purchase, a message is sent from the shopping cart service to the inventory service.

The shopping cart sample application can be cloned from the following GitHub repositories:

* **Java**: https://github.com/lagom/shopping-cart-java
* **Scala**: https://github.com/lagom/shopping-cart-scala

Before you proceed, it is strongly recommended that you clone the repository, read the README, familiarise yourself with the code, and run it in development to get an understanding for what the sample app is and what it does.

@@toc { depth=1 }

@@@ index

* [Deploying Postgres](deploying-postgres.md)
* [Deploying Kafka](deploying-kafka.md)
* [Deploying using sbt](deploying-using-sbt.md)

@@@
