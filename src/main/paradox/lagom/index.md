# Deploying a Lagom application to OpenShift

For this guide we will be using the Lagom shopping cart sample application. It is available for both [Java](https://github.com/lagom/lagom-samples/tree/1.5.x/shopping-cart/shopping-cart-java) and [Scala](https://github.com/lagom/lagom-samples/tree/1.5.x/shopping-cart/shopping-cart-scala), and uses a PostgreSQL database. This guide covers how to deploy a Lagom 1.5.0 application.

This sample application just offers a REST API, it does not off a user interface, so we will interact with it using `curl`. It comprises two services - a shopping cart service, that manages shopping carts, and an inventory service, that tracks inventory levels. The shopping cart service communicates with the inventory service using Kafka, when a user completes the purchase, a message is sent from the shopping cart service to the inventory service.

The shopping cart sample application can be cloned from the following GitHub repositories:

* **Java**: https://github.com/lagom/lagom-samples/tree/1.5.x/shopping-cart/shopping-cart-java
* **Scala**: https://github.com/lagom/lagom-samples/tree/1.5.x/shopping-cart/shopping-cart-scala

Before you proceed, it is strongly recommended that you clone the repository, read the README, familiarise yourself with the code, and run it in development to get an understanding for what the sample app is and what it does. This will help put more context around the rest of the guide.

@@toc { depth=2 }

@@@ index

* [Prerequisites](prerequisites.md)
* [Preparing for production](preparing-for-production.md)
* [Building the application](building.md)
* [Deploying the application](deploying.md)
* [Appendix A - Deploying Postgres](deploying-postgres.md)
* [Appendix B - Deploying Kafka](deploying-kafka.md)

@@@
