package jdocs.lagom;

//#start
import akka.actor.ActorSystem;
import akka.management.AkkaManagement;
import akka.management.cluster.bootstrap.ClusterBootstrap;

import javax.inject.Inject;

public class ClusterBootstrapStart {

    @Inject
    public ClusterBootstrapStart(ActorSystem actorSystem) {
        AkkaManagement.get(actorSystem).start();
        ClusterBootstrap.get(actorSystem).start();
    }
}
//#start
