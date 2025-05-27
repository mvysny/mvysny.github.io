---
layout: post
title: 2 Vaadin Apps 1 Traefik
---

The goal is to setup 2 Vaadin apps on one Ubuntu machine:

* 2 Vaadin apps are running in production mode in docker
* Configure [Traefik](https://traefik.io) as 'reverse proxy' so that the apps are accessible via `http://app1.myserver.fake` and `http://app2.myserver.fake`

> Note: you can alternatively configure the Vaadin apps to run on `/app1` context root, then you can also publish the app at, say, `http://myserver.fake/app1`.

> Note: you might be tempted to try to configure path rewriting, to have the apps serving `/` context root to be published at `http://myserver.fake/app1` and `http://myserver.fake/app2`, respectively.
> It's not a good idea:  see [StackOverflow answer](https://stackoverflow.com/a/78782475/377320) for details. In short,
> I don't think this is possible (e.g. https://community.traefik.io/t/traefik-2-reverse-proxy-to-a-path/8623/12 ), and also I don't think it's a good idea.
> Remember that you would need to rewrite all links in the response html files; possibly session cookie paths. Rewriting response html is most probably
> not a good idea since it might not be possible to do so reliably (see [Jenkins behind reverse proxy](https://mvysny.github.io/jenkins-behind-reverse-proxy/) for more details).

## Traefik Setup

I assume that docker is installed & configured on your machine. To run Traefik quickly, we'll just run it according to
[Traefik Quick Start](https://doc.traefik.io/traefik/getting-started/quick-start/). Create a `docker-compose.yml`:

```yaml
version: '3'

networks:
  web:
    external: true

services:
  traefik:
    # The official v3 Traefik docker image
    image: traefik:v3.3.5
    # Enables the web UI and tells Traefik to listen to docker
    command: --api.insecure=true --providers.docker
    networks:
      - web
    ports:
      # The HTTP port
      - "80:80"
      # The Web UI (enabled by --api.insecure=true)
      - "8080:8080"
    volumes:
      # So that Traefik can listen to the Docker events
      - /var/run/docker.sock:/var/run/docker.sock
```
Create a shared docker network named `web`, which will be used by Traefik to access your Vaadin apps:
```bash
$ docker network create web
```
To start Traefik:
```bash
$ docker-compose up -d
```
Now browse to [localhost](http://localhost:8080) and check that you can see the Traefik dashboard.

## Faking the DNS addresses

Edit `/etc/hosts` and add the following line to the end:
```bash
127.0.0.1 app1.myserver.fake app2.myserver.fake
```
Now when browsing to `http://app1.myserver.fake`, the browser will report the hostname as `app1.myserver.fake`,
exactly as if the DNS name was provided by an actual DNS server. We can take advantage of this,
to test as if on a real environment.

> Alternatively setup a [wildcard DNS rules](../ubuntu-local-wildcard-dns/).

## Setting up Vaadin apps

We'll run two Vaadin apps from docker: [vaadin-boot-example-gradle](https://github.com/mvysny/vaadin-boot-example-gradle)
and [beverage-buddy-vok](https://github.com/mvysny/beverage-buddy-vok). To build docker
images out of those apps, run the following in your terminal:

```bash
git clone https://github.com/mvysny/vaadin-boot-example-gradle
cd vaadin-boot-example-gradle
docker build --no-cache -t test/vaadin-boot-example-gradle:latest .
```
and
```bash
git clone https://github.com/mvysny/beverage-buddy-vok
cd beverage-buddy-vok
docker build --no-cache -t test/beverage-buddy-vok:latest .
```

Now, create a file named `vaadin-boot-example-gradle.docker-compose.yml`:
```yaml
version: '3'

networks:
  web:
    external: true
services:
  vaadin-boot-example-gradle:
    image: test/vaadin-boot-example-gradle:latest
    networks:
      - web
    labels:
      - "traefik.http.routers.vaadin-boot-example-gradle.entrypoints=http"
      - "traefik.http.routers.vaadin-boot-example-gradle.rule=Host(`app1.myserver.fake`)"
```

Now, create a file named `beverage-buddy-vok.docker-compose.yml`:
```yaml
version: '3'

networks:
  web:
    external: true
services:
  beverage-buddy-vok:
    image: test/beverage-buddy-vok:latest
    networks:
      - web
    labels:
      - "traefik.http.routers.beverage-buddy-vok.entrypoints=http"
      - "traefik.http.routers.beverage-buddy-vok.rule=Host(`app2.myserver.fake`)"
```

Run them:
```bash
$ docker-compose -f vaadin-boot-example-gradle.docker-compose.yml up -d
$ docker-compose -f beverage-buddy-vok.docker-compose.yml up -d
```

Traefik will automatically discover those docker containers and will setup proper routing - you can check out
Traefik's Dashboard (the HTTP tab, the HTTP routers sub-tab) to see that.

Verify that you can access those apps: [app1.myserver.fake](http://app1.myserver.fake) and [app2.myserver.fake](http://app2.myserver.fake).

## https

You can enable https in Traefik very easily. Traefik will generate and use self-signed certificates by default.
To enable https, modify Traefik `docker-compose.yaml` as follows:
```yaml
version: '3'

networks:
  web:
    external: true

services:
  traefik:
    # The official v3 Traefik docker image
    image: traefik:v3.3.5
    # Enables the web UI and tells Traefik to listen to docker
    command: --api.insecure=true --providers.docker --entrypoints.https.address=:443
    networks:
      - web
    ports:
      # The Web UI (enabled by --api.insecure=true)
      - "8080:8080"
      # The 'https' entrypoint
      - "443:443"
    volumes:
      # So that Traefik can listen to the Docker events
      - /var/run/docker.sock:/var/run/docker.sock
```
Modify the apps' `docker-compose.yml` as follows:
```
...
    labels:
      - "traefik.http.routers.vaadin-boot-example-gradle.entrypoints=https"
      - "traefik.http.routers.vaadin-boot-example-gradle.tls=true"
      - "traefik.http.routers.vaadin-boot-example-gradle.rule=Host(`app1.myserver.fake`)"
```

### https via Let's Encrypt

See [Setup wildcard DNS https certificates on Traefik with GoDaddy and Let's Encrypt](../traefik-https-le-godaddy-wildcard-dns/).

## Securing Things via Multiple Networks, plus running apps via pure docker

At the moment, all apps run on the same network `web`, which is potentially a security issue.
The easiest way is to create one network per app, isolating the apps from each other:
```bash
$ docker network create web1
$ docker network create web2
$ docker network connect web1 CONTAINER_ID_OF_TRAEFIK
$ docker network connect web2 CONTAINER_ID_OF_TRAEFIK
```
Obtain the Traefik container id by running `docker ps`.

Kill & remove the `vaadin-boot-example-gradle` and `beverage-buddy-vok` docker containers
via `docker kill` and `docker container rm`, so that we can start those two via pure docker:
```bash
$ docker run -d --network web1 --name vaadin-boot-example-gradle \
   --label "traefik.http.routers.vaadin-boot-example-gradle.entrypoints=http" \
   --label "traefik.http.routers.vaadin-boot-example-gradle.rule=Host(`app1.myserver.fake`)" \
   test/vaadin-boot-example-gradle:latest
$ docker run -d --network web2 --name beverage-buddy-vok \
   --label "traefik.http.routers.beverage-buddy-vok.entrypoints=http" \
   --label "traefik.http.routers.beverage-buddy-vok.rule=Host(`app2.myserver.fake`)" \
   test/beverage-buddy-vok:latest
```
Observe that Traefik automatically registered both apps exactly as before.

### Hitting the network limit

By default you can create 29 docker networks and then docker will fail with
`Error response from daemon: failed to parse pool request for address space "LocalDefault" pool "" subpool "": could not find an available predefined netw
ork`.

To be able to create more networks, edit `/etc/docker/daemon.json` and add:
```json
{
   "default-address-pools": [
        {
            "base":"172.17.0.0/12",
            "size":16
        },
        {
            "base":"192.168.0.0/16",
            "size":20
        },
        {
            "base":"10.99.0.0/16",
            "size":24
        }
    ]
}
```
then `sudo service docker restart`. Taken from [Stack Overflow](https://stackoverflow.com/questions/41609998/how-to-increase-maximum-docker-network-on-one-server).
