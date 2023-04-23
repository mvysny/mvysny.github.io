---
layout: post
title: Vaadin app with persistent PostgreSQL in Kubernetes
---

We'll build on the [2 Vaadin Apps 1 Kubernetes](../2-vaadin-apps-1-kubernetes/) article;
this time we'll add a persistent database PostgreSQL to the mix.
We'll deploy the [jdbi-orm-vaadin-crud-demo](https://github.com/mvysny/jdbi-orm-vaadin-crud-demo)
app which has the capability of running with either in-memory H2, or a remote PostgreSQL
database. We'll learn how services talk to each other by the help of the [DNS plugin](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/),
and how to make PostgreSQL database files persistent using the [hostpath-storage](https://microk8s.io/docs/addon-hostpath-storage)
plugin.

> Note: this article borrows heavily from the excellent
[Kubernetes series by Mark Gituma](https://markgituma.medium.com/kubernetes-local-to-production-with-django-3-postgres-with-migrations-on-minikube-31f2baa8926e).

## DNS

We'll use the [microk8s DNS plugin](https://microk8s.io/docs/addon-dns):

```bash
$ microk8s enable dns
```

This will allow the app to connect to the `postgres` service (which we'll create in a minute)
via `jdbc:postgresql://postgres:5432/postgres`, as opposed to having type in an IP address of the service.

## Persistent Storage

Data in PostgreSQL needs to be persisted for long term storage. The default location for
storage in PostgreSQL is `/var/lib/postgresql/data`. However, Kubernetes pods are designed
to have ephemeral storage, which means once a pod dies all the data within the pod is lost.
To mitigate against this, Kubernetes has the concept of volumes.
You can learn the concepts from excellent [Kubernetes Volumes Explained](https://www.youtube.com/watch?v=0swOh5C3OVM)
by Nana.

We'll use the [microk8s hostpath-storage](https://microk8s.io/docs/addon-hostpath-storage) add-on
which creates the volumes on a local machine, but that's more than enough for our purposes.
It creates the persistent volume automatically for us; therefore we only need to create a
Persistent Volume Claims and microk8s will automatically connect them to the local volume.

To enable the plugin, run:

```bash
$ microk8s enable hostpath-storage
```

## Putting it all together

The entire setup is configured in one Kubernetes configuration file:
[kubernetes-app.yaml](https://github.com/mvysny/jdbi-orm-vaadin-crud-demo/blob/master/kubernetes-app.yaml)
Please see the contents of the file for further explanation.
