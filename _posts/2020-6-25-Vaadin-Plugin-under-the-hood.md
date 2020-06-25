---
layout: post
title: Vaadin - The missing guide
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

In order to understand what's going on, please read the [Vaadin: the missing guide](../2020-6-24-Vaadin-the-missing-guide/)
article first.

## prepare-frontend

TBD
