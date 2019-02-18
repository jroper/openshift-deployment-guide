---
service.name = shopping-cart
---
# Deploying

With the docker image built and pushed to the OpenShift registry, we can now deploy the deployment config that we've built.

Run the following command:

```sh
oc apply -f deploy/shopping-cart.yaml
```

Immediately after running this, you should see the three shopping cart pods when you run `oc get pods`:

```
shopping-cart-756894d68d-9sltd             0/1       Running   0          9s
shopping-cart-756894d68d-bccdv             0/1       Running   0          9s
shopping-cart-756894d68d-d8h5j             0/1       Running   0          9s
```

## Understanding bootstrap logs

Let's take a look at their logs as they go through the cluster bootstrap process. By default, the logging in the application during startup is reasonably noisy. You may wish to set the logging to a higher threshold (eg warn) if you wish to make the logs quieter, but for now it can help us to understand what is going down. Below is a selection of log messages, with much of the extraneous information (such as timestamps, threads, logger names) removed. Also, you will say a lot of info messages when features that depend on clustering start up, but a cluster has not yet been formed. These messages can be ignored.

@@@vars
```
1  [info] Remoting started; listening on addresses :[akka.tcp://application@172.17.0.12:2552]
   [info] Cluster Node [akka.tcp://application@172.17.0.12:2552] - Started up successfully
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
7  [info] Contact point [akka.tcp://application@172.17.0.13:2552] returned [0] seed-nodes []
8  [info] Bootstrap request from 172.17.0.12:47312: Contact Point returning 0 seed-nodes ([TreeSet()])
9  [info] Exceeded stable margins without locating seed-nodes, however this node 172.17.0.12:8558
     is NOT the lowest address out of the discovered endpoints in this deployment, thus NOT joining
     self. Expecting node [ResolvedTarget(172-17-0-11.myproject.pod.cluster.local,Some(8558),Some(/172.17.0.11))]
     to perform the self-join and initiate the cluster.
10 [info] Contact point [akka.tcp://application@172.17.0.11:2552] returned [1] seed-nodes
     [akka.tcp://application@172.17.0.11:2552]
11 [info] Joining [akka.tcp://application@172.17.0.12:2552] to existing cluster
     [akka.tcp://application@172.17.0.11:2552]
12 [info] Cluster Node [akka.tcp://application@172.17.0.12:2552] - Welcome from [akka.tcp://application@172.17.0.11:2552]
```
@@@

An explanation of these messages is as follows.

1. These are init messages, showing that remoting has started on port 2552. The IP address should be the pods IP address from which other pods can access it, while the port number should match the configured remoting number, defaulting to 2552.
2. Init messages for Akka management, once again, the IP address should be the pods IP address, while the port number should be the port number you've configured for Akka management to use, defaulting to 8558.
3. Now the cluster bootstrap process is starting. The service name should match your configured service name in cluster bootstrap, and the port should match your configured port name.
4. This log message comes from the Kubernetes API implementation of Akka discovery, the label selector should be one that will return your pods, and the namespace should match your applications namespace.
5. Here the Kubernetes API has returned three services, including ourselves.
6. This log message shows what cluster bootstrap has decided to do with the three services. It has found three, but so far it has not confirmed whether any of them have joined a cluster yet, hence, it will continue retrying looking them up, and attempting to contact them, until it has found that a cluster has been, or can be started.
7. This message will appear many times, it's the result of probing one of the contact points to find out if it has formed a cluster.
8. This message will also appear many times, it's the result of this node being probed by another node to find out if it has formed a cluster.
9. This message may or may not appear, depending on how fast your nodes are able to start given the amount of resources. It's simply informing you that the node hasn't located a seed node yet, but it's not going to try and form a cluster since it not the node with the lowest IP address.
10. Eventually, this message will change to report that one of the nodes has formed a cluster.
11. The node has decided to join an existing cluster.
12. The node has joined the cluster.

Following these messages, you may still some messages warning that messages can't be routed, it still may take some time for cluster singletons and other cluster features to decide which node to start up on, but before long, the logs should go quiet as the cluster is started up.

One thing to notice in the logs above, this node was not the node that first started the cluster - 