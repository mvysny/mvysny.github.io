---
layout: post
title: 2 Vaadin Apps 1 Kubernetes
---

This builds on [2 Vaadin Apps 1 Nginx](../2-vaadin-apps-1-nginx/) but wraps everything
in Kubernetes (namely, [microk8s](https://microk8s.io/)).

See [Playing with Kubernetes](../playing-with-kubernetes/) for tips on how to install
Microk8s and for the list of basic commands.

We'll deploy 2 Vaadin apps to Kubernetes: [vaadin-boot-example-gradle](https://github.com/mvysny/vaadin-boot-example-gradle)
and [beverage-buddy-vok](https://github.com/mvysny/beverage-buddy-vok).

## Creating images and importing into microk8s docker registry

Create docker images of two Vaadin apps and import them into the microk8s kubelet docker registry:

```bash
cd vaadin-boot-example-gradle
docker build --no-cache -t test/vaadin-boot-example-gradle .
docker save test/vaadin-boot-example-gradle > image.tar
microk8s ctr image import image.tar
rm image.tar
cd beverage-buddy-vok
docker build --no-cache -t test/beverage-buddy-vok .
docker save test/beverage-buddy-vok > image.tar
microk8s ctr image import image.tar
rm image.tar
```

Check that the images have been imported to the registry:
```bash
microk8s ctr image ls|grep test
```

Saving images via `docker save` creates huge file since it saves all layers and parent images
into one huge 700MB file (the reason is that `openjdk:11` itself is huge, 654MB as can be seen via `docker images openjdk:11`).
There are [ways to shrink the saved image size](https://stackoverflow.com/questions/39142698/docker-save-only-non-public-layers),
but they look complicated.

Another way is to push the images straight to the kubernetes registry, by using remote tags.
Docker tag may optionally start with a host and a port, e.g. `localhost:32000/test/beverage-buddy-vok`,
as documented at the [Built-in Registry Documentation](https://microk8s.io/docs/registry-built-in).
This way, the common layers (`openjdk:11`) are reused between both Vaadin projects.

Delete the old images via
```bash
microk8s ctr images rm docker.io/test/beverage-buddy-vok
microk8s ctr images rm docker.io/test/vaadin-boot-example-gradle
```

Then, build the new ones via:

```bash
cd vaadin-boot-example-gradle
docker build --no-cache -t localhost:32000/test/vaadin-boot-example-gradle .
docker push localhost:32000/test/vaadin-boot-example-gradle
cd beverage-buddy-vok
docker build --no-cache -t localhost:32000/test/beverage-buddy-vok .
docker push localhost:32000/test/beverage-buddy-vok
```

This pushes the image not to the kubelet registry, but to the Microk8s internal registry instead,
from which all kubelets can pull the images.

`microk8s ctr image ls|grep test` doesn't reveal the new images yet - they're only shown when
the containers have been run and kubelet has downloaded the images from the Microk8s internal registry.
Afterwards, the images show 345mb only, probably because they share the `openjdk:11` common image.

### Running Apps

Then apply the following config file:

```bash
$ mkctl apply -f vaadin-demo.yaml
```

```yaml
#
# Vaadin Boot Example Gradle
#

apiVersion: v1
kind: Namespace
metadata:
  name: my-vaadin-boot-example-gradle
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment
  namespace: my-vaadin-boot-example-gradle
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
        image: localhost:32000/test/vaadin-boot-example-gradle
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
  namespace: my-vaadin-boot-example-gradle
spec:
  selector:
    app: pod
  ports:
    - port: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-main
  namespace: my-vaadin-boot-example-gradle
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$3
    nginx.ingress.kubernetes.io/proxy-cookie-path: / /$1
spec:
  rules:
    - host: "myserver.fake"
      http:
        paths:
          - path: /(app1)(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: service
                port:
                  number: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-custom-dns
  namespace: my-vaadin-boot-example-gradle
spec:
  rules:
    - host: "vaadin1.fake"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service
                port:
                  number: 8080
---

#
# Beverage Buddy
#

apiVersion: v1
kind: Namespace
metadata:
  name: my-beverage-buddy-vok
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment
  namespace: my-beverage-buddy-vok
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
          image: localhost:32000/test/beverage-buddy-vok
          ports:
            - containerPort: 8080
          resources:
            limits:
              memory: "256Mi"
              cpu: 1
---
apiVersion: v1
kind: Service
metadata:
  name: service
  namespace: my-beverage-buddy-vok
spec:
  selector:
    app: pod
  ports:
    - port: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-main
  namespace: my-beverage-buddy-vok
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$3
    nginx.ingress.kubernetes.io/proxy-cookie-path: / /$1
spec:
  rules:
    - host: "myserver.fake"
      http:
        paths:
          - path: /(app2)(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: service
                port:
                  number: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-custom-dns
  namespace: my-beverage-buddy-vok
spec:
  rules:
    - host: "vaadin2.fake"
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

To "create" those fake DNS names, simply append the following line at the end of your `/etc/hosts` file:
```
127.0.0.1 myserver.fake vaadin1.fake vaadin2.fake
```

The [vaadin1.fake](http://vaadin1.fake/) and [vaadin2.fake](http://vaadin2.fake/) links will work:
apparently Ingress takes care of cookie host name rewriting (the `proxy_cookie_domain`). Unfortunately, it does not take care
of path rewriting, and therefore playing with [myserver.fake/app1](http://myserver.fake/app1/)
and [myserver.fake/app2](http://myserver.fake/app2/) will cause both apps to overwrite each other cookies.

That's why we need to employ `nginx.ingress.kubernetes.io/proxy-cookie-path` to rewrite cookie path.
Read more on that here:

* [Proxy Cookie Path on Kubernetes Ingress](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#proxy-cookie-path)
* [Nginx proxy_cookie_path](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_cookie_path)
* [All Kubernetes Ingress Configuration Annotations](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md)

The `http://myserver.fake/app2/` will work, but `http://myserver.fake/app2` won't. See [Issue #2](https://github.com/mvysny/shepherd/issues/2)
for more details and a solution.

### Rolling out an update

There's [Kubernetes Images](https://kubernetes.io/docs/concepts/containers/images/)
documentation which documents working with images. There are two ways to upgrade your app.

The recommended way is to push another image with a different version (tag) to
the Microk8s registry, then update your pod definition in YAML to reference the new images.
Upon apply, Microk8s will restart containers automatically. The downside is that
you'll have to manually delete the images later on, via `microk8s ctr images rm`.

If you know you'll always roll forward, then you can use the alternative way of
using the `latest` tag (or no tag at all). Every image build thus simply overwrites
the previous one. That sets the `imagePullPolicy` property
to `Always`. That causes Kubernetes to always pull in the newest image before
starting pod. To force pod restart after image update, call `kubectl rollout restart deployment <deployment_name>`.

(TODO check whether that works)

The best way could be a combination: using image sha256 digest value.
You build the latest image, then figure out its sha256 checksum, then you update YAML
configuration resource file to reference the new image:

```
image: gcr.io/google-containers/echoserver@sha256:cb5c1bddd1b5665e1867a7fa1b5fa843a47ee433bbb75d4293888b71def53229
```

Since the YAML has been changed, Kubernetes will restart the pods to use the newest image.

To get the image sha256 (this only works after the image has been built *and* pushed to the kubernetes repo via `docker push`):

```bash
$ docker inspect --format='{{index .RepoDigests 0}}' localhost:32000/test/vaadin-boot-example-gradle:latest
localhost:32000/test/vaadin-boot-example-gradle@sha256:62d6de89ced35ed07571fb9190227b08a7a10c80c97eccfa69b1aa5829f44b9a
```
