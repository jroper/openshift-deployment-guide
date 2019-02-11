<!--- #bootstrap-process --->
Services that use Akka clustering have a somewhat unique requirement compared to a typical stateless service deployed to OpenShift. To form a cluster, each pod needs to know which other pods have been deployed for the service, so that they can connect to each other. Akka provides a cluster bootstrap library that allows Akka applications in Kubernetes to discover this automatically using the Kubernetes API. The bootstrap process is roughly as follows:

1. When the application starts, the application polls the Kubernetes API to find what pods are deployed, until a configured minimum number of pods have been discovered.
2. It then attempts to connect to those pods, using Akka's HTTP management interface, and queries whether any of those pods have already formed a cluster.
3. If a cluster has already been formed, then the application will join the cluster.
4. If a cluster has not yet been formed on any of the pods, a deterministic function is used to decide which pod will initiate the cluster - this function ensures that all pods that are currently going through this process will decide on the same pod.
5. The pod that is decided to start the cluster forms a cluster with itself.
6. The remaining pods poll that pod until it reports that it has formed a cluster, they then join it.
<!--- #bootstrap-process --->

<!--- #bootstrap-deps --->
## Adding cluster bootstrap to your application

To use Akka cluster bootstrap, you'll need to add the following dependencies to your application:

sbt
:    @@@vars
```scala
libraryDependencies ++= Seq(
  "com.lightbend.akka.management" %% "akka-management-cluster-bootstrap" % "$akka.management.version$",
  "com.lightbend.akka.management" %% "akka-discovery-kubernetes-api" % "$akka.management.version$"
)
```
@@@

Maven
:    @@@vars
```xml
<dependency>
  <groupId>com.lightbend.akka.management</groupId>
  <artifactId>akka-management-cluster-bootstrap_2.12</artifactId>
  <version>$akka.management.version$</version>
</dependency>
<dependency>
  <groupId>com.lightbend.akka.management</groupId>
  <artifactId>akka-discovery-kubernetes-api_2.12</artifactId>
  <version>$akka.management.version$</version>
</dependency>
```
@@@
<!--- #bootstrap-deps --->

<!--- #configuring -->
## Configuring cluster bootstrap

There are three components that need to be configured for cluster bootstrap to work, Akka Cluster, Akka Management HTTP, and Akka Cluster Bootstrap.

### Akka Cluster

The first thing that's needed is a general Akka cluster configuration. For the most part, we'll rely on the defaults, for example, the default port that Akka remoting binds to is 2552. But there are a few things we need to tweak. We need to first enable Akka cluster by making it the Actor provider. We also want to tell Akka to shut itself down if it's unable to join the cluster after a given timeout.

```
akka {
    actor {
        provider = cluster
    }

    cluster {
        shutdown-after-unsuccessful-join-seed-nodes = 60s
    }
}
```

### Akka management HTTP

Akka management HTTP provides an HTTP API for querying the status of the Akka cluster, used both by the bootstrap process, as well as healthchecks to ensure requests don't get routed to your pods until the pods have joined the cluster.

The default configuration for Akka management HTTP is suitable for use in Kubernetes, it will bind to a default port of 8558 on the pods external IP address. It will also expose liveness and readiness health checks on `/alive` and `/ready` respectively, and included in the readiness check will be a check to ensure that a cluster has been formed.

### Cluster bootstrap

To configure cluster bootstrap, we need to tell it which discovery method will be used to discover the other nodes in the cluster. This uses Akka discovery to find nodes, however, the discovery method and configuration used in cluster bootstrap will often be different to the method used for looking up other services. The reason for this is that during cluster bootstrap, we are interested in discovering nodes even when they aren't ready to handle requests yet, for example, because they too are trying to form a cluster. If we were to use a method such as DNS to lookup other services, the Kubernetes DNS server, by default, will only return services that are ready to serve requests, indicated by their readiness check passing. Hence, when forming a new cluster, there is a chicken or egg problem, Kubernetes won't tell us which nodes are running that we can form a cluster with until those nodes are ready, and those nodes won't pass their readiness check until they've formed a cluster.

Hence, we need to use a different discovery method for cluster bootstrap, and for Kubernetes, the simplest method is to use the Kubernetes API, which will return all nodes regardless of their readiness state. This can be configured like so:

```
akka.management.cluster.bootstrap {
  contact-point-discovery {
    discovery-method = kubernetes-api
    required-contact-point-nr = ${REQUIRED_CONTACT_POINT_NR}
    kubernetes-api {
      pod-port-name = management
      pod-label-selector = "app=%s"
    }
  }
}               
```

A few things to note:

* The `required-contact-point-nr` has been configured to read the environment variable `REQUIRED_CONTACT_POINT_NR`. This is the number of pods that Akka Cluster Bootstrap must discover before it will form a cluster. It's very important to get this number right, let's say it was configured to be two, and you deployed five pods for this application, and all five started at once, it's possible, due to eventual consistency in the Kubernetes API, that two of the nodes might discover each other, and decide to form a cluster, and the other two nodes might discover each other, and also decide to form a cluster. The result will be two separate clusters formed, and this can have disastrous results. For this reason, we'll pass this in the deployment spec, which will be the same place that we'll configure the number of replicas. This will help us ensure that the number of replicas equals the required contact point number, ensuring we safely form one and only one cluster on bootstrap.
* The `pod-port-name` and `pod-label-selector` are actually set to their default values, and so are not needed, however it's important that the match what's in the deployment spec. The `pod-port-name` needs to match a `ports` entry in the pod spec, while the `pod-label-selector` needs to match a query that will return only and all the pods for this particular selector.
<!--- #configuring -->

## Starting

* Show code to start management and cluster bootstrap

<!--- #deployment-spec --->
## Updating the deployment spec

### RBAC

* Briefly explain RBAC, why it's needed, and show YAML

### Replicas and contact points

* Show configuring replicas and contact points environment variable

### Namespace

* Show how to pass the namespace

### Management port configuration

* Show defining the management port

### Health checks

* Show health check configuration
<!--- #deployment-spec --->
