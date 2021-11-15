---
layout: post
title: Building Vaadin 14+ apps offline
---

This could be tricky: not only you need a Maven repository proxy/cache
which will allow Maven to access and download Vaadin jars (and transitive dependency jars),
you also need a (p)npm proxy/cache which will allow (p)npm to access and download JavaScript
client-side stuff used by Vaadin.

Tips for Maven repository proxy/caches:

* [Tiny Maven Proxy](https://github.com/timboudreau/tiny-maven-proxy) looks simple and extremely useful
* [Nginx](https://weblog.lkiesow.de/20170413-nginx-as-fast-maven-repository-proxy.html) could also work
* Sonatype Nexus used to be good but now it looks enterprisey
* JFrog Artifactory - perhaps you'll manage to download and run it locally

Tips for (p)npm proxies/caches:

* [Verdaccio](https://verdaccio.org/)
* Using Nexus as npm proxy cache is possible too
  * Perhaps the [docker-nexus-npm-registry](https://github.com/SebastianKuehnau/docker-nexus-npm-registry) could help.

Using Vaadin Licenses in offline mode:

* See [licensing FAQ](https://vaadin.com/licensing-faq-and-troubleshooting)
* Pass the license via a JVM parameter to Maven via `-Dvaadin.proKey=your@email.com/uuid`
