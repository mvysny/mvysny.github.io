---
layout: post
title: Running Vaadin-on-Kotlin app in microk8s
---

[microk8s](https://microk8s.io/) is an excellent way to have a Kubernetes server
up-and-running in no time on your Ubuntu machine. In this article
we're going to have the [vaadin-kotlin-pwa](https://github.com/mvysny/vaadin-kotlin-pwa)
app running in Kubernetes with a PostgreSQL database. That will require the following
steps:

1. Create a docker image of the vaadin-kotlin-pwa running in Jetty
2. Deploy that docker image into microk8s docker repository
3. Define a Kubernetes pod consisting of the vaadin-kotlin-pwa app and the PostgreSQL database.
4. Upload and run the pod.

## Install microk8s and docker

First, follow the steps outlined on the [microk8s home page](https://microk8s.io/)
to have microk8s up-and-running quickly. Verify that the microk8s is running on your
machine, by running `microk8s dashboard-proxy` and navigating to [https://127.0.0.1:10443](https://127.0.0.1:10443).

## Create a docker image of vaadin-kotlin-pwa

Follow the [vaadin-kotlin-pwa Docker guide](https://github.com/mvysny/vaadin-kotlin-pwa#docker).
After the `test/vaadin-kotlin-pwa` docker image is built on your local system, we're
ready to proceed to the next step.

## Import the `test/vaadin-kotlin-pwa` image to microk8s

Microk8s pods can only run docker images located in the local microk8s docker repository.

In order to register the `test/vaadin-kotlin-pwa` image to microk8s, we need
to export it first:

```bash
$ docker save test/vaadin-kotlin-pwa > vok-pwa.tar
$ microk8s ctr image import vok-pwa.tar
```

Now you can confirm that the image has indeed been imported to your microk8s docker
repository:

```bash
$ microk8s ctr images ls|grep test/vaadin-kotlin-pwa
docker.io/test/vaadin-kotlin-pwa:latest                                                                             application/vnd.docker.distribution.manifest.v2+json      sha256:b4f81c1e1ced941931b2cc1d3ffed26c2581cff11782475a4b9c9cbcdaaa794d 335.8 MiB linux/amd64                                                 io.cri-containerd.image=managed
```

## Define the vok-pwa Kubernetes pod

TODO
