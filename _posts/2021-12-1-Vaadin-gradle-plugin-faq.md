---
layout: post
title: Vaadin 14 Gradle plugin FAQ
---

#### Q: I'm getting java.io.FileNotFoundException: JAR entry during vaadinBuildFrontend

The full stack trace is
```
java.io.FileNotFoundException: JAR entry org/x/y/Z.class not found in /your/project/folder/build/libs/yourproject.jar
        at com.vaadin.flow.server.frontend.scanner.FrontendDependencies.visitClass(FrontendDependencies.java:490)
        at com.vaadin.flow.server.frontend.scanner.FrontendDependencies.collectEndpoints(FrontendDependencies.java:250)
        at com.vaadin.flow.server.frontend.scanner.FrontendDependencies.computeEndpoints(FrontendDependencies.java:228)
        at com.vaadin.flow.server.frontend.scanner.FrontendDependencies.<init>(FrontendDependencies.java:98)
```

Java 8 JDK may fail with a cryptic
`java.io.FileNotFoundException: JAR entry org/x/y/Z.class not found in /your/project/folder/build/libs/yourproject.jar`
when it's running out of file handles on Linux. It could be that the Gradle daemon has been running in the background
for some time, amassing lots of opened files in the meantime. Try killing it with `killall java` then restart
the build, or run gradle with the `--no-daemon` switch.

You can also increase the file open limit. Try printing the current limit of open files via `ulimit -n`; if it's 1024 or lower
try to increase it:

```
$ ulimit -n 200000
$ killall java
```

Kill all java processes to make sure the Gradle daemon is dead and is started anew next time, using the new
file limit.

Reported as [flow #12489](https://github.com/vaadin/flow/issues/12489)

#### Q: I'm getting IllegalArgumentException: wrong number of arguments

The full stack trace is

```
Caused by: java.lang.IllegalArgumentException: wrong number of arguments
        at com.vaadin.flow.server.webcomponent.WebComponentModulesWriter$DirectoryWriter.generateWebComponentsToDirectory(WebComponentModulesWriter.java:246)
        at com.vaadin.flow.server.frontend.FrontendWebComponentGenerator.generateWebComponents(FrontendWebComponentGenerator.java:95)
        at com.vaadin.flow.server.frontend.NodeTasks.<init>(NodeTasks.java:451)
```

and it's caused by your project using different Vaadin version than the Vaadin Gradle Plugin was intended for.
For example, your project is using Vaadin 14.2 while you're trying to use Gradle plugin 0.14.6.0. Try to change the Vaadin Gradle
plugin version in your `build.gradle` to better match your Vaadin version.
Alternatively, try to upgrade Vaadin version in your project.

Please see the Compatibility chart at the [Vaadin gradle plugin](https://github.com/vaadin/vaadin-gradle-plugin/) page.

