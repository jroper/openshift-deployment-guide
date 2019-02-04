<!--- #bootstrap-process --->
Services that use Akka clustering have a somewhat unique requirement compared to a typical stateless service deployed to OpenShift, they need to form a cluster. To form a cluster, each pod needs to know which other pods have been deployed for the service, so that they can connect to each other. Akka provides a cluster bootstrap library that allows Akka applications in Kubernetes to discover this automatically using the Kubernetes API. The bootstrap process is roughly as follows:

1. When the application starts, the application polls the Kubernetes API to find what pods are deployed, until a configured minimum number of pods have been discovered.
2. It then attempts to connect to those pods, using Akka's HTTP management interface, and queries whether any of those pods have already formed a cluster.
3. If a cluster has already been formed, then the application will join the cluster.
4. If a cluster has not yet been formed on any of the pods, a deterministic function is used to decide which pod will initiate the cluster - this function ensures that all pods that are currently going through this process will decide on the same pod.
5. The pod that is decided to start the cluster forms a cluster with itself.
6. The remaining pods poll that pod until it reports that it has formed a cluster, they then join it.
<!--- #bootstrap-process --->

<!--- #bootstrap-deps --->
## Adding cluster bootstrap to your application

The following dependencies are needed:

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

### Akka management HTTP

Explain why Akka management HTTP is needed.

* Add health checks
* Mention port

### Cluster bootstrap

* Configure bootstrap and Kubernetes discovery
<!--- #configuring -->

## Starting

* Show code to start management and cluster bootstrap

<!--- #deployment-spec --->
## Creating the deployment spec

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
