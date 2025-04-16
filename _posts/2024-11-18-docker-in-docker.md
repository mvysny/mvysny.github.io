---
layout: post
title: Docker-in-Docker
---

Say you're hosting a bunch of apps as Docker containers, possibly [via Traefik](../2-vaadin-apps-1-traefik/)
and you want to control those containers from some kind of Admin interface, which too is
running in a Docker environment (so that the Traefik routing to the admin interface is easily implemented).

The way to do this is to expose `/var/run/docker.sock` to the container itself. Of course this
is an inherent security issue since it allows the container to control host; use only
for containers that you absolutely trust.

## Plain Docker

Just run
```bash
$ docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock ubuntu /bin/bash
```
Unfortunately, the Ubuntu image won't have docker-cli installed. There are ways to
[install the docker-cli only](https://stackoverflow.com/questions/38675925/is-it-possible-to-install-only-the-docker-cli-and-not-the-daemon),
or [via docker java client library](https://www.baeldung.com/docker-java-api). But, when running Ubuntu-on-Ubuntu, the
easiest way is to mount the docker binary itself into the container:
```bash
$ docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker ubuntu /bin/bash
# docker ps
CONTAINER ID   IMAGE       COMMAND              CREATED          STATUS          PORTS                                   NAMES
2c2e38401d58   ubuntu      "/bin/bash"          45 seconds ago   Up 44 seconds                                           cranky_maxwell
# docker run -d --name my-apache-app -p 8080:80 httpd:2.4
# docker ps
CONTAINER ID   IMAGE       COMMAND              CREATED          STATUS          PORTS                                   NAMES
562cfc3bb562   httpd:2.4   "httpd-foreground"   3 seconds ago    Up 3 seconds    0.0.0.0:8080->80/tcp, :::8080->80/tcp   my-apache-app
2c2e38401d58   ubuntu      "/bin/bash"          45 seconds ago   Up 44 seconds                                           cranky_maxwell
```
Even though the httpd container was started from an Ubuntu Docker container, httpd container is actually running on the host machine:
* We're controlling the docker daemon running on the host machine; we're just controlling it from a docker container.
* Similar to when you ssh to a remote machine and run `docker`.
* it's not even possible to start a container within a container since the Docker daemon only runs on the host machine.

You can verify the httpd is running on the host machine, by exiting the Ubuntu container (which is immediately killed and removed because of `--rm`),
and listing running docker containers from the host machine:
```bash
# exit
exit
$ docker ps
CONTAINER ID   IMAGE       COMMAND              CREATED              STATUS              PORTS                                   NAMES
562cfc3bb562   httpd:2.4   "httpd-foreground"   About a minute ago   Up About a minute   0.0.0.0:8080->80/tcp, :::8080->80/tcp   my-apache-app
```
Go to [localhost:8080](http://localhost:8080), to see the httpd still running.

## Docker-Compose

Unfortunately the trick with mounting the docker-compose binary to your container
won't work anymore since docker-compose is a python script and requires other files to be present as well.

However, that is just a minor inconvenience since docker-compose is just a front for docker, so you
should be able to achieve the same thing with just the `docker` binary.

## docker-buildx

It's even possible to build images via `docker build` from within docker container, including
the buildx extension:
```bash
$ docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v /usr/libexec/docker/cli-plugins/docker-buildx:/usr/libexec/docker/cli-plugins/docker-buildx ubuntu /bin/bash
```
You can for example build [vaadin-boot-example-gradle](https://github.com/mvysny/vaadin-boot-example-gradle/):
```bash
$ sudo apt update && sudo apt install -y git
$ git clone https://github.com/mvysny/vaadin-boot-example-gradle/
$ cd vaadin-boot-example-gradle
$ docker build --cache-from "type=local,src=/root/build-cache" --cache-to "type=local,dest=/root/build-cache" -t test/vaadin-boot-example-gradle:latest .
```
The build will be performed outside of the docker container: docker client will
zip & send the folder to the docker daemon to perform the build. The `--cache-from`
and `--cache-to` will however refer path from within the docker container;
if you wish to have a persistent cache you can simply mount the path as a volume.
