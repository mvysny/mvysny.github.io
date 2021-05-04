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

## Deploy the `test/vaadin-kotlin-pwa` image to microk8s

Microk8s pods can only run docker images located in the local microk8s docker repository.
