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
machine:

```bash
$ microk8s dashboard-proxy
```

Navigate to [https://127.0.0.1:10443](https://127.0.0.1:10443), to see the microk8s dashboard.
From here, you can for example inspect pods and their logs, which will reveal any errors.

## Create a docker image of vaadin-kotlin-pwa

Follow the [vaadin-kotlin-pwa Docker guide](https://github.com/mvysny/vaadin-kotlin-pwa#docker).
After the `test/vaadin-kotlin-pwa` docker image is built on your local system, we're
ready to proceed to the next step.

## Import the `test/vaadin-kotlin-pwa` image to microk8s

Microk8s pods can only run docker images located in the local microk8s docker registry.

In order to register the `test/vaadin-kotlin-pwa` image to microk8s, we need
to export it first, then import into the microk8s internal docker registry:

```bash
$ docker save test/vaadin-kotlin-pwa > vok-pwa.tar
$ microk8s ctr image import vok-pwa.tar
```

Now you can confirm that the image has indeed been imported to your microk8s docker
registry:

```bash
$ microk8s ctr images ls|grep test/vaadin-kotlin-pwa
docker.io/test/vaadin-kotlin-pwa:latest   application/vnd.docker.distribution.manifest.v2+json      sha256:b4f81c1e1ced941931b2cc1d3ffed26c2581cff11782475a4b9c9cbcdaaa794d 335.8 MiB linux/amd64                                                 io.cri-containerd.image=managed
```

## Define the vok-pwa Kubernetes pod

We need to define a pod and a service, both for the vok-pwa webapp and for the PostgreSQL
database.

Create a file named `vok-pwa.yml` with the following contents:

```yaml
# First, the database service
# This will expose the database pod as a service under given name.
# That will cause microk8s to create a DNS record for it,
# which in turn will allow the vok-pwa pod to access the database via
# the 'pgsql-service' host name.
apiVersion: v1
kind: Service
metadata:
  name: pgsql-service
  labels:
    app: pgsql
spec:
  type: NodePort
  ports:
  - port: 5432
    protocol: TCP
  selector:
    app: pgsql
---
# The database pod follows
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgsql
spec:
  selector:
    matchLabels:
      app: pgsql
  template:
    metadata:
      labels:
        app: pgsql
    spec:
      containers:
      - name: pgsql
        image: postgres:10.3
        env:
        - name: POSTGRES_PASSWORD
          value: mysecretpassword
        ports:
        - containerPort: 5432
        livenessProbe:
          tcpSocket:
            port: 5432
---
# This configuration exposes the vok-pwa pod as a service.
# To obtain the IP address, you need to run `microk8s kubectl get all`; then just navigate to http://IP:8080
apiVersion: v1
kind: Service
metadata:
  name: vok-pwa-service
  labels:
    app: vok-pwa
spec:
  type: NodePort
  ports:
  - port: 8080
    protocol: TCP
  selector:
    app: vok-pwa
---
# Now the vok-pwa webapp pod itself.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vok-pwa
spec:
  selector:
    matchLabels:
      app: vok-pwa
  template:
    metadata:
      labels:
        app: vok-pwa
    spec:
      containers:
      - name: webapp
        image: test/vaadin-kotlin-pwa:latest
        imagePullPolicy: Never
        env:
        - name: VOK_PWA_JDBC_DRIVER
          value: org.postgresql.Driver
        - name: VOK_PWA_JDBC_URL
          value: jdbc:postgresql://pgsql-service:5432/postgres
        - name: VOK_PWA_JDBC_USERNAME
          value: postgres
        - name: VOK_PWA_JDBC_PASSWORD
          value: mysecretpassword
        ports:
        - containerPort: 8080
        livenessProbe:
          tcpSocket:
            port: 8080
```

Run this command in order to create and activate the services and pods above:
```bash
$ microk8s kubectl apply -f vok-pwa.yaml
```

You can verify that the pods and services have been created, via:
```bash
$ microk8s kubectl get all
```

You can also navigate to the [microk8s dashboard](https://127.0.0.1:10443),
to *Pods* / *vok-pwa-*. You can select the three-dot overflow menu and *Logs*,
to view the pod logs. If you see something like

```
2021-05-04 16:55:51.360:INFO:oejs.AbstractConnector:main: Started ServerConnector@5981f4a6{HTTP/1.1, (http/1.1)}{0.0.0.0:8080}
2021-05-04 16:55:51.361:INFO:oejs.Server:main: Started @9195ms
```

Then the vok-pwa app has started correctly and is correctly connected to the PostgreSQL database.

To browse the app, you need to figure out the vok-pwa-service IP address. You can do so
by running
```bash
$ microk8s kubectl get all
```

or by navigating to *Services* / *vok-pwa-service* in the Dashboard. After you
figure out the IP address, you can simply point your browser towards
`http://IP:8080` and you should see the vok-pwa app.

## Troubleshooting

If the vok-pwa pod fails with `UnknownHostException`, then it means that the kube-dns
is not exposing the PostgreSQL service correctly.

First, run

```bash
$ microk8s kubectl get all --namespace kube-system
```

and make sure that both the `service/kube-dns` service and `deployment.apps/coredns` are running correctly.

Also, try to run
```bash
$ microk8s inspect
```

which should check whether microk8s is running correctly, and should suggest commands
fixing any issues found. For example, you may have to enable access to your `cni0` network interface
from ufw:

```bash
$ sudo ufw allow in on cni0
$ sudo ufw allow out on cni0
```
