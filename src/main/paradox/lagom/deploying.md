---
service.name = shopping-cart
actor.system.name = application
spec.path = deploy/shopping-cart.yaml
---
# Deploying

With the docker image built and pushed to the OpenShift registry, we can now deploy the deployment config that we've built.

Run the following command:

@@@vars
```sh
oc apply -f $spec.path$
```
@@@

@@@note
If you haven't been creating the files as you go for the guide, but rather are relying on the existing files distributed with the sample app, make sure you have performed the following easy to miss steps:

* The $spec.path$ `RoleBinding` spec @ref[needs to have the namespace updated](forming-a-cluster.md#role-based-access-control) for the user name if you are not using the `myproject` namespace.
* You need to have @ref[created the application secret](preparing-for-production.md#application-secret).
@@@

Immediately after running this, you should see the three shopping cart pods when you run `oc get pods`:

@@@vars
```
$service.name$-756894d68d-9sltd         0/1       Running   0          9s
$service.name$-756894d68d-bccdv         0/1       Running   0          9s
$service.name$-756894d68d-d8h5j         0/1       Running   0          9s
```
@@@

## Understanding bootstrap logs

Let's take a look at their logs as they go through the cluster bootstrap process. The logs can be very useful for diagnosing cluster startup problems, so understanding what messages will be logged when, and what information they should contain, can greatly help in achieving that.

To view the logs, select one of the pods from the above output (the actual name is random so you'll need to copy from your output, not use the name in this guide), and run:

@@@vars
```sh
oc log -f pods/$service.name$-756894d68d-9sltd
```
@@@

By default, the logging in the application during startup is reasonably noisy. You may wish to set the logging to a higher threshold (eg warn) if you wish to make the logs quieter, but for now it will help us to understand what is happening. Below is a curated selection of log messages, with much of the extraneous information (such as timestamps, threads, logger names) removed. Also, you will see a lot of info messages when features that depend on the cluster start up, but a cluster has not yet been formed. Typically these messages come from cluster singleton or shard region actors. These messages will stop soon after the cluster is formed, and can be safely ignored.

@@@vars
```
1  [info] Remoting started; listening on addresses :[akka.tcp://$actor.system.name$@172.17.0.12:2552]
   [info] Cluster Node [akka.tcp://$actor.system.name$@172.17.0.12:2552] - Started up successfully
   [info] Bootstrap using `akka.discovery` method: kubernetes-api
2  [info] Binding Akka Management (HTTP) endpoint to: 172.17.0.12:8558
   [info] Using self contact point address: http://172.17.0.12:8558
3  [info] Looking up [Lookup($service.name$,Some(management),Some(tcp))]
4  [info] Querying for pods with label selector: [app=$service.name$]. Namespace: [myproject]. Port: [management]
5  [info] Located service members based on: [Lookup($service.name$,Some(management),Some(tcp))]:
     [ResolvedTarget(172-17-0-12.myproject.pod.cluster.local,Some(8558),Some(/172.17.0.12)),
      ResolvedTarget(172-17-0-11.myproject.pod.cluster.local,Some(8558),Some(/172.17.0.11)),
      ResolvedTarget(172-17-0-13.myproject.pod.cluster.local,Some(8558),Some(/172.17.0.13))]
6  [info] Discovered [3] contact points, confirmed [0], which is less than the required [3], retrying
7  [info] Contact point [akka.tcp://$actor.system.name$@172.17.0.13:2552] returned [0] seed-nodes []
8  [info] Bootstrap request from 172.17.0.12:47312: Contact Point returning 0 seed-nodes ([TreeSet()])
9  [info] Exceeded stable margins without locating seed-nodes, however this node 172.17.0.12:8558
     is NOT the lowest address out of the discovered endpoints in this deployment, thus NOT joining
     self. Expecting node [ResolvedTarget(172-17-0-11.myproject.pod.cluster.local,Some(8558),Some(/172.17.0.11))]
     to perform the self-join and initiate the cluster.
10 [info] Contact point [akka.tcp://$actor.system.name$@172.17.0.11:2552] returned [1] seed-nodes
     [akka.tcp://$actor.system.name$@172.17.0.11:2552]
11 [info] Joining [akka.tcp://$actor.system.name$@172.17.0.12:2552] to existing cluster
     [akka.tcp://$actor.system.name$@172.17.0.11:2552]
12 [info] Cluster Node [akka.tcp://$actor.system.name$@172.17.0.12:2552] - Welcome from [akka.tcp://$actor.system.name$@172.17.0.11:2552]
```
@@@

An explanation of these messages is as follows.

1. These are init messages, showing that remoting has started on port 2552. The IP address should be the pods IP address from which other pods can access it, while the port number should match the configured remoting number, defaulting to 2552.
2. Init messages for Akka management, once again, the IP address should be the pods IP address, while the port number should be the port number you've configured for Akka management to use, defaulting to 8558.
3. Now the cluster bootstrap process is starting. The service name should match your configured service name in cluster bootstrap, and the port should match your configured port name. This and subsequent messages will be repeated many times as cluster bootstrap polls Kubernetes and the other pods to determine what pods have been started, and whether and where a cluster has been formed.
4. This log message comes from the Kubernetes API implementation of Akka discovery, the label selector should be one that will return your pods, and the namespace should match your applications namespace.
5. Here the Kubernetes API has returned three services, including ourselves.
6. This log message shows what cluster bootstrap has decided to do with the three services. It has found three, but so far it has not confirmed whether any of them have joined a cluster yet, hence, it will continue retrying looking them up, and attempting to contact them, until it has found that a cluster has been, or can be started.
7. This message will appear many times, it's the result of probing one of the contact points to find out if it has formed a cluster.
8. This message will also appear many times, it's the result of this pod being probed by another pod to find out if it has formed a cluster.
9. This message may or may not appear, depending on how fast your pods are able to start given the amount of resources. It's simply informing you that the pod hasn't located a seed node yet, but it's not going to try and form a cluster since it not the pod with the lowest IP address.
10. Eventually, this message will change to report that one of the pods has formed a cluster.
11. The pod has decided to join an existing cluster.
12. The pod has joined the cluster.

Following these messages, you may still some messages warning that messages can't be routed, it still may take some time for cluster singletons and other cluster features to decide which pod to start up on, but before long, the logs should go quiet as the cluster is started up.

The logs above show those of a pod that wasn't the pod to start the cluster. As mentioned earlier, the default strategy that Akka Cluster Bootstrap uses when it starts and finds that there is no existing cluster is to get the pod with the lowest IP address to start the cluster. In the example above, that pod has an IP address of `172.17.0.11`, and you can see at 10 that it eventually returns itself as a seed node, which results in this pod joining it.

If you look in the logs of that pod, you'll see a message like this: 

```
[info] Initiating new cluster, self-joining [akka.tcp://application@172.17.0.11:2552].
   Other nodes are expected to locate this cluster via continued contact-point probing.
```

This message will appear after a timeout called the stable margin, which defaults to 5 seconds, at that point, the pod has seen that there have been no changes to the number of pods deployed for 5 seconds, and so given that it has the lowest IP address, it considers it safe for it to start a new cluster.

If your cluster is failing to form, carefully check over the logs for the following things:

* Make sure the right IP addresses are in use. If you see `localhost` or `127.0.0.1` used anywhere, that is generally an indication of a misconfiguration.
* Ensure that the namespace, service name, label selector, port name and protocol matches your deployment spec.
* Ensure that the port numbers match what you've configured both in the configuration files and in your deployment spec.
* Ensure that the required contact point number matches your configuration and the number of replicas you have deployed.
* Ensure that pods are successfully polling each other, looking for messages such as `Contact point [...] returned...` for outgoing polls and `Bootstrap request from ...` for incoming polls from other pods.

## Interacting with the service

Once the service is running, and a cluster has formed, the state should change to ready, this can be seen when running `oc get pods`:

@@@vars
```
$service.name$-756894d68d-9sltd         1/1       Running   0          9s
$service.name$-756894d68d-bccdv         1/1       Running   0          9s
$service.name$-756894d68d-d8h5j         1/1       Running   0          9s
```
@@@

Now you can interact with the service. First we need to expose it to the outside world. We can do this using the `oc expose` command. If running on Minishift, there's no need to tell it what IP address or host name to expose the service on, Minishift will generate one for you:

@@@vars
```
oc expose svc/$service.name$
```
@@@

You can then see the hostname to access it by getting the routes:

@@@vars
```
$ oc get routes/$service.name$
```
@@@

You should see this:

@@@vars
```
$service.name$   $service.name$-myproject.192.168.42.246.nip.io  $service.name$  http   None
```
@@@

You can use the hostname to connect to the service, let's try that:

@@@vars
```
$ curl http://$service.name$-myproject.192.168.42.246.nip.io/shoppingcart/123
{"id":"123","items":[],"checkedOut":false}
```
@@@

For convenience, let's place the hostname in an environment variable, which will then allow the remainder of the curl commands to be copied and pasted into your terminal as is.

@@@vars
```
$ SHOPPING_CART_HOST=$service.name$-myproject.192.168.42.246.nip.io
```
@@@

Now let's try adding some items to the shopping cart:

```
curl -H "Content-Type: application/json" -X POST -d '{"productId": "456", "quantity": 2}' \
 http://$SHOPPING_CART_HOST/shoppingcart/123
curl -H "Content-Type: application/json" -X POST -d '{"productId": "789", "quantity": 3}' \
 http://$SHOPPING_CART_HOST/shoppingcart/123
curl http://$SHOPPING_CART_HOST/shoppingcart/123
```

Finally, let's checkout the shopping cart

```
$ curl http://$SHOPPING_CART_HOST/shoppingcart/123/checkout -X POST
```

At this point, the shopping cart service should publish a message to Kafka. Let's deploy the inventory service to consume that message. We won't go into the details of how to configure it and its deployment descriptor since it's just a subset of what's needed for the shopping cart service - it doesn't need to form a cluster, it doesn't have a database, it just has a single node and needs to connect to Kafka. First, if you haven't already, build and push the inventory service to the docker registry:

sbt
:    ```
sbt inventory-impl/docker:publishLocal
```

Maven
:    ```
mvn package docker:build
```

If you're not using Minishift, you'll now need to push the docker image as described for @ref[sbt](building-using-sbt.md#pushing-the-docker-image) and @ref[Maven](building-using-maven.md#pushing-the-docker-image).

Now, we can create the application secret, apply the deployment spec, and expose the service:

```
oc create secret generic inventory-application-secret --from-literal=secret="$(openssl rand -base64 48)"
oc apply -f deploy/inventory.yaml
oc expose svc/inventory
```

Now find out the hostname that the inventory service is exposed on and set it in an environment variable:

```
$ oc get routes/inventory
inventory   inventory-myproject.192.168.42.246.nip.io  inventory  http   None
$ INVENTORY_HOST=inventory-myproject.192.168.42.246.nip.io
```

And use that to query the inventory of one of the products that we just checked out from the shopping cart:

```
curl http://$INVENTORY_HOST/inventory/456
```

Since we checked out two of product `456`, and we haven't added anything to its inventory, if the inventory service has successfully consumed the checkout message, we expect the current inventory to be -2.