<!--- #bootstrap-process --->
Services that use Akka clustering have a somewhat unique requirement compared to a typical stateless service deployed to OpenShift. To form a cluster, each pod needs to know which other pods have been deployed as part of that service, so that they can connect to each other. Akka provides a cluster bootstrap library that allows Akka applications in Kubernetes to discover this automatically using the Kubernetes API. The bootstrap process is roughly as follows:

1. When the application starts, the application polls the Kubernetes API to find what pods are deployed, until a configured minimum number of pods have been discovered.
2. It then attempts to connect to those pods, using Akka's HTTP management interface, and queries whether any of those pods have already formed a cluster.
3. If a cluster has already been formed, then the application will join the cluster.
4. If a cluster has not yet been formed on any of the pods, a deterministic function is used to decide which pod will initiate the cluster - this function ensures that all pods that are currently going through this process will decide on the same pod.
5. The pod that is decided to start the cluster forms a cluster with itself.
6. The remaining pods poll that pod until it reports that it has formed a cluster, they then join it.

For a much more detailed description of this process, see the [Akka Cluster Bootstrap documentation](https://developer.lightbend.com/docs/akka-management/current/bootstrap/details.html).
<!--- #bootstrap-process --->

<!--- #bootstrap-deps --->
## Adding cluster bootstrap to your application

To use Akka cluster bootstrap, you'll need to add the following dependencies to your application:

sbt
:    @@@vars
```scala
libraryDependencies ++= Seq(
  "com.lightbend.akka.management" %% "akka-management-cluster-bootstrap" % "$akka.management.version$",
  "com.lightbend.akka.management" %% "akka-management-cluster-http" % "$akka.management.version$",
  "com.lightbend.akka.discovery" %% "akka-discovery-kubernetes-api" % "$akka.management.version$"
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
  <artifactId>akka-management-cluster-http_2.12</artifactId>
  <version>$akka.management.version$</version>
</dependency>
<dependency>
  <groupId>com.lightbend.akka.discovery</groupId>
  <artifactId>akka-discovery-kubernetes-api_2.12</artifactId>
  <version>$akka.management.version$</version>
</dependency>
```
@@@
<!--- #bootstrap-deps --->

<!--- #configuring -->
## Configuring cluster bootstrap

There are three components that need to be configured for cluster bootstrap to work, Akka Cluster, Akka Management HTTP, and Akka Cluster Bootstrap.
<!--- #configuring -->

<!--- #configuring-general-config -->
### Akka Cluster

The first thing that's needed is a general Akka cluster configuration. For the most part, we'll rely on the defaults, for example, the default port that Akka remoting binds to is 2552. But there are a few things we need to tweak. We need to first enable Akka cluster by making it the Actor provider. We also want to tell Akka to shut itself down if it's unable to join the cluster after a given timeout. This is very important, as we will see further down, we will use the cluster formation status to decide when the service is ready to receive traffic by means of configuring a readiness health check probe. Kubernetes won't restart an application based on the readiness probe, therefore, if for some reason we fail to form a cluster we must have the means to stop the pod and let Kubernetes re-create it.

```HOCON
akka {
    actor {
        provider = cluster
    }

    cluster {
        # after 60s of unsuccessul attempts to form a cluster, 
        # the actor system will be terminated
        shutdown-after-unsuccessful-join-seed-nodes = 60s
        # exit jvm on actor system termination
        akka.coordinated-shutdown.exit-jvm = on
    }
}
```
<!--- #configuring-general-config -->


<!--- #configuring-akka-mngt-config -->
### Akka management HTTP

Akka management HTTP provides an HTTP API for querying the status of the Akka cluster, used both by the bootstrap process, as well as healthchecks to ensure requests don't get routed to your pods until the pods have joined the cluster.

The default configuration for Akka management HTTP is suitable for use in Kubernetes, it will bind to a default port of 8558 on the pods external IP address.
<!--- #configuring-akka-mngt-config -->

<!--- #configuring-health-check-config -->
### Health Checks

Akka management HTTP includes [health check routes](https://developer.lightbend.com/docs/akka-management/current/healthchecks.html) that will expose liveness and readiness health checks on `/alive` and `/ready` respectively. 

In Kubernetes, if an application is live, it means its running - it hasn't crashed. But it may not necessarily be ready to serve requests, for example, it might not yet have managed to connect to a database, or in our case, it may not have formed a cluster yet. By separating liveness and readiness, Kubernetes can distinguish between fatal errors, like crashing, and transient errors, like not being able to contact other resources that the application depends on, allowing Kubernetes to make more intelligent decisions about whether an application needs to be restarted, or if it just needs to be given time to sort itself out.

These routes expose information which is the result of multiple internal checks. For example, by depending on `akka-management-cluster-http` the health checks will take cluster membership status into consideration and will be a check to ensure that a cluster has been formed.
<!--- #configuring-health-check-config -->

<!--- #configuring-cluster-bootsrap-config -->
### Cluster bootstrap

To configure cluster bootstrap, we need to tell it which discovery method will be used to discover the other nodes in the cluster. This uses Akka discovery to find nodes, however, the discovery method and configuration used in cluster bootstrap will often be different to the method used for looking up other services. The reason for this is that during cluster bootstrap, we are interested in discovering nodes even when they aren't ready to handle requests yet, for example, because they too are trying to form a cluster. If we were to use a method such as DNS to lookup other services, the Kubernetes DNS server, by default, will only return services that are ready to serve requests, indicated by their readiness check passing. Hence, when forming a new cluster, there is a chicken or egg problem, Kubernetes won't tell us which nodes are running that we can form a cluster with until those nodes are ready, and those nodes won't pass their readiness check until they've formed a cluster.

Hence, we need to use a different discovery method for cluster bootstrap, and for Kubernetes, the simplest method is to use the Kubernetes API, which will return all nodes regardless of their readiness state. 

First, you need to depend on `akka-discovery-kubernetes-api`: 

sbt
:    @@@vars
```scala
libraryDependencies ++= Seq(
  "com.lightbend.akka.discovery" %% "akka-discovery-kubernetes-api" % "$akka.management.version$"
)
```
@@@

Maven
:    @@@vars
```xml
<dependency>
  <groupId>com.lightbend.akka.discovery</groupId>
  <artifactId>akka-discovery-kubernetes-api_2.12</artifactId>
  <version>$akka.management.version$</version>
</dependency>
```
@@@

Then you must configure that discovery mechanism like so:

@@@vars
```
akka.management {
  cluster.bootstrap {
    contact-point-discovery {
      discovery-method = kubernetes-api
      service-name = "shopping-cart"
      required-contact-point-nr = ${REQUIRED_CONTACT_POINT_NR}
    }
  }
}
```
@@@

A few things to note:

* The `service-name` needs to match the `app` label applied to your pods in the deployment spec.
* The `required-contact-point-nr` has been configured to read the environment variable `REQUIRED_CONTACT_POINT_NR`. This is the number of pods that Akka Cluster Bootstrap must discover before it will form a cluster. It's very important to get this number right, let's say it was configured to be two, and you deployed five pods for this application, and all five started at once, it's possible, due to eventual consistency in the Kubernetes API, that two of the nodes might discover each other, and decide to form a cluster, and the other two nodes might discover each other, and also decide to form a cluster. The result will be two separate clusters formed, and this can have disastrous results. For this reason, we'll pass this in the deployment spec, which will be the same place that we'll configure the number of replicas. This will help us ensure that the number of replicas equals the required contact point number, ensuring we safely form one and only one cluster on bootstrap.
* Querying the Kubernetes API will require setting up Kubernetes RBAC (see below). 
<!--- #configuring-cluster-bootsrap-config -->

## Starting

To ensure that cluster bootstrap is started, both the cluster bootstrap and the Akka Management extensions must be started. This can be done by invoking the `start` method on both the `ClusterBoostrap` and `AkkaManagement` extensions when your application starts up.

Scala
:   @@snip [Example.scala](code/FormingACluster.scala) { #start }

Java
:   @@snip [Example.java](code/jdocs/includes/FormingACluster.java) { #start }

<!--- #deployment-spec --->
## Updating the deployment spec

### Role-Based Access Control

By default, pods are unable to use the Kubernetes API because they are not authenticated to do so. In order to allow the applications pods to form an Akka CLuster using the Kubernetes API, we need to define some Role-Based Access Control (RBAC) roles and bindings.

RBAC allows the configuration of access control using two key concepts, roles, and role bindings. A role is a set of permissions to access something in the Kubernetes API. For example, a `pod-reader` role may have permission to perform the `list`, `get` and `watch` operations on the `pods` resource in a particular namespace, by default the same namespace that the role is configured in. In fact, that's exactly what we are going to configure, as this is the permission that our pods need. Here's the spec for the `pod-reader` role:

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

Having configured a role, you can then bind that role to a subject. A subject is typically either a user or a group, and a user may be a human user, or it could be a service account. A service account is an account created by Kubernetes for Kubernetes resources, such as applications running in pods, to access the Kubernetes API. Each namespace has a default service account that is used by default by pods that don't explicitly declare a service account, otherwise, you can define your own service accounts. Kubernetes automatically injects the credentials of a pods service account into that pods filesystem, allowing the pod to use them to make authenticated requests on the Kubernetes API.

Since we are just using the default service account, we need to bind our role to the default service account so that our pod will be able to access the Kubernetes API as a `pod-reader`:

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
subjects:
- kind: User
  name: system:serviceaccount:myproject:default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Note the service account name, `system:serviceaccount:myproject:default`, contains the `myproject` namespace in it. If you are using a different project name, you'll need to update it accordingly.

#### A note on secrets with RBAC

One thing to be aware of when using role based access control, the `pod-reader` role is going to grant access to read all pods in the `myproject` namespace, not just the pods for your application. This includes the deployment specs, which includes the environment variables that are hard coded in the deployment specs. If you pass secrets through those environment variables, rather than using the Kubernetes secrets API, then your application, and every other app that uses the default service account, will be able to see these secrets. This is a good reason why you should never pass secrets directly in deployment specs, rather, you should pass them through the Kubernetes secrets API.

If this is a concern, one solution might be to create a separate namespace for each application you wish to deploy. You may find the configuration overhead of doing this very high though, it's not what Kubernetes namespaces are intended to be used for.

### Replicas and contact points

In the @ref:[cluster bootstrap configuration section](#cluster-bootstrap), we used a `REQUIRED_CONTACT_POINT_NR` environment variable. Let's configure that now in our spec. It needs to match the number of replicas that we're going to deploy. If you're really strapped for resources in your cluster, you might set this to one, but for the purposes of this demo we strongly recommend that you set it to 3 or more to see an Akka cluster form.

In the deployment spec, set the replicas to 3:

@@@vars
```yaml
apiVersion: "apps/v1beta2"
kind: Deployment
metadata:
  name: shopping-cart
  labels:
    app: shopping-cart
spec:
  replicas: 3
```
@@@

Now down in the environment variables section, add the `REQUIRED_CONTACT_POINT_NR` environment variable to match:

```yaml
- name: REQUIRED_CONTACT_POINT_NR
  value: "3"
```

### Health checks

Finally, we need to configure the health checks. As mentioned earlier, Akka Management HTTP provides health check endpoints for us, both for readiness and liveness. Kubernetes just needs to be told about this. The first thing we do is configure a name for the management port, while not strictly necessary, this allows us to refer to it by name in the probes, rather than repeating the port number each time. We'll configure some of the numbers around here, we're going to tell Kubernetes to wait 20 seconds before attempting to probe anything, this gives our cluster a chance to start before Kubernetes starts trying to ask us if it's ready, and since in some scenarios, particularly if you haven't assigned a lot of CPU to your pods, it can take a long time for the cluster to start, so we'll give it a high failure threshold of 10.

```yaml
ports:
  - name: management
    containerPort: 8558
<<<<<<< HEAD
=======
```

### Health checks probes configuration 

Finally, we need to configure the health checks. As mentioned earlier, Akka Management HTTP provides health check endpoints for us, both for readiness and liveness. Kubernetes just needs to be told about this. In addition, we'll configure some of the numbers around here, we're going to tell Kubernetes to wait 20 seconds before attempting to probe anything, this gives our cluster a chance to start before Kubernetes starts trying to ask us if it's ready, and since in some scenarios, particularly if you haven't assigned a lot of CPU to your pods, it can take a long time for the cluster to start, so we'll give it a high failure threshold of 10.

```yaml
>>>>>>> Adapt for Lagom 1.5.0 deployment
readinessProbe:
  httpGet:
    path: "/ready"
    port: management
  periodSeconds: 10
  failureThreshold: 10
  initialDelaySeconds: 20
livenessProbe:
  httpGet:
    path: "/alive"
    port: management
  periodSeconds: 10
  failureThreshold: 10
  initialDelaySeconds: 20
```
<!--- #deployment-spec --->
