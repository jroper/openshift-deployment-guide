package sdocs.lagom

import com.lightbend.lagom.scaladsl.api.{Descriptor, Service}
import com.lightbend.lagom.scaladsl.devmode.LagomDevModeComponents
import com.lightbend.lagom.scaladsl.server.{LagomApplication, LagomApplicationContext, LagomApplicationLoader, LagomServer}
import play.api.libs.ws.ahc.AhcWSComponents

object StartClusterBootstrap {

  class ShoppingCartLoader extends LagomApplicationLoader {

    //#start
    import akka.management.scaladsl.AkkaManagement
    import akka.management.cluster.bootstrap.ClusterBootstrap
    import com.lightbend.lagom.scaladsl.akka.discovery.AkkaDiscoveryComponents

    override def load(context: LagomApplicationContext): LagomApplication =
      new ShoppingCartApplication(context) with AkkaDiscoveryComponents {
        AkkaManagement(actorSystem).start()
        ClusterBootstrap(actorSystem).start()
      }
    //#start

    override def loadDevMode(context: LagomApplicationContext): LagomApplication =
      new ShoppingCartApplication(context) with LagomDevModeComponents

    override def describeService = Some(readDescriptor[ShoppingCartService])
  }

  abstract class ShoppingCartApplication(context: LagomApplicationContext)
    extends LagomApplication(context) with AhcWSComponents {
    override lazy val lagomServer: LagomServer = serverFor[ShoppingCartService](new ShoppingCartService {})
  }

  trait ShoppingCartService extends Service {
    override def descriptor: Descriptor = Service.named("shopping-cart")
  }

}
