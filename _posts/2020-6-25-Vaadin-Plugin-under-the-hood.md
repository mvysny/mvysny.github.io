---
layout: post
title: Vaadin 14 Plugins - under the hood
---

Neither the [Vaadin Gradle Plugin](https://github.com/vaadin/vaadin-gradle-plugin/)
nor the [Vaadin Maven Plugin](https://github.com/vaadin/flow/issues/8617)
really document what they're doing under the hood. When something goes wrong,
it's very hard for a server-side guy like myself to know what's going on, especially
since the entire JavaScript client-side landscape is pretty much a mystery to a Java
guy. Hence this blog post.

Both Maven and Gradle Vaadin Plugins do pretty much the same thing; they both have two goals/tasks:

* `vaadin:prepare-frontend` for Maven, `vaadinPrepareFrontend` for Gradle
* `vaadin:build-frontend` for Maven, `vaadinBuildFrontend` for Gradle

> Note: If you feel lost at any point, please read the [Vaadin: the missing guide](../Vaadin-the-missing-guide/)
article first.

> Important: that this article **discusses the npm mode only**: since the compatibility/bower
mode is deprecated, we're not going to discuss that anymore.

## prepare-frontend

The prepare-frontend goal/task does the following things (you can follow the text below
and look into the sources of the
[Vaadin Gradle Plugin prepare-frontend task implementation](https://github.com/vaadin/vaadin-gradle-plugin/blob/master/src/main/kotlin/com/vaadin/gradle/VaadinPrepareFrontendTask.kt#L63)
if you'd like):

First, the plugin will prepare the very important `flow-build-info.json` file into
the classpath, into the `target/` or `build/` folder (depends on whether you use Maven or Gradle).
By placing it into the `target/` folder, the file will then later on be packaged
correctly into the target artifact, be it WAR, EAR or SpringBoot jar. This way
it is also visible to Vaadin when [launching Vaadin with embedded Jetty](https://github.com/mvysny/vaadin14-embedded-jetty).

> **Important:** Since the `flow-build-info.json` file is removed when
> running the `clean` task, it's really good to remember
> to run the `prepare-frontend` task after the `clean` task.

The next step is for the Vaadin Plugin to validate that the npm and node.js is of acceptable
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

> Note: The Gradle Vaadin Plugin
configures Gradle to handle this automatically, so if you run `vaadinBuildFrontend` task, the `vaadinPrepareFrontend` task is going to be run, too.

You can again follow the [Vaadin Gradle plugin build-frontend task implementation](https://github.com/vaadin/vaadin-gradle-plugin/blob/master/src/main/kotlin/com/vaadin/gradle/VaadinBuildFrontendTask.kt#L68).

First, the `flow-build-info.json` file is modified. Since we are targeting production mode here,
the Vaadin Servlet will no longer start embedded webpack and will serve precompiled
JavaScript files instead. That's why we set `enableDevServer` to false and remove
all npm-related settings like `npmFolder`, `generatedFolder` and `frontendFolder`.
We can also remove `pnpm.enable` since it doesn't matter how the precompiled JavaScript
files were produced. Also we remove `require.home.node` since in production mode
we do not need `node.js`, `npm` nor `webpack` anymore, since the precompiled JavaScript
files will be produced by the Plugin and packaged into the WAR/EAR/JAR archive.

Next, we will run `npm install` to make sure all packages are available in `node_modules`,
in order for webpack to be able to produce the precompiled JavaScript files (the `runNodeUpdater()` function
in plugin's sources).

Lastly, `webpack` is run, to package everything from `frontend/` and `node_modules` into
the precompiled JavaScript files bundle.

If this task succeeds, it should produce the following outputs:

* `node_modules` and `package-lock` in the project root folder;
* The `META-INF/VAADIN/config/flow-build-info.json` file into the folder where generated resources go;
* The `META-INF/VAADIN/config/stats.json` into the folder where generated resources go;
* The `META-INF/VAADIN/build/` folder into the folder where generated resources go.

The placement of generated resources depends on whether the project is built by
Maven (then the folder is somewhere in `target/classes/`) or Gradle (then it's in `build/resources/main/`).
It is now the job of the packaging plugin (WAR/EAR/JAR) to package those files
and folders properly, so that Vaadin can use ClassLoader to load those files as
resources from the classpath. For example:

* When building JAR without Spring Boot (see [vaadin14-embedded-jetty](https://github.com/mvysny/vaadin14-embedded-jetty) example project), those folders
  are simply located in the root of the jar file;
* When building WAR (see e.g. [skeleton-starter](https://github.com/vaadin/skeleton-starter-flow))
  then the folders are located in `WEB-INF/classes/`;
* When building JAR+Spring Boot (e.g. [skeleton-starter-flow-spring](https://github.com/vaadin/skeleton-starter-flow-spring), those folders are located in
  `BOOT-INF/classes/` in the Spring Boot jar file.

Please see [Vaadin: the missing guide](../Vaadin-the-missing-guide/) on the
example contents of those files and folders.

## What to read next

See the [Vaadin: Troubleshooting](../Vaadin-troubleshooting/) guide when something
goes wrong.

