---
layout: post
title: Vaadin Gradle Plugin Official!
---

After months of development and testing, the Vaadin Gradle Plugin is now official,
hooray! :-D

You can now see that the ['com.vaadin' Vaadin Plugin at plugins.gradle.org](https://plugins.gradle.org/plugin/com.vaadin)
version no longer begins with the leading zero (which meant that the plugin is in alpha state),
but instead now follows the Vaadin platform official versioning. 

That being said, the plugin `20.0.0.alpha6` is bit of an exception. The alpha, beta, rc
versions will no longer be released to plugins.gradle.org - only the final versions
will be released to toe Gradle Plugins repo. This is in accord with the Maven plugin:
final versions of the plugin are released to Maven Central while pre-releases are released to `vaadin-prereleases` only.

If you need to use a pre-release version of the plugin, create the following
`settings.gradle.kts` file in the root folder of your Gradle-based project:

```kotlin
pluginManagement {
    repositories {
        maven { setUrl("https://maven.vaadin.com/vaadin-prereleases") }
        gradlePluginPortal()
    }
}
```

That will enable you to download Gradle plugin pre-releases from the `vaadin-prereleases` repository.

The official [vaadin-prereleases](https://maven.vaadin.com/vaadin-prereleases)
does not allow browsing though; however in order to find out the gradle plugin
you can browse the following repo which is exactly the same thing:
[vaadin-gradle-plugin prereleases at Vaadin Nexus](http://tools.vaadin.com/nexus/content/repositories/vaadin-prereleases/com/vaadin/vaadin-gradle-plugin/).
