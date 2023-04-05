---
layout: post
title: Vaadin Lookup VS Vaadin Instantiator
---

Quoting Javadoc,
Lookup Provides a way to discover services used by Flow (SPI). Dependency injection
frameworks can provide an implementation that manages instances according to
the conventions of that framework. This is similar to the Instantiator class but a Lookup
instance is available even before a VaadinService instance is created
(and as a consequence there is no yet an Instantiator instance).

In short, Vaadin Lookup is pretty low-level stuff used to instantiate Vaadin internals (including the Instantiator itself);
while Instantiator is used to create instances of Routes, [i18n](../vaadin-localization/)
and components in Polymer/LitTemplates. Apps may encounter a need to [override Instantiator](../vaadin-custom-instantiator/);
however there's really no use-case to override Lookup yourself. Correct
implementation of Lookup is provided automatically (for example for the OSGi environment there's `OsgiLookupImpl`).

## Initializing `Lookup`

What if you are tinkering with the servlet environment (perhaps
[trying to run Vaadin in embedded jetty](https://github.com/mvysny/vaadin-embedded-jetty-gradle) or such),
and suddenly you're getting `NullPointerException`s such as `Cannot invoke "com.vaadin.flow.server.StaticFileHandler.serveStaticResource(javax.servlet.http.HttpServletRequest, javax.servlet.http.HttpServletResponse)" because "this.staticFileHandler" is null`
because `getContext().getAttribute(Lookup.class)` returned null? Who creates Lookup?

Everything starts in `LookupServletContainerInitializer`. It implements `ServletContainerInitializer`
and has `@HandlesTypes` annotation, which tells the servlet container to perform classpath discovery
of given classes and hand them over to `LookupServletContainerInitializer`.

`LookupServletContainerInitializer.getLookupInitializer()` then discovers proper `AbstractLookupInitializer`:
if your app defines a class which extends `AbstractLookupInitializer` then that class is automatically used;
otherwise the default `LookupInitializer` is used. Then `AbstractLookupInitializer.initialize()` is called,
which creates the `Lookup` instance and calls `VaadinApplicationInitializationBootstrap` closure
which finally sets the `Lookup` instance to the `VaadinServletContext`. Holy shit this
could not be more complicated.

In short: if you're getting those `NPE`s, make sure your servlet container finds and runs
`LookupServletContainerInitializer`.

[Karibu-Testing](https://github.com/mvysny/karibu-testing/) runs no servlet container and
therefore calls `LookupServletContainerInitializer` manually, then ensures that `Lookup` is
properly set in the `VaadinServletContext`

## Yet Another Way For a custom `Instantiator`

You could in theory introduce your own `AbstractLookupInitializer` which provides a custom `InstantiatorFactory`
which loads your `Instantiator`, but that's a really complicated way. For simpler ways, see
[Vaadin custom instantiator](../vaadin-custom-instantiator/).
