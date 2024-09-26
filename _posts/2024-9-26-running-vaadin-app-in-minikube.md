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

We'll need to define a pod and a service and an ingress rule for the app.
The app will configure ingress to forward all traffic coming from the `myapp.fake` DNS
domain. The easiest way to create the domain is to edit your `/etc/hosts` and add the rule:
```
192.168.49.2 myapp.fake
```
Note the `192.168.49.2` IP address: run `minikube docker-env` and minikube will
tell you on which IP address it listens. Use that IP address.

Create a file named `my-vaadin-boot-example-maven.yml` with the following contents:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-vaadin-boot-example-maven
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment
  namespace: my-vaadin-boot-example-maven
spec:
  selector:
    matchLabels:
      app: pod
  template:
    metadata:
      labels:
        app: pod
    spec:
      containers:
        - name: main
          image: test/vaadin-boot-example-maven:latest
          imagePullPolicy: Never
          ports:
            - containerPort: 8080
          resources:
            limits:
              memory: "256Mi"  # https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
              cpu: 1
---
apiVersion: v1
kind: Service
metadata:
  name: service
  namespace: my-vaadin-boot-example-maven
spec:
  selector:
    app: pod
  ports:
    - port: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-custom-dns
  namespace: my-vaadin-boot-example-maven
spec:
  rules:
    - host: "myapp.fake"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service
                port:
                  number: 8080
```

> Note: if the configuration file above doesn't make any sense, please make sure
> to read the [Deploy your first scaleable PHP/MySQL Web application in Kubernetes](https://faun.pub/deploy-your-first-scaleable-php-mysql-web-application-in-kubernetes-33ed7ab66595)
> article which is an excellent introduction to Kubernetes.

Run this command in order to create and activate the services and pods above:
```bash
$ kubectl apply -f my-vaadin-boot-example-maven.yml
```

You can go to MiniKube dashboard, to see a Pod is started, a Service is created,
and an Ingress rule is created. You need to select the `my-vaadin-boot-example-maven`
namespace first though.

To see the logs, go to Pods, then "View Logs" upper-right icon button.
