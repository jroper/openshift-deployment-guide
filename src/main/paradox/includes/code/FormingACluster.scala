package sdocs.includes

import akka.actor.ActorSystem

object StartClusterBootStrap {

  val actorSystem = ActorSystem()

  // #start
  import akka.management.AkkaManagement
  import akka.management.cluster.bootstrap.ClusterBootstrap

  AkkaManagement(actorSystem).start()
  ClusterBootstrap(actorSystem).start()
  // #start


}