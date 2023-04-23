---
layout: post
title: Vaadin app with persistent PostgreSQL in Kubernetes
---

We'll build on the [2 Vaadin Apps 1 Kubernetes](../2-vaadin-apps-1-kubernetes/) article;
this time we'll add a persistent database PostgreSQL to the mix.
We'll deploy the [jdbi-orm-vaadin-crud-demo](https://github.com/mvysny/jdbi-orm-vaadin-crud-demo)
app which has the capability of running with either in-memory H2, or a remote PostgreSQL
database. We'll learn how services talk to each other by the help of the DNS plugin,
and how to make PostgreSQL database files persistent using the [hostpath-storage](https://microk8s.io/docs/addon-hostpath-storage)
plugin.

> Note: this article borrows heavily from the excellent
[Kubernetes series by Mark Gituma](https://markgituma.medium.com/kubernetes-local-to-production-with-django-3-postgres-with-migrations-on-minikube-31f2baa8926e).

TODO
