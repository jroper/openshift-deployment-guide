## Pushing the docker image

If you are using Minishift with the Minishift docker environment set up, then you will have just built the image directly in the OpenShift docker registry, and no further steps are needed. Otherwise, you will need to now push the image to the OpenShift repository.

@@@ note { title=Remember }
Before doing this, ensure that your OpenShift instance has exposed its Docker registry, and that you have logged in to the remote Docker registry, as described in @ref:[Setting up docker](../index.md#setting-up-docker)
@@@

OpenShift will only allow you to push images to projects that you have permission on. Before you push, you first need to tag your image such that it matches the OpenShift Docker repository and project path. Assuming your docker repository is `docker-registry-default.myopenshift.example.com`, and that your project is `myproject`, you can tag your image like so:

@@@vars
```
docker tag $docker.image.tag$ docker-registry-default.myopenshift.example.com/myproject/$docker.image.tag$
```
@@@

Now you can push the newly tagged image to the OpenShift registry:

@@@vars
```
docker push docker-registry-default.myopenshift.example.com/myproject/$docker.image.tag$
```
@@@

When you push a docker image to OpenShifts internal registry, it will automatically create an image stream that the image can be consumed from.

Since we're using Kubernetes deployments rather than OpenShift deployment configs, in order to ensure that our deployment can consume this from the internal OpenShift registry with an unqualified tag, we need to allow local lookups on it. This can be enabled by running the following command.

@@@vars
```
oc set image-lookup $docker.image$
```
@@@

For more information on image stream lookups, see the [OpenShift documentation](https://docs.openshift.com/container-platform/latest/dev_guide/managing_images.html#using-is-with-k8s).
