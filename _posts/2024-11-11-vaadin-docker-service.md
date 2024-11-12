---
layout: post
title: Running Vaadin apps in background as a Docker service
---

Docker daemon has the ability to [automatically start containers on boot-up](https://docs.docker.com/engine/containers/start-containers-automatically/)
and even restart them automatically when they die.
That is exactly what we need - if we use this feature then we don't need
systemd to keep our containers up.

To test this, we'll experiment on the [karibu-helloworld-app](https://github.com/mvysny/karibu-helloworld-application)
which already provides a well-documented `Dockerfile`. To build the docker image:

```bash
$ git clone https://github.com/mvysny/karibu-helloworld-application
$ cd karibu-helloworld-application
$ docker build --no-cache -t test/karibu-helloworld-application:latest .
```
Create a file named `docker-compose.yaml` anywhere on disk:
```yaml
services:
  web:
    image: test/karibu-helloworld-application:latest
    ports:
      - "8080:8080"
    restart: always
```
Now start the app:
```bash
$ docker-compose up -d
```
Test that the app is running, by opening [http://localhost:8080](http://localhost:8080).

## Testing the resilience of the docker daemon

The docker daemon should now run the container automatically when the computer reboots.
Test this out by rebooting the machine and checking that the container is running after bootup:

```bash
$ docker ps
CONTAINER ID   IMAGE                                       COMMAND              CREATED         STATUS         PORTS                                       NAMES
28f55d447858   test/karibu-helloworld-application:latest   "/bin/sh -c ./app"   2 minutes ago   Up 9 seconds   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   karibu-helloworld-application_web_1
```

Again test that the app is running, by opening [http://localhost:8080](http://localhost:8080).

## Updating the app

Let's test an app update. Modify the `MainView.kt` file and add another button
`button("Say hello"){}`, then rebuild the app:
```bash
$ docker build --no-cache -t test/karibu-helloworld-application:latest .
```
When you open [http://localhost:8080](http://localhost:8080), you'll notice the
old version of the app - that's because we need to restart the container.
Running `docker-compose restart` isn't enough - the container will stick to the
old image. You need to stop the container and remove it, then start it again:

```bash
$ docker-compose down
$ docker-compose up -d
```

## Getting logs

Run `docker-compose logs` to print the logs of the running containers.
