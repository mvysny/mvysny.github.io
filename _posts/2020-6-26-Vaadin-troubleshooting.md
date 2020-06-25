---
layout: post
title: Vaadin - Troubleshooting
---

Sometimes Vaadin 14 fails mysteriously, which is very unfortunate: it now uses
LOTS of JavaScript code, frameworks and tools. Those things are unfamiliar to server-side
guys, and it's really hard to tell what to do, should one of JavaScript toolchain fail.

This article remedies that, by listing a bunch of troubleshooting ideas and FAQs to
follow and check out. We expect a basic knowledge of Vaadin toolchain here, please
read the [Vaadin: the missing guide](../Vaadin-the-missing-guide/) article
and the [Vaadin Plugin under the hood](../Vaadin-Plugin-under-the-hood/) article first.

## What to do first

Sometimes Vaadin will fail to update `package.yaml` and `package-lock.yaml` with
new versions of npm modules (especially after a Vaadin version update),
or sometimes the `node_modules` becomes corrupted, or `package.yaml` will list
multiple versions of the same thing.

The best thing to do first is to perform the "Vaadin Dance" (akin to [Eclipse Dance](http://underlap.blogspot.com/2011/10/eclipse-dance-steps.html)):
delete all npm-related packages, npm config files and webpack config files and force
Vaadin to start from the clean state. You can achieve this by deleting the following files:

* `node_modules`
* `package.json`
* `package-lock.json` (if using npm)
* `webpack.generated.js`
* `pnpm-lock.yaml` (if using pnpm)
* `pnpmfile.js` (if using pnpm)

(With [Vaadin Gradle plugin](https://github.com/vaadin/vaadin-gradle-plugin) you can simply run the `vaadinClean` task to do this).

Then run the `prepare-frontend` task, to re-create those files. Note that the `node_modules`
is populated later: either by Vaadin Servlet when running in development mode, or
by `build-frontend` when building for production.

### Gradle: use matching version of Vaadin and the Plugin

Use Gradle Plugin 0.6.0 for Vaadin 14.1 and lower; use Gradle Plugin 0.7.0 for Vaadin 14.2 and newer.
Gradle Plugin 0.6.0 doesn't work correctly with Vaadin 14.2.

### Use newest Vaadin

Use the newest Vaadin 14.x - there are also fixes with respect to the JavaScript
toolchain; for example it could be that at some point Vaadin will be able to detect
all breaks and issues and the Vaadin Dance will be unnecessary.

### Production issues: make sure the necessary files are present

Make sure that all of the Vaadin files are present in the WAR/EAR/JAR archive:

* Most importantly, the `flow-build-info.json` file, located on classpath in the
  `META-INF/VAADIN/package/` package.
  * In a WAR archive it's located in the
  `WEB-INF/classes/META-INF/VAADIN/config/` folder; in a SpringBoot JAR it's located
  in `BOOT-INF/classes/META-INF/VAADIN/config/` folder.
  * Make sure that it sets the following properties as follows:
  `"compatibilityMode": false, "productionMode": true, "enableDevServer": false`


TBD
