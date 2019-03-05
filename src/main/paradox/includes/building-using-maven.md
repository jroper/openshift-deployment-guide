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
                <name>${docker.username}/%a:%l</name>
                <build>
                    <from>adoptopenjdk/openjdk8</from>
                    <tags>
                        <tag>latest</tag>
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

There are three things to pay careful attention to here. Firstly, the base image we're using is `adoptopenjdk/openjdk8`. You can use any Docker image that provides a JDK, this is the one we recommend for open source users of OpenShift and is certified by Lightbend for running our products. If you're a RedHat customer, you will likely prefer to use the RedHat certified OpenJDK base images, which use a RedHat certified OpenJDK build on RHEL, which is also certified by Lightbend for running our products:

```xml
<from>registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift</from>
```

The second thing to notice is that we've set `skip` to `true`. This means that, by default, for child modules in this build, no Docker image will be built. This is convenient because it means that Maven modules that are just libraries don't have to have any Fabric8 configuration in them, when you do a docker build of your whole project they will just be skipped.

Finally, we're reading the docker username from a system property. This ensures that our build is not tied to any particular OpenShift environment or namespace. We'll need to be careful to ensure we set this system property when invoking Maven. In addition to this system property being externalised, Fabric8 also automatically reads a system property called `docker.registry` to know which docker registry to deploy to, which we will also set when we invoke Maven.

### Git hash based version numbers
    
This step is optional, but we recommend basing the version number of your application on the current git hash, since this ensures that you will always be able to map whats deployed to production back to the exact version of your application being used.

There are a number of Maven plugins available for interacting with git, we recommend the [Maven git commit id plugin](https://github.com/git-commit-id/maven-git-commit-id-plugin). This plugin will allow us to make certain git based properties available to the build, which we can then use to compute the version number.

To use it, add this plugin to the build section of your parent POM:

```xml
<plugin>
    <groupId>pl.project13.maven</groupId>
    <artifactId>git-commit-id-plugin</artifactId>
    <version>2.2.6</version>
    <executions>
        <execution>
            <phase>validate</phase>
            <goals>
                <goal>revision</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
        <dateFormat>yyyyMMdd-HHmmss</dateFormat>
        <dotGitDirectory>${project.basedir}/.git</dotGitDirectory>
        <generateGitPropertiesFile>false</generateGitPropertiesFile>
    </configuration>
</plugin>
```

Now, in the properties section of the parent POM, create a version number based on the commit time and id. Using the commit time is useful because it makes it possible to sort tags chronologically:

```xml
<properties>
   <version.number>${git.commit.time}.${git.commit.id.abbrev}</version.number>
</properties>
```

Finally, we now need to reconfigure the Fabric8 plugin to use this version number as a tag. You can either update the `name` property to use `%a:${version.number]` instead of `%a:%l`, or, add an additional tag, like so:

```xml
<tags>
    <tag>${version.number}</tag>
    <tag>latest</tag>
</tags>
```

@@@note
The version number will only change when you create a new git commit. If you are not using the `latest` tag in your deployment spec, then make sure when you update your project and want to redeploy, that you commit your changes first so you get a new version number, and to ensure that version number correlates to what is in the git repository at that commit hash.
@@@

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
    <executions>
        <execution>
            <id>build-docker-image</id>
            <phase>package</phase>
            <goals>
                <goal>build</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```
@@@

As you can see, now we're overriding the `skip` configuration from the parent POM. We've also configured the startup command to run our application. Finally, we've added the `docker:build` execution to our `package` phase, so that when we run `mvn package`, the docker image will be built.

## Building the docker image

Now that we're setup, we can build our docker image. Let's build and deploy the image for the `shopping-cart` project:

@@snip[building.sh](scripts/building.sh) { #maven }

This will package your project, build the docker images, tag them and push them to the OpenShift repository. The first time you run this it may take some time as it downloads the docker base image layers to your repository, but subsequent runs will be fast.

@@include[building](building.md) { #image-stream }
