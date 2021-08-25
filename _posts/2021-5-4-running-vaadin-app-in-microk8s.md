---
layout: post
title: Running Vaadin-on-Kotlin app in microk8s
---

[microk8s](https://microk8s.io/) is an excellent way to have a Kubernetes server
up-and-running in no time on your Ubuntu machine. In this article
we're going to have the [vaadin-kotlin-pwa](https://github.com/mvysny/vaadin-kotlin-pwa)
app running in Kubernetes with a PostgreSQL database. That will require the following
steps:

1. Create a docker image of the vaadin-kotlin-pwa app; we'll use Jetty to run the WAR
2. Deploy that docker image into microk8s docker repository.
3. Define a Kubernetes pod consisting of the vaadin-kotlin-pwa app and the PostgreSQL database.
4. Upload and run the pod.

## Install microk8s and docker

First, follow the steps outlined on the [microk8s home page](https://microk8s.io/)
to have microk8s up-and-running quickly. Make sure to enable the dashboard and dns:
the dashboard will give you a nice UI way to view the app logs, while
the DNS management facilitates communication between services:

```bash
$ microk8s enable dashboard dns
```

Verify that the microk8s is running on your machine:

```bash
$ microk8s dashboard-proxy
```

Navigate to [https://127.0.0.1:10443](https://127.0.0.1:10443), to see the microk8s dashboard.
From here, you can for example inspect pods and their logs, which will reveal any errors.

Also, it's a good idea to have your user join the `microk8s` group, so that you don't have
to use sudo when typing microk8s commands. You can find the guide on the [Getting Started](https://microk8s.io/docs)
guide. I had to reboot my machine in order for my user to have the `microk8s` group; you can verify
that by running the `groups` command.

## Create a docker image of vaadin-kotlin-pwa

Follow the [vaadin-kotlin-pwa Docker guide](https://github.com/mvysny/vaadin-kotlin-pwa#docker).
After the `test/vaadin-kotlin-pwa` docker image is built on your local system, we're
ready to proceed to the next step.

## Import the `test/vaadin-kotlin-pwa` image to microk8s

Since microk8s/Kubernetes is supposed to run on multiple machines, it wouldn't
make sense to access local docker repository since it may differ machine by machine.
Therefore, microk8s uses its own image repository, and that's where we need to
import the image produced in the step above.

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
docker.io/test/vaadin-kotlin-pwa:latest   application/vnd.docker.distribution.manifest.v2+json  sha256:b4f81c1e1ced941931b2cc1d3ffed26c2581cff11782475a4b9c9cbcdaaa794d 335.8 MiB linux/amd64  io.cri-containerd.image=managed
```

## Define Kubernetes deployments and services

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
# The database pod configuration
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
# To obtain the IP address, you need to run
# `microk8s kubectl get all`; then browse http://IP:8080
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
# The vok-pwa webapp pod
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

> Note: if the configuration file above doesn't make any sense, please make sure
> to read the [Deploy your first scaleable PHP/MySQL Web application in Kubernetes](https://faun.pub/deploy-your-first-scaleable-php-mysql-web-application-in-kubernetes-33ed7ab66595)
> article which is an excellent introduction to Kubernetes.

Run this command in order to create and activate the services and pods above:
```bash
$ microk8s kubectl apply -f vok-pwa.yml
```

You can verify that the pods and services have been created, via:
```bash
$ microk8s kubectl get all
NAME                           READY   STATUS    RESTARTS   AGE
pod/pgsql-768d7b4756-t2wp5     1/1     Running   1          145m
pod/vok-pwa-66cc5d8645-kjzw6   1/1     Running   1          145m

NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/kubernetes        ClusterIP   10.152.183.1     <none>        443/TCP          28h
service/vok-pwa-service   NodePort    10.152.183.242   <none>        8080:30540/TCP   153m
service/pgsql-service     NodePort    10.152.183.83    <none>        5432:32363/TCP   145m

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/pgsql     1/1     1            1           145m
deployment.apps/vok-pwa   1/1     1            1           172m
```

You can also navigate to the [microk8s dashboard](https://127.0.0.1:10443),
to *Pods* / *vok-pwa-*. You can select the three-dot overflow menu and *Logs*,
to view the pod logs (Jetty/vok-pwa stdout). If you see something like

```
2021-05-04 16:55:51.360:INFO:oejs.AbstractConnector:main: Started ServerConnector@5981f4a6{HTTP/1.1, (http/1.1)}{0.0.0.0:8080}
2021-05-04 16:55:51.361:INFO:oejs.Server:main: Started @9195ms
```

then the vok-pwa app has started correctly and is correctly connected to the PostgreSQL database.

To browse the app, you need to figure out the vok-pwa-service IP address. You can do so
by running
```bash
$ microk8s kubectl get all
```

or by navigating to *Services* / *vok-pwa-service* in the Dashboard. After you
figure out the IP address (shown under "CLUSTER IP"), you can simply point your browser towards
`http://IP:8080` and you should see the vok-pwa app up and running.

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

## LoadBalancer

Instead of using `NodePort` for `vok-pwa-service` you could try to use the `LoadBalancer` and
try to run multiple instances of the vok-pwa pod. However, you would quickly find that
the session gets invalid all the time. That's because the load balancer chooses the pods randomly,
but only one pod has the servlet session. You either need to enable session replication between pods,
or sticky sessions.

According to
[Does Vaadin 14 support session replication](../vaadin-14-session-replication/)
Vaadin 14 doesn't work well with session replication and thus the only option is to enable
sticky session.

Apparently the `LoadBalancer` service type can not handle sticky
sessions, hence you need to use the `ingress-nginx` service type. According to
[ingress-nginx deploy: microk8s](https://kubernetes.github.io/ingress-nginx/deploy/#microk8s)
microk8s already uses ingress-nginx, so you only need to configure it properly:
[ingress-nginx docs on sticky sessions](https://kubernetes.github.io/ingress-nginx/examples/affinity/cookie/).

Just let me know if you manage to do so, and I'll post the config file here along with
your copyright.

## More Resources

* [microk8s official documentation](https://microk8s.io/docs)
* [Kubernetes official documentation](https://kubernetes.io/docs/home/)

microk8s is an implementation of the Kubernetes standard, therefore visit both
sites to learn as much as possible. Kubernetes has quite steep learning curve -
make sure to allocate lots of time and energy for your learning endeavour ;)
