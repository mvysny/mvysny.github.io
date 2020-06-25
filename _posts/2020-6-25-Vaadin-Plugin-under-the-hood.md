---
layout: post
title: Vaadin plugin - under the hood
---

Neither the [Vaadin Gradle Plugin](https://github.com/vaadin/vaadin-gradle-plugin/)
and the [Vaadin Maven Plugin](https://github.com/vaadin/flow/issues/8617)
really document what they're doing under the hood. When something goes wrong,
it's very hard for a server-side guy to know what's going on, especially
since the entire JavaScript client-side landscape is pretty much a mystery to a Java
guy. Therefore, this blog post.

Both plugins do the same thing and have two goals/tasks:

* `vaadin:prepare-frontend` for Maven, `vaadinPrepareFrontend` for Gradle
* `vaadin:build-frontend` for Maven, `vaadinBuildFrontend` for Gradle

In order to understand what's going on, please read the [Vaadin: the missing guide](../Vaadin-the-missing-guide/)
article first.

Note that this article **discusses the npm mode only**: since the compatibility/bower
mode is deprecated, we're not going to discuss that anymore.

## prepare-frontend

The prepare-frontend goal/task does the following things (you can follow the text below
and look into the sources of the
[Vaadin Gradle Plugin prepare-frontend task implementation](https://github.com/vaadin/vaadin-gradle-plugin/blob/master/src/main/kotlin/com/vaadin/gradle/VaadinPrepareFrontendTask.kt#L63)
if you'd like).

First, the plugin will prepare the very important `flow-build-info.json` file into
the classpath, into the `target/`/`build/` folder. This way, it will then be packaged
correctly into the target artifact, be it WAR, EAR or SpringBoot jar. This way
it is also visible to Vaadin when [launching Vaadin with embedded Jetty](https://github.com/mvysny/vaadin14-embedded-jetty).

> **Important:** Since the file is removed when running the `clean` task, it's really good to remember
> to run the `prepare-frontend` task after the `clean` task.

Afterwards, Vaadin plugin validates that the npm and node.js is of acceptable
version, and will warn or fail if either one is too old. If either of the npm or node.js is missing,
Vaadin plugin will automatically download both, into the `$HOME/.vaadin/node` folder.

Afterwards, Vaadin plugin will generate the necessary npm and webpack configuration files:
`webpack.config.js`, `webpack.generated.js` and `package.json`. Note that the
`node_modules` nor `package-lock` files are not generated at this point:
they will be generated later on:

* In development mode: Vaadin Servlet will run npm and webpack automatically,
  before the app is started, to populate those folders.
* In production mode, you run `build-frontend` which will run npm and webpack
  and will produce the huge JavaScript file, containing all npm modules.

After the `prepare-frontend` finishes, you're all set to run the Vaadin application
in the development mode.

## build-frontend

`build-frontend` builds on the outcome of the `prepare-frontend` task, and thus
it requires the `prepare-frontend` task to be run beforehand.

You can again follow the [Vaadin Gradle plugin build-frontend task implementation](https://github.com/vaadin/vaadin-gradle-plugin/blob/master/src/main/kotlin/com/vaadin/gradle/VaadinBuildFrontendTask.kt#L68).

TBD