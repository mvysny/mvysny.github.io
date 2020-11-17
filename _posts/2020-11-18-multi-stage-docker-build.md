---
layout: post
title: Multi-Stage Docker builds
---

In the past I have written an article regarding [Launching your Vaadin apps in Docker](../Launch-your-Vaadin-on-Kotlin-app-quickly-in-cloud/)
and [Running WAR apps in Docker with Jib](../running-war-apps-in-docker-jib).
However, what if you don't have Java installed at all on the machine (e.g. it's a CI server)
and therefore can't run Gradle build? Or what if you don't want to have an unfamiliar
Gradle script running on your machine (e.g. could be a virus)?
The solution is to perform the build itself in Docker as well, by using
[Docker multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/).

## Building WAR images

The following example Docker file will git-clone and build the
[karibu10-helloworld-app](https://github.com/mvysny/karibu10-helloworld-application) example project:

```dockerfile
# Build stage
FROM openjdk:11 AS BUILD
RUN git clone https://github.com/mvysny/karibu10-helloworld-application /app
WORKDIR app
RUN ./gradlew -Pvaadin.productionMode --info --no-daemon

# Run stage
FROM tomcat:9.0.35-jdk11-openjdk
COPY --from=BUILD /app/build/libs/app.war /usr/local/tomcat/webapps/ROOT.war
```

Just create an empty directory and place a single file named `Dockerfile` (the contents above) there, then run:

```bash
$ docker build -t test/karibu10:latest --no-cache .
$ docker run --rm -ti -p8080:8080 test/karibu10:latest
```

The first command will go through individual stages and build the `test/karibu10` image containing Tomcat and the karibu10-helloworld-app WAR file;
the second command will start the pre-built image.

## Building jar images

The advantage of using jar-based apps are that the image is much smaller (since it doesn't package Tomcat)
and it starts much faster (since it embeds Jetty which starts faster than Tomcat).

The following example Docker file will git-clone and build the
[vaadin14-embedded-jetty-gradle](https://github.com/mvysny/vaadin14-embedded-jetty-gradle) example project:

```dockerfile
# Build stage
FROM openjdk:11 AS BUILD
RUN git clone https://github.com/mvysny/vaadin14-embedded-jetty-gradle /app
WORKDIR app
RUN ./gradlew -Pvaadin.productionMode --info --no-daemon
WORKDIR /app/build/distributions
RUN unzip app.zip

# Run stage
FROM openjdk:11
COPY --from=BUILD /app/build/distributions/app /app/
WORKDIR /app/bin
EXPOSE 8080
ENTRYPOINT ./app
```

Just create an empty directory and place a single file named `Dockerfile` (the contents above) there, then run:

```bash
$ docker build -t test/vaadin14-embedded-jetty:latest --no-cache .
$ docker run --rm -ti -p8080:8080 test/vaadin14-embedded-jetty
```
