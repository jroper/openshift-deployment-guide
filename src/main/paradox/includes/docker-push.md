## Pushing the docker image

<!--- #intro --->
If you are using Minishift with the Minishift docker environment set up, then you will have just built the image directly in the OpenShift docker registry, and no further steps are needed. Otherwise, you will need to now push the image to the OpenShift repository.

@@@ note { title=Remember }
Before doing this, ensure that your OpenShift instance has exposed its docker registry, and that you have logged in to the remote docker registry, as described in @ref:[Setting up docker](../index.md#setting-up-docker).
@@@

To push to the docker registry, you need to configure the repository URL, as well as the repository username, which should match your project name.
<!--- #intro --->

<!--- #image-stream --->
When you push a docker image to OpenShift's internal registry, it will automatically create an image stream that the image can be consumed from.

Since we're using Kubernetes deployments rather than OpenShift deployment configs, in order to ensure that our deployment can consume this from the internal OpenShift registry with an unqualified tag, we need to allow local lookups on it. This can be enabled by running the following command.

@@@vars
```
oc set image-lookup $docker.image$
```
@@@

For more information on image stream lookups, see the [OpenShift documentation](https://docs.openshift.com/container-platform/latest/dev_guide/managing_images.html#using-is-with-k8s).
<!--- #image-stream --->
