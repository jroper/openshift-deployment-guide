package jdocs.lagom;

import com.google.inject.AbstractModule;
import com.lightbend.lagom.javadsl.api.Descriptor;
import com.lightbend.lagom.javadsl.api.Service;
import com.lightbend.lagom.javadsl.server.ServiceGuiceSupport;

public interface FormingACluster {

    interface start {

        public class ShoppingCartModule extends AbstractModule implements ServiceGuiceSupport {
            //#start
            @Override
            protected void configure() {
                bindService(ShoppingCartService.class, ShoppingCartServiceImpl.class);
                bind(ClusterBootstrapStart.class).asEagerSingleton();
            }
            //#start
        }

        interface ShoppingCartService extends Service {
            @Override
            default Descriptor descriptor() {
                return Service.named("shopping-cart");
            }
        }

        class ShoppingCartServiceImpl implements ShoppingCartService {}

    }
}
