---
layout: post
title: Figuring out Vaadin version in runtime
---

For example you may want to log the Vaadin version to the server log at start time,
or you want to see whether the vaadin version v-bump has been taken into effect
in your project.

## From Java

You can look up the `NpmPackage` annotation from the `VaadinCoreShrinkWrap` class to learn the
Vaadin version. This works with Vaadin 14 and higher.

> Tip: that's what `VaadinVersion.get` from [karibu-tools](https://github.com/mvysny/karibu-tools/) does.

## From JavaScript

This one is trickier.

### In both dev mode and in production

For Vaadin 20+ the Vaadin component versions is in sync with the version of Vaadin itself.
Therefore, running `customElements.get('vaadin-button').version` should return
something like `"21.0.2"` which exactly matches the Vaadin version.

Unfortunately, on Vaadin 14 this doesn't work since `customElements.get('vaadin-button').version`
will print something like `"2.4.0"` and you have to figure out the Vaadin version from that somehow.
One way would be to take a look at the `@NpmPackage(value = "@vaadin/vaadin-button", version = "2.4.0")`
annotation present on the Java `Button` class (or rather `GeneratedVaadinButton`), but
it's definitely not a clear indicator of Vaadin version.

There's `window.Vaadin` and `window.Vaadin.Flow` object but neither of those seem
to be able to provide the version. You can only learn whether you're running
production mode or not, by querying `window.Vaadin.developmentMode`.

### In dev mode

* In Vaadin 22+ the dev mode gizmo will now clearly show Vaadin version.

Other than that, the dev mode doesn't provide more information on Vaadin version than
the production mode does.
