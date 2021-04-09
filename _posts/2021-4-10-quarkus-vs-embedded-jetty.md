---
layout: post
title: Quarkus VS Embedded Jetty
---

In today's highly unscientific test, I'm going to compare two projects:
[Vaadin Quarkus Skeleton Starter](https://github.com/mvysny/vaadin-quarkus-skeleton-starter)
and [Vaadin Embedded Jetty](https://github.com/mvysny/vaadin14-embedded-jetty-gradle).

Both projects are compiled with Vaadin production mode:

* The Quarkus project is compiled via `mvn -C clean package -Pproduction`, then launched
  via `java -jar vaadin-quarkus-skeleton-starter-1.0.0-SNAPSHOT-runner.jar`
* The Embedded Jetty project is compiled via `./gradlew -Pvaadin.productionMode`,
  then launched via the `build/distributions/vaadin14-embedded-jetty-gradle/bin/vaadin14-embedded-jetty-gradle`
  script.

In both cases, openjdk 11.0.10 x86-64 on Ubuntu 20.10 is used.

## Startup time

I've performed three startups, and the startup time is very similar:

* The Quarkus project boots in 1345ms, 1319ms and 1454ms
* The Embedded Jetty project boots in 1394ms, 1452ms, 1380ms

## Memory Usage

With the default JVM memory settings, after startup and serving of one page:

* The Quarkus project used 367M of RAM
* The Embedded Jetty project used 485M of RAM

Using `-Xmx32M` (32 megs of heap space), after startup and serving of one page:

* The Quarkus project used 189M of RAM and started in 1272ms
* The Embedded Jetty project used 151M of RAM but was noticeable slower to start - 2462ms
