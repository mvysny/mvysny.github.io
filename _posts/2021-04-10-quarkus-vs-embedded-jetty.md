---
layout: post
title: Quarkus VS Embedded Jetty VS Spring Boot
---

In today's highly unscientific test, I'm going to compare two projects:

* [Vaadin Quarkus Skeleton Starter](https://github.com/mvysny/vaadin-quarkus-skeleton-starter)
  running Vaadin 14.5.1 and Quarkus 1.10.5
* [Vaadin Embedded Jetty](https://github.com/mvysny/vaadin14-embedded-jetty-gradle) running
  Vaadin 14.5.2 and Jetty 9.4.36.v20210114.
* [Vaadin Skeleton Starter Spring Boot](https://github.com/vaadin/skeleton-starter-flow-spring)
  running Vaadin 14.5.2, Spring Boot and Tomcat.

Both projects are compiled with Vaadin production mode enabled:

* The Quarkus project is compiled via `mvn -C clean package -Pproduction`, then launched
  via `java -jar vaadin-quarkus-skeleton-starter-1.0.0-SNAPSHOT-runner.jar`
* The Embedded Jetty project is compiled via `./gradlew -Pvaadin.productionMode`,
  then launched via the `build/distributions/vaadin14-embedded-jetty-gradle/bin/vaadin14-embedded-jetty-gradle`
  script.
* The Spring Boot Skeleton Starter is compiled via `mvn -C clean package -Pproduction`,
  then launched via `java -jar spring-skeleton-1.0-SNAPSHOT.jar`.

In both cases, openjdk 11.0.10 x86-64 on Ubuntu 20.10 is used.

## Startup time

I've performed three startups, and the startup times are as follows:

* The Quarkus project boots in 1345ms, 1319ms and 1454ms
* The Embedded Jetty project boots in 1394ms, 1452ms, 1380ms
* Spring Boot Skeleton Starter boots in 3194ms, 2991ms and 3004ms

## Memory Usage

With the default JVM memory settings, after startup and serving of one page:

* The Quarkus project used 367M of RAM
* The Embedded Jetty project used 485M of RAM
* Spring Boot uses a whopping 783M of RAM

Using `-Xmx32M` (32 megs of heap space), after startup and serving of one page:

* The Quarkus project used 189M of RAM and started in 1272ms
* The Embedded Jetty project used 151M of RAM but was noticeable slower to start - 2462ms
* Spring Boot starts in 3307ms but fails to serve a page and throws `OutOfMemoryError: Java heap space`
   * With `-Xmx64M` the app starts in 3800ms and uses 317M of RAM.

## Update

Tried running the [vaadin-boot-example-gradle](https://github.com/mvysny/vaadin-boot-example-gradle)
on 32bit openjdk-20: it's Jetty 12 + Vaadin 24.1.7 project; the project starts quickly and uses 97 MB of RAM.
