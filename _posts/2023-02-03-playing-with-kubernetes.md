---
layout: post
title: Playing with Kubernetes - microk8s
---

[microk8s](https://microk8s.io/) is an excellent way to have a Kubernetes server
up-and-running in no time on your Ubuntu machine. In this article we'll deploy
a container with nginx serving a simple static page, and we'll configure ingress
to perform reverse proxy for us.

This series document my Kubernetes journey, from the very beginning to having 2
vaadin apps deployed in Kubernetes.
Also lists the most commonly used commands.

You'll need:

* A computer running newest Ubuntu (or `snap`)
* At least a basic knowledge of docker

## Setup

* Excellent quick & hands-on [Getting started](https://microk8s.io/docs/getting-started)
* Guides for other OSes: [Install microk8s](https://microk8s.io/#install-microk8s)

In short:

```bash
sudo snap install microk8s --classic
microk8s enable dashboard    # gives access to admin web interface
microk8s enable dns          # not sure why
microk8s enable registry     # kubernetes docker registry
microk8s enable ingress      # reverse proxy
microk8s status
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
```

> Note: the `~/.kube` folder gets created after reboot I think.

* Add `alias mkctl="microk8s kubectl"` to `~/.config/fish/config.fish`
* Reboot

## Basic commands

* `microk8s stop`
* `microk8s start`
* `microk8s status`
* `mkctl get all --all-namespaces`
* `mkctl get nodes`, `mkctl get services`, `mkctl get pods`
* `microk8s dashboard-proxy` - most important, gives you access to microk8s admin web interface.

You can define new services, pods etc via the dashboard. However, it's much better to do so
via yaml files since that way the services/pods can be easily defined and redefined from a command-line,
via `mkctl apply -f`.

When you're done experimenting, stop microk8s via `microk8s stop`. Microk8s will no longer start automatically
on next boot until you run `microk8s start`. This is to conserve your dev machine battery.

## About Kubernetes

For excellent intro into Kubernetes please see [YouTube Series: Nana on What Is Kubernetes](https://www.youtube.com/playlist?list=PLy7NrYWoggjziYQIDorlXjTvvwweTYoNC).
She really has a knack of explaining everything properly, quickly, simply, no bullshit. I warmly recommend.

Pod hosts one or more Docker containers. Overwhelmingly often it's just one container: the app itself. So, for our purposes, pod equals container.

Pods are wrapped in Deployments. Deployment defines the pod itself (the `spec.template` is a pod definition) and how
many replicas of the pod there will be running. Usually it's just 1.

Pods/Deployments expose themselves to other pods or load balancers via services.
You need services since pods are "ephemeral": may be killed at any time and may change their IP addresses,
while the services are persistent.

Service types:
* ClusterIP: the default one, simply exposes pods to other Kubernetes things, but not outside of Kubernetes. Most often used.
* NodePort: a service which exposes pod port on the node. Only used for dev, should not be used for production.
* LoadBalancer: requires an external load balancer to be set up; load-balances requests to individual pods.
  For a simple self-hosted setup it's better to use ingress.

We'll use the ClusterIP service, and we'll expose it via additional service called Ingress.
Ingress is a reverse proxy which runs in Kubernetes and exposes
a http/https port of a service. Ingress performs URL path mapping,
and also https->http unwrapping - there's also an integration with Let's Encrypt.

### YAML configuration resource file

Names: microk8s says that the name must be a DNS-1035 label; it must consist of lower case alphanumeric characters or '-', start with an alphabetic character, and end with an alphanumeric character.
Kubernetes docs is more permissive but whatever: [Name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/)

Labels: microk8s says that: a valid label must be an empty string or consist of alphanumeric characters, '-', '_' or '.', and must start and end with an alphanumeric character.
Kubernetes doc says something different but whatever: [Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/).

Deployment: [matchLabels is probably necessary](https://medium.com/@zwhitchcox/matchlabels-labels-and-selectors-explained-in-detail-for-beginners-d421bdd05362).

## Deploy an app

We'll create the resources gradually. This is not the recommended practice (better way is
to have all resources listed in a YAML file), but this will do for the tutorial.

* `mkctl create deployment nginx --image=nginx`
* `mkctl get pods`
* In the dashboard, navigate to workloads/pods/nginx/, then there's IP address in Resource information, e.g. 10.1.46.87
* Open the browser and go to http://10.1.46.87:80, you should see a nginx welcome page.

To publish the pod on host, we'll use Ingress. First, we need to expose the pod as a service:

`nginx-service.yaml`:
```yaml
kind: Service
apiVersion: v1
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - port: 80
```

You can verify that you can access the nginx demo app via http://10.152.183.81 now as well
(depending on the IP assigned to the `nginx-service` service).

* `microk8s enable ingress`

Then, create a file named `ingress-nginx.yaml` with this content:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: http-ingress-nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - http:
      paths:
      - path: /experiment/nginx(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
```

This also demoes the [ingress reverse proxy path rewriting](https://kubernetes.github.io/ingress-nginx/examples/rewrite/).

All-in-one config file:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo-nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment
  namespace: demo-nginx
spec:
  selector:
    matchLabels:
      app: pod  # this must match spec.template.metadata.labels for some reason
  template:
    metadata:
      labels:
        app: pod
    spec:
      containers:
        - name: nginx
          image: nginx:1.14.2
          ports:
            - containerPort: 80
          resources:
            limits:
              memory: "128Mi"
              cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: service
  namespace: demo-nginx
spec:
  selector:
    app: pod
  ports:
    - port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress
  namespace: demo-nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - http:
        paths:
          - path: /experiment/nginx(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: service
                port:
                  number: 80
```

To deploy:

```bash
$ mkctl apply -f nginx-demo.yaml
```

Now visit [http://127.0.0.1/experiment/nginx](http://127.0.0.1/experiment/nginx) to check that everything works.

To delete all objects defined in a YAML file and stop all containers:
```bash
$ mkctl delete -f nginx-demo.yaml
```

Don't forget to delete the demo deployment `nginx` we created earlier.

## Security

microk8s by default open some ports on all interfaces: [services and ports](https://microk8s.io/docs/services-and-ports).
They all require a certificate auth and are protected by https.

It's probably better to enable ufw: [ufw tutorial](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands)

Then you need to enable some ufw rules in order for microk8s to work: [microk8s ufw](https://discourse.ubuntu.com/t/install-a-local-kubernetes-with-microk8s/13981)

```bash
sudo ufw allow ssh
sudo ufw allow in on cni0 && sudo ufw allow out on cni0
sudo ufw default allow routed
sudo ufw enable
sudo ufw status
```

## Namespaces

If you have multiple projects running in Kubernetes, it's better to place every app into their own separate namespace,
in order to avoid name clashes between resources.

Namespace must be a valid [DNS Name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names),
which means that the project ID must:

* contain at most 63 characters
* contain only lowercase alphanumeric characters or '-'
* start with an alphanumeric character
* end with an alphanumeric character

Useful commands:

* `mkctl get namespace`
* `mkctl get all --namespace my-project`

Alternatively you can omit namespaces from the YAML file and use `mkctl apply -f foo.yaml --namespace=my-namespace`.
You can forget to type in the `--namespace` part though, thus having namespaces in yaml directly is a better idea.
