# Deploying using sbt

sbt uses a plugin called [sbt-native-packager](https://www.scala-sbt.org/sbt-native-packager/) to allow conveniently packaging Java and Scala applications built using sbt as Docker images.

## Setup

To use this plugin in your sbt application, add the following to your `project/plugins.sbt` file:

@@@vars
```scala
addSbtPlugin("com.typesafe.sbt" % "sbt-native-packager" % "$sbt.native.packager.version$")
```
@@@

Now you can enable the appropriate plugins in your build, by modifying your project in `build.sbt`:

```scala
enablePlugins(JavaAppPackaging, DockerPlugin)
```

Here we're telling native packager to package our application as a Java application that can be run from the command line. This will package up all the applications dependencies (jar files), and generate a start script to start the application. To generate this start script, native packager needs to know what the applications main class is. When the application only has one main class in its source folder, sbt will detect this automatically, but in case there are multiple, or the main class comes from a dependency, it can be set in `build.sbt` like so:

```scala
mainClass in Compile := Some("com.lightbend.example.Main")
```

<!--- #no-setup --->
### Selecting a JDK

By default, sbt native packager uses the `openjdk` latest Docker image from DockerHub. At time of writing, this will give you OpenJDK 11, which is not certified by Lightbend, and it also gives you the Debian OpenJDK build, which is not certified by Lightbend. For a full list of Lightbend certified JDK builds and versions, see [here](https://developer.lightbend.com/docs/reactive-platform/2.0/supported-java-versions/index.html).

We'll configure our project to use AdoptOpenJDK 8. This can be done by setting:

```scala
dockerBaseImage := "adoptopenjdk/openjdk8"
```

You may want to explicitly set the version, to ensure your build always produces the same artifact. To do so, select a tag from [here](https://hub.docker.com/r/adoptopenjdk/openjdk8), and add it to the base image:

@@@vars
```scala
dockerBaseImage := "adoptopenjdk/openjdk8:$adoptopenjdk.docker.image.version$"
```
@@@

## Deploying

Now that we're setup, we can deploy our application.

@@@ note { title=Remember }
Before doing this, ensure you have your `DOCKER_HOST` environment variable and authentication setup, as described in @ref:[Installing OpenShift](../index.md#installing-openshift). In Minishift, this means running:

```
eval $(minishift docker-env)
```
@@@
 
Start `sbt`, and then in the sbt shell, run:

@@@vars
```
$sbt.prompt$ docker:publishLocal
```
@@@

This will publish all projects for which you have sbt native packager enabled to the OpenShift docker repository. The first time you run this it may take some time as it downloads the docker base image to the OpenShift docker repository, but subsequent runs will be fast.

If you have multiple projects, then you may wish to deploy just one of those projects, this can be done like so:

@@@vars
```
$sbt.prompt$ $sbt.sub.project$/docker:publishLocal
```
@@@

<!--- #no-setup --->