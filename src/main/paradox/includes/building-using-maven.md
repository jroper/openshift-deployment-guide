# Building using Maven

There are a number of Maven plugins available for building and deploying Docker images. We're going to use [Fabric8](https://maven.fabric8.io/).

## Build wide plugin configuration

We recommend adding and configuring the Docker plugin in your builds parent POM, this saves it having to be configured in every modules POM file. Add the following to the build plugins configuration in the parent POM for your project:

```xml
<plugin>
    <groupId>io.fabric8</groupId>
    <artifactId>docker-maven-plugin</artifactId>
    <version>0.26.1</version>
    <configuration>
        <skip>true</skip>
        <images>
            <image>
                <name>%a:%l</name>
                <build>
                    <from>adoptopenjdk/openjdk8</from>
                    <tags>
                        <tag>latest</tag>
                        <tag>${project.version}</tag>
                    </tags>
                    <assembly>
                        <descriptorRef>artifact-with-dependencies</descriptorRef>
                    </assembly>
                </build>
            </image>
        </images>
    </configuration>
</plugin>
```

There are two things to pay careful attention to here. Firstly, the base image we're using is `adoptopenjdk/openjdk8`. You can use any Docker image that provides a JDK, this is the one we recommend for open source users of OpenShift. You may wish to explicitly select a version, rather than just relying on the latest build, in which case you may change it to:

@@@vars
```xml
<from>adoptopenjdk/openjdk8:$adoptopenjdk.docker.image.version$</from>
```
@@@

The second thing to notice is that we've set `skip` to `true`. This means that, by default, for child modules in this build, no Docker image will be built. This is convenient because it means that Maven modules that are just libraries don't have to have any Fabric8 configuration in them, when you do a docker build of your whole project they will just be skipped.

## Per module configuration

Now that we've configured the plugin build wide, we can modify our individual services that we need a Docker image built for to enable building a docker image:

@@@vars
```xml
<plugin>
    <groupId>io.fabric8</groupId>
    <artifactId>docker-maven-plugin</artifactId>
    <configuration>
        <skip>false</skip>
        <images>
            <image>
                <build>
                    <entryPoint>
                       java $JAVA_OPTS -cp '/maven/*' $main.class$
                    </entryPoint> 
                </build>
            </image>
        </images>
    </configuration>
</plugin>
```
@@@

As you can see, now we're overriding the `skip` configuration from the parent POM. We've also configured the startup command to run our application.

## Building the docker image

Now that we're setup, we can build our docker image.

@@@ note { title=Remember }
If you are using Minishift, ensure you have setup your docker environment as described in @ref:[Installing Minishift](../index.md#installing-minishiftshift). This means running:

```
eval $(minishift docker-env)
```
@@@

We need to first package the application jars (and its dependencies), and then we can build the image:

```
mvn package docker:build
```

@@include[docker-push.md](docker-push.md)
