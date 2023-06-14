---
layout: post
title: okhttp vs JVM built-in HttpClient
---

[okhttp](https://square.github.io/okhttp/) was my go-to library when writing a http client code
for JVM. However, since Java 9 there's a built-in `java.net.http.HttpClient`.
Feature-wise and API-wise it compares very well against okhttp - it's really usable, supports async
out-of-the-box and is baked-in in JVM by default, as opposed to okhttp (which also brings in additional dependency on okio).

You can check out the [HttpClient overview on Baeldung](https://www.baeldung.com/java-9-http-client); the
[HttpClient javadoc](https://docs.oracle.com/en/java/javase/11/docs/api/java.net.http/java/net/http/HttpClient.html) is
very well written and contains examples to get you started quickly.

The only disadvantage is the missing URIBuilder.

## URIBuilder

URIBuilder is useful when you need to programatically create the URI, e.g. programatically add query parameters and escape them correctly.
URIBuilder is not baked in JVM, and it's surprisingly hard to find a decent library that only provides URIBuilder:

* [Apache HttpCore5](https://hc.apache.org/httpcomponents-core-5.2.x/) offers URIBuilder. It doesn't require any additional dependencies, which is great; but the jar itself is 900kb long.
  Still, this is the best way to go forward at the moment.
* There's a rs URIBuilder baked in JavaEE7, but that also brings tons of deps
* Spring has URIBuilder too, but that also brings tons of deps
* [URIBuilder-tiny](https://github.com/moznion/uribuilder-tiny) lacks support for duplicate query parameters, useful e.g. when you need to create a filter query such as
  `http://foo.com/rest/person?age=lt:30&age=gt:20`. See [#7](https://github.com/moznion/uribuilder-tiny/issues/7).
* [uri-builder-java](https://github.com/BastiaanJansen/uri-builder-java) is barebones and doesn't even support escaping
* [httpcache4j uribuilder](https://github.com/httpcache4j/uribuilder) is immutable which is just plain dumb to create an immutable builder
  (which is by definition a mutable builder used to build immutable objects).

An ideal solution would be to copy URIBuilder out of Apache HttpCore5 and add nothing else to the jar.
