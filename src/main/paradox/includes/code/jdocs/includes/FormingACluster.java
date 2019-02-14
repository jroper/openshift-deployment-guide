package jdocs.includes;

import akka.actor.ActorSystem;
// #start
import akka.management.AkkaManagement;
import akka.management.cluster.bootstrap.ClusterBootstrap;
// #start

public interface FormingACluster {
    class StartClusterBootstrap {
        {
            ActorSystem actorSystem = ActorSystem.create();

            // #start

            AkkaManagement.get(actorSystem).start();
            ClusterBootstrap.get(actorSystem).start();
            // #start
        }
    }
}

