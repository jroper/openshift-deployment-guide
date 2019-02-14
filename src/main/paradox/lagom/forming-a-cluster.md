---
service.name = shopping-cart
---
# Forming an Akka cluster

If you're using an of the Akka cluster based features of Lagom, such as Lagom Persistence, or Lagom Pub Sub, you will need to configure your Lagom services to form a cluster. Akka clusters are groups of nodes, usually running the same code base, that distribute their state and work across them. For example, Lagom persistent entities are distributed across an Akka cluster ensuring that each entity only resides on one node at a time, ensuring that strongly consistent operations can be done on that entity without any need of coordination, such as transactions, between nodes.

## Bootstrap process

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #bootstrap-process }

<!--- Later something should exist in Lagom to do automatically --->
@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #bootstrap-deps }

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #configuring }

## Starting

Akka Cluster Bootstrap and Akka Management HTTP both need to be started when your Lagom service starts up. The method to start up depends on whether you're using Scala or Java.

### Scala

To start these components when using Scala, you need to invoke the `start` methods on their respective Akka extensions in your production cake. This should be done in your application loader, which can be found in `com/example/shoppingcart/impl/ShoppingCartLoader` in `shopping-cart-impl/src/main/scala`:

@@snip [ShoppingCartLoader.scala](code/FormingACluster.scala) { #start }

### Java

To start these components when using Java, you need to bind an eager singleton bean that starts them in its constructor. To create the bean, create a class called `com.example.shoppingcart.impl.ClusterBootstrapStart` in `shopping-cart-impl/src/main/java`:

@@snip [ClusterBootstrapStart.java](code/jdocs/lagom/ClusterBootstrapStart.java) { #start }

And now bind that in `com.example.shoppingcart.impl.ShoppingCartModule`:

@@snip [ShoppingCartModule.java](code/jdocs/lagom/FormingACluster.java) { #start }

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #deployment-spec }
