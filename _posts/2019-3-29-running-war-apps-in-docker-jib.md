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

Then, edit the `build.gradle.kts` file. Because of [Issue 591](https://github.com/GoogleContainerTools/jib/issues/591)
we need to add the following on the top of the `build.gradle.kts` file:

```kotlin
buildscript {
    repositories {
        mavenCentral()
    }

    dependencies {
        classpath("com.google.guava:guava:27.0.1-jre")
    }
}
```

Then, just add the Jib plugin:

```kotlin
plugins {
   ...
   id("com.google.cloud.tools.jib") version "1.3.0"
}
```

Jib will automatically detect that the project is a WAR project and will use Jetty Docker image
(you can read more about this at [Jib War Projects](https://github.com/GoogleContainerTools/jib/tree/master/jib-gradle-plugin#war-projects)).

To build the Docker image locally, simply run

```bash
$ ./gradlew jibDockerBuild --image=test/karibu-helloworld-app
```

To run the image:

```bash
$ docker run --rm -ti -p8080:8080 test/karibu-helloworld-app
```

Done - your app is now running at [localhost:8080](http://localhost:8080).
