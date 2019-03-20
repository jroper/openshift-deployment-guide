# Forming an Akka cluster

If you're using any of the Akka cluster based features of Lagom, such as Lagom Persistence, or Lagom Pub Sub, you will need to configure your Lagom services to form a cluster. Akka clusters are groups of nodes, usually running the same code base, that distribute their state and work across them. For example, Lagom persistent entities are distributed across an Akka cluster ensuring that each entity only resides on one node at a time, ensuring that strongly consistent operations can be done on that entity without any need of coordination, such as transactions, between nodes.

## Bootstrap process

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #bootstrap-process }

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #configuring }

These components are automatically added by Lagom whenever Lagom Persistence or Lagom Pub Sub is in use, or when you explicitly enable clustering in Lagom. The following sections explain their roles, how they fit together and which extra configurations are needed.

### Akka Cluster

Most of the Akka cluster configuration is already handled by Lagom. There are two things we need to configure, we need to tell Akka to shut itself down if it's unable to join the cluster after a given timeout and we need to tell Lagom to exit the JVM when that happens. This is very important, @ref:[as we will see further down](#health-checks), we will use the cluster formation status to decide when the service is ready to receive traffic by means of configuring a readiness health check probe. Kubernetes won't restart an application based on the readiness probe, therefore, if for some reason we fail to form a cluster we must have the means to stop the pod and let Kubernetes re-create it.

```HOCON
# after 60s of unsuccessul attempts to form a cluster, 
# the actor system will be terminated
akka.cluster.shutdown-after-unsuccessful-join-seed-nodes = 60s

# exit jvm on actor system termination
# this will allow Kubernetes to restart the pod
lagom.cluster.exit-jvm-when-system-terminated = on
```

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #configuring-akka-mngt-config }

This component is already included and configured by Lagom. 

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #configuring-cluster-bootsrap-config }

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #deployment-spec }

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #configuring-health-check }

Lagom also includes the routes for `akka-management-cluster-http`, meaning that the readiness check will take the cluster membership status into consideration.

@@include[forming-a-cluster.md](../includes/forming-a-cluster.md) { #configuring-health-check-spec }