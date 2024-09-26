---
layout: post
title: Running Vaadin-on-Kotlin app in MiniKube Kubernetes
---

[minikube](https://minikube.sigs.k8s.io/docs/start) is an excellent way to have a Kubernetes server
up-and-running in no time on your Ubuntu machine. In this article
we're going to have the [vaadin-boot-example-maven](https://github.com/mvysny/vaadin-boot-example-maven)
app running in Kubernetes. That will require the following
steps:

1. Create a docker image of the `vaadin-boot-example-maven`
2. Deploy that docker image into MiniKube docker repository.
3. Define a Kubernetes app consisting of the vaadin-boot-example-maven app and an ingress rule
4. Upload and run the app.

## Install minikube and docker

First, follow the steps outlined on the [MiniKube docs page](https://minikube.sigs.k8s.io/docs/start),
to have MiniKube up-and-running quickly. I'm running Ubuntu 24.04 arm64, so I downloaded the
appropriate deb package and installed it as suggested in the minikube start page.

Start the MiniKube dashboard, to see that minikube is running: `minikube dashboard`.

We'll need to install the following addons to minikube:

* `ingress`, to correctly reroute http traffic to the app pods
* `registry` to be able to have locally built docker images accessible from within the minikube.

That can be done easily:
```bash
$ minikube addons enable ingress registry
```

## Create a docker image of vaadin-boot-example-maven

This one is easy, just git clone the project and create the docker image locally:

```bash
git clone https://github.com/mvysny/vaadin-boot-example-maven
cd vaadin-boot-example-maven
docker build --no-cache -t test/vaadin-boot-example-maven:latest .
```

See the project `Dockerfile` for more details.

Verify that the app is running correctly in Docker:

```bash
docker run --rm -ti -p8080:8080 test/vaadin-boot-example-maven
```
The app should start and should listen on [localhost:8080](http://localhost:8080).

Stop the app - we'll run it from minikube next.

## Import the `test/vaadin-boot-example-maven` image to minikube

Build the image again, but this time using minikube local docker
([as described here](https://stackoverflow.com/a/48999680/377320)):

```bash
eval $(minikube docker-env)
docker build --no-cache -t test/vaadin-boot-example-maven:latest .
minikube image ls|grep vaadin-boot
```

The last command will print `docker.io/test/vaadin-boot-example-maven:latest`
if the image was built correctly.

## Define Kubernetes deployments and services

TODO

We need to define a pod and a service, both for the vok-pwa webapp and for the PostgreSQL
database.

Create a file named `vok-pwa.yml` with the following contents:

```yaml
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
