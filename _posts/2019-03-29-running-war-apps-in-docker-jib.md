---
layout: post
title: Running WAR apps in Docker with Jib
---

In the past I have written an article regarding [Launching your Vaadin apps in Docker](../Launch-your-Vaadin-on-Kotlin-app-quickly-in-cloud/).
That required you to write the Dockerfile. However there is even simpler way:
[Jib](https://github.com/GoogleContainerTools/jib).

We're going to launch the [Karibu HelloWorld App](https://github.com/mvysny/karibu-helloworld-application) in Docker.
First, clone the repo:

```bash
$ git clone https://github.com/mvysny/karibu-helloworld-application
```

Then, edit the `build.gradle.kts` file and add the Jib plugin:

```kotlin
plugins {
   // ...
    id("com.google.cloud.tools.jib") version "3.0.0"
}
```

> Note: these instructions might be outdated. Please see the [vaadin-kotlin-pwa build.gradle.kts](https://github.com/mvysny/vaadin-kotlin-pwa/blob/master/build.gradle.kts)
> file for the most up-to-date JIB plugin configuration.

Jib will automatically detect that the project is a WAR project and will use Jetty Docker image
(you can read more about this at [Jib War Projects](https://github.com/GoogleContainerTools/jib/tree/master/jib-gradle-plugin#war-projects)).
However, to force a specific Jetty image just add this to `build.gradle.kts`:

```kotlin
jib {
    from {
        image = "jetty:9.4.40-jre11"
    }
    container {
        appRoot = "/var/lib/jetty/webapps/ROOT"
        user = "root" // otherwise we'll get https://github.com/appropriate/docker-jetty/issues/80
    }
}
```

To build the Docker image locally, simply run

```bash
$ ./gradlew clean build jibDockerBuild --image=test/karibu-helloworld-app
```

To run the image:

```bash
$ docker run --rm -ti -p8080:8080 test/karibu-helloworld-app
```

Done - your app is now running at [localhost:8080](http://localhost:8080).
