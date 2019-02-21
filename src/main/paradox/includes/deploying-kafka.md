Kafka is relatively difficult to install. You need to install ZooKeeper, which Kafka uses to coordinate between its nodes, and ZooKeeper should be installed in a clustered configuration with at least three nodes. Then you need to install Kafka, which once again should be installed in a clustered configuration with at least three nodes.

Fortunately, Kubernetes provides a mechanism for capturing the operational concerns of difficult deployments like this, using a feature called operators. An operator is able to encode how to provision and configure deployments, providing high level features to scale them up and down, allowing backups, and so on, allowing you as the end user to deploy the components the operator manages with minimal effort. [Strimzi](https://strimzi.io/) is an open source project that provides an operator for Kafka.

[Lightbend](https://www.lightbend.com) provides a [commercially supported](https://www.lightbend.com/lightbend-platform) Strimzi installation, we recommend when going to production that you use that. This guide provides a means to deploy Kafka as quickly and simply as possible for evaluation purposes, it won't give you a robust production setup.

## Installing Strimzi

To install the Strimzi cluster operator, you need to be logged in as a cluster administrator. If using Minishift, you can log in using the following command:

```sh
oc login -u system:admin
```

Now you can install Strimzi using the following command:

@@@vars
```sh
oc apply -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/$strimzi.version$/strimzi-cluster-operator-$strimzi.version$.yaml -n myproject
```
@@@

@@@note
Be careful to ensure that the `myproject` project matches the OpenShift project you are using.
@@@

At this point, nothing has actually been deployed other than the operator. With the operator installed, we're ready to deploy a Kafka instance.

## Deploying a Kafka instance

If you're deploying to a real cluster with many physical machines, then it's best to deploy with three Kafka nodes to get a realistic production setup. The spec below deploys three Kafka nodes, one ZooKeeper node, and uses ephemeral storage (so if your nodes are destroyed, they lose their data).

```yaml
apiVersion: kafka.strimzi.io/v1alpha1
kind: Kafka
metadata:
  name: strimzi
spec:
  kafka:
    replicas: 3
    listeners:
      plain: {}
      tls: {}
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
    storage:
      type: ephemeral
  zookeeper:
    replicas: 1
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

To deploy this, create a file called `kafka.yaml`, and run:

```sh
oc apply -f kafka.yaml -n myproject
```

If you're deploying to Minishift however, then you'll likely find that by the time all the ZooKeeper and Kafka instances are deployed, along with all the auxiliary services deployed by the operator, you're machine has no resources left for anything else. So instead we'll use a spec that only deploys one Kafka replica and one ZooKeeper replica. In addition, we'll need to change the replication factors to one, since with only one replica, we can't replicate more than once.

```yaml
apiVersion: kafka.strimzi.io/v1alpha1
kind: Kafka
metadata:
  name: strimzi
spec:
  kafka:
    replicas: 3
    listeners:
      plain: {}
      tls: {}
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
    storage:
      type: ephemeral
  zookeeper:
    replicas: 1
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

Save the above YAML to a file called `kafka.yaml`, and run:

```sh
oc apply -f kafka.yaml -n myproject
```

Once you've deployed your Kafka instance, you can watch it come up by running:

```sh
oc get pods -w -n myproject
```

You should eventually see something like the following output, with the number of Kafka and ZooKeeper pods corresponding to how many you configured above.

```
strimzi-entity-operator-6bc7f6985c-q29p5   3/3     Running   0          44s
strimzi-kafka-0                            2/2     Running   1          91s
strimzi-kafka-1                            2/2     Running   1          91s
strimzi-kafka-2                            2/2     Running   1          91s
strimzi-zookeeper-0                        2/2     Running   0          2m30s
strimzi-cluster-operator-78f8bf857-kpmhb   1/1     Running   0          3m10s
```

It's also useful to see what services have been deployed:

```sh
oc get services -n myproject
```

This should show at least:

```
strimzi-kafka-bootstrap    ClusterIP   172.30.231.126   <none>        9091/TCP,9092/TCP,9093/TCP,9404/TCP   2m
strimzi-kafka-brokers      ClusterIP   None             <none>        9091/TCP,9092/TCP,9093/TCP            2m
strimzi-zookeeper-client   ClusterIP   172.30.226.168   <none>        9404/TCP,2181/TCP                     3m
strimzi-zookeeper-nodes    ClusterIP   None             <none>        2181/TCP,2888/TCP,3888/TCP            3m
```

As you can see, there is a service called `strimzi-kafka-brokers`, this is the service that Kafka clients are going to connect to.

Once Kafka is deployed and running, you no longer need to be logged in as an administrator, so log back in as your old user. If using Minishift, that means logging in as the developer user:

```sh
oc login -u developer
```
