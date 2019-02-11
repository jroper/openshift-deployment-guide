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

TODO

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #deployment-spec }
