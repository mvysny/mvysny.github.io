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

The only disadvantage is the missing URIBuilder, and a bit of bare-bones API.

## URIBuilder

URIBuilder is useful when you need to programmatically create the URI, e.g. programmatically add query parameters and escape them correctly.
URIBuilder is unfortunately not baked in JVM. Fear not, there are these solutions:

* Use the [apache-uribuilder](https://gitlab.com/mvysny/apache-uribuilder) library. It's a fork of Apache HttpCore5 but with just the URIBuilder part.
* Alternatively, this [urlbuilder project](https://github.com/mikaelhg/urlbuilder) looks good too.
* Alternatively use [http4k](https://www.http4k.org/guide/howto/client_as_a_function/) with a bit of
  [error-checking code](../using-gson-with-http4k/)

There are other ways of getting the URIBuilder class, but they're inferior:

* [Apache HttpCore5](https://hc.apache.org/httpcomponents-core-5.2.x/) ([sources on github](https://github.com/apache/httpcomponents-core/tree/master/httpcore5/src/main/java/org/apache/hc/core5/net))
  offers URIBuilder. It doesn't require any additional dependencies, which is great; but the jar itself is 900kb long.
  Still, this is the best way to go forward at the moment.
* There's a rs URIBuilder baked in JavaEE7, but that also brings tons of deps
* Spring has URIBuilder too, but that also brings tons of deps
* [URIBuilder-tiny](https://github.com/moznion/uribuilder-tiny) lacks support for duplicate query parameters, useful e.g. when you need to create a filter query such as
  `http://foo.com/rest/person?age=lt:30&age=gt:20`. See [#7](https://github.com/moznion/uribuilder-tiny/issues/7).
* [uri-builder-java](https://github.com/BastiaanJansen/uri-builder-java) is barebones and doesn't even support escaping
* [httpcache4j uribuilder](https://github.com/httpcache4j/uribuilder) is immutable which is just plain dumb to create an immutable builder
  (which is by definition a mutable builder used to build immutable objects).

## Usage Tips

See [HttpClient Usage Tips](../httpclient-error-checking/).

## Android

What about Android? The `java.net.http.HttpClient` is missing; Android instead packages
Apache HttpClient by default. The quality of that one is unknown, but I'm not sure whether
it's portable to JDK. Everyone else seems to be using okhttp, so I'll go with that for the time being.

Beware: okhttp 3.13+ requires Android 5.0 (SDK 21); you can use 3.12+ but it lacks support for TLS 1.2+.
I think that everyone switched to Android 5.0 already, so going with okhttp 4+ is probably a good choice.
