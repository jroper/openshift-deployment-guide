## Shared docker docs

<!--- #intro --->
There are multiple ways to deploy docker images to OpenShift. You may decide to deploy your images to an external docker registry, such as one that your organisation has set up, or even to a public registry. OpenShift comes with its own built in docker registry that you can deploy to, for this guide we are going to use that.

Docker registries have a convention for tags that is typically used to enforce permissions, that is, a Docker tag should have the format of `<repository-url>/<username>/<image>:<version>`. The internal OpenShift registry maps the `username` part of the tag to a project or namespace. So, if you want to deploy an image to the `myproject` project, then you need to use that in place of the `<username>` in the tag.

For convenience, we'll refer to the `repository-url` using the environment variable `DOCKER_REPO_URL`, so if you set that in your shell like so:

```sh
DOCKER_REPO_URL=docker-registry-default.myopenshift.example.com
```

Then you will be able to copy and paste commands from this guide.

## A note on using Minishift

In addition to providing OpenShifts internal registry, Minishift makes it straight forward to build images directly into the Minishift VMs docker host. This is done by running `eval $(minishift docker-env)`, which sets up a number of environment variables so that the `docker` command will use that instead of the docker host on your host machine.

If you've built your image directly in the Minishift VMs docker host, then technically, you don't need to push to the OpenShift registry, since the images are already in the Minishift VMs docker host ready to be run. However, if your deployment spec has an `imagePullPolicy` of `Always`, as is the default when using the `latest` tag, then regardless of whether the image is there or not, Kubernetes will first attempt to pull the image, and this will fail if you haven't pushed it to any registry that it can see yet. For this reason, if using Minishift, we will still do the push step into the OpenShift built in registry, this has the advantage of being able to run the guide in a more realistic setup.

You still will need to setup the Minishift docker environment variables before you run this, since by default, the built in OpenShift docker registry is not exposed to your host machine, only the VM can see it.

The Minishift docker repository can be obtained by `minishift openshift registry`, so setup your Minishift environment, and initialize the `DOCKER_REPO_URL` environment variable to that:

@@snip[building.sh](scripts/building.sh) { #minishift-setup }

## Logging in

Before you can push to OpenShift's built in docker registry, you need to log into it. This can be done using your OpenShift login token, which you can discover at any time by running `oc whoami -t`. To log in, run:

@@snip[building.sh](scripts/building.sh) { #login }
<!--- #intro --->

<!--- #image-stream --->
### Configuring OpenShift image lookup

When you push a docker image to OpenShift's internal registry, it will automatically create an image stream that the image can be consumed from.

Since we're using Kubernetes deployments rather than OpenShift deployment configs, in order to ensure that our deployment can consume this from the internal OpenShift registry with an unqualified tag, we need to allow local lookups on it. This can be enabled by running the following command.

@@snip[building.sh](scripts/building.sh) { #image-lookup }

For more information on image stream lookups, see the [OpenShift documentation](https://docs.openshift.com/container-platform/latest/dev_guide/managing_images.html#using-is-with-k8s).
<!--- #image-stream --->
