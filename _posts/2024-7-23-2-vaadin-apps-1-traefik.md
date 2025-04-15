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
$ docker-compose up -d -f vaadin-boot-example-gradle.docker-compose.yml
$ docker-compose up -d -f beverage-buddy-vok.docker-compose.yml
```

Traefik will automatically discover those docker containers and will setup proper routing - you can check out
Traefik's Dashboard (the HTTP tab, the HTTP routers sub-tab) to see that.

Verify that you can access those apps: [app1.myserver.fake](http://app1.myserver.fake) and [app2.myserver.fake](http://app2.myserver.fake).

## https via Let's Encrypt

To enable https with Let's Encrypt, you obviously have to set up Traefik on an actual
server running somewhere in the internet; then you have to register a bunch of domains
and make them point to the IP address where the server is running.

See [Traefik: Let's Encrypt documentation](https://doc.traefik.io/traefik/https/acme/).

Also see [DigitalOcean documentation on Traefik](https://www.digitalocean.com/community/tutorials/how-to-use-traefik-v2-as-a-reverse-proxy-for-docker-containers-on-ubuntu-20-04).

You do not have to have any account at Let's Encrypt: the only requirement is to own the DNS domain and
to have it pointing to the server's IP.

### DNS Wildcard mode

It's possible to set up your DNS record to handle wildcard requests, e.g. having your Traefik handle
`http://*.yourdomain.com`. For this to work, you need two things:

1. Enable wildcard support with your DNS provider.  E.g. with GoDaddy, click on the domain, then "Manage Domain",
   the "DNS" tab, then "Add New Record": Type: A, Name: `*` (an asterisk), Data: the IP address of your server. Hit save -
   the change will eventually propagate through all DNS servers and you'll be able to `ping foo.yourdomain.com`.
2. Configure Traefik's Let's Encrypt integration for a proper wildcard support

https with DNS wildcard is tricky: Let's Encrypt only supports the [DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/)
type when verifying wildcard DNS. In short, the ACME client needs to briefly add a specific TXT record to your DNS entry.
In order to do that, the ACME client needs to go to where your DNS is registered, and temporarily modify the DNS record.
In other words, with Traefik:

1. You need to use [dnsChallenge](https://doc.traefik.io/traefik/https/acme/#dnschallenge)
2. You need to let Traefik know which provider you use, and configure proper access.

Here's an example of [GoDaddy integration](https://stackoverflow.com/questions/61234489/cannot-get-wildcard-certificate-with-traefik-v2-and-godaddy).

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
