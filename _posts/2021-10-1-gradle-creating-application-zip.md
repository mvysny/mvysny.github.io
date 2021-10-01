---
layout: post
title: Gradle - creating Application zip
---

To create a zip with the project jar, all transitive dependencies and a bunch of scripts,
just paste this into your `build.gradle`:

```groovy
task zip(type: Zip) {
    from 'src/main/scripts' // adds scripts
    into('lib') {
        from jar // adds jar produced by this project
        from configurations.runtimeClasspath // adds all transitive dependencies
    }
}

artifacts {
   archives zip
}
```

Then, a script which runs your app:

```bash
#!/bin/bash
set -e -o pipefail
CP=`ls lib/*.jar|tr '\n' ':'`
JAVA_OPTS="-Xmx3G $JAVA_OPTS"
java $JAVA_OPTS -cp $CP your.Main "$@"
```

However, even simpler is to use the [application plugin](https://docs.gradle.org/current/userguide/application_plugin.html) -
it will create a zip and a tar of your app, all transitive dependencies and will
also automatically generate scripts which run your app:

```groovy
plugins {
    id 'java'
    id 'application'
}
application {
    mainClassName = "your.Main"
}
```
