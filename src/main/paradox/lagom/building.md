# Building your application

With the application prepared to run in OpenShift, and the Kubernetes specs written for its deployment, we are now ready to build and deploy it.

@@include[building.md](../includes/building.md) { #intro }

## Running the build

How you build the docker image and deploy it to the registry will depend on what build tool you are using.

@@toc { depth=1 }

@@@index

* [Deploying using sbt](building-using-sbt.md)
* [Deploying using Maven](building-using-maven.md)

@@@