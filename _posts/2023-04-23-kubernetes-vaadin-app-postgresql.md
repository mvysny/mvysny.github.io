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

When everything is up-and-running, you should be able to browse to [localhost](http://localhost)
and see the app up-and-running.

You can view the database files according to the [hostpath-storage](https://microk8s.io/docs/addon-hostpath-storage) docs;

```bash
$ mkctl get pvc -n jdbi-orm-vaadin-crud-demo
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
postgres-pvc   Bound    pvc-8c8879fd-c0f4-4b94-8677-b5885babe5a1   512Mi      RWO            microk8s-hostpath   18m
$ mkctl describe pv pvc-8c8879fd-c0f4-4b94-8677-b5885babe5a1
...
    Path:          /var/snap/microk8s/common/default-storage/jdbi-orm-vaadin-crud-demo-postgres-pvc-pvc-8c8879fd-c0f4-4b94-8677-b5885babe5a1
...
$ sudo ls -la /var/snap/microk8s/common/default-storage/jdbi-orm-vaadin-crud-demo-postgres-pvc-pvc-8c8879fd-c0f4-4b94-8677-b5885babe5a1
```

## When something fails

If the app fails to start because Postgres was unavailable for too long, you can
see that in the app logs. Either run the Kubernetes Dashboard via
`microk8s dashboard-proxy` then point your browser according to the instructions printed
in the console. Make sure to select the `jdbi-orm-vaadin-crud-demo` namespace, browse
to the Pods, `deployment` and view its logs.

Alternatively, do the same thing with the command-line:
```bash
$ mkctl get pods --namespace jdbi-orm-vaadin-crud-demo
NAME                                     READY   STATUS    RESTARTS   AGE
deployment-6bc9b6b675-9x7m4              1/1     Running   0          7m27s
postgresql-deployment-6cb8657544-bxgtz   1/1     Running   0          10m
$ mkctl logs deployment-6bc9b6b675-9x7m4 -n jdbi-orm-vaadin-crud-demo
2023-04-24 05:53:00.689 [main] INFO com.github.mvysny.vaadinboot.VaadinBoot - Starting App
...
```

If you see the database-related exceptions, the easiest way is to restart the deployment:

```bash
mkctl rollout restart deployment deployment -n jdbi-orm-vaadin-crud-demo
```
