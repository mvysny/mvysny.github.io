---
layout: post
title: NPE in `VaadinServlet.serveStaticOrWebJarRequest()`
---

Keywords: embedded Jetty, getting `NullPointerException`:
`Cannot invoke "com.vaadin.flow.server.StaticFileHandler.serveStaticResource(javax.servlet.http.HttpServletRequest, javax.servlet.http.HttpServletResponse)" because "this.staticFileHandler" is null`

What if you are tinkering with the servlet environment (perhaps
[trying to run Vaadin in embedded jetty](https://github.com/mvysny/vaadin-embedded-jetty-gradle) or such),
and suddenly you're getting `NullPointerException`s such as `Cannot invoke "com.vaadin.flow.server.StaticFileServer.serveStaticResource(javax.servlet.http.HttpServletRequest, javax.servlet.http.HttpServletResponse)" because "this.staticFileHandler" is null`?
How can that happen?

The reason is the check in `VaadinServlet:124` which checks whether `vaadinServletContext
.getAttribute(Lookup.class) == null` - if it is, the function just returns without fully initializing the servlet.
That causes the `VaadinServlet.staticFileHandler` to stay `null`, which then fails
with the abovementioned NPE.

The main entrypoint of the Vaadin initialization is the `Lookup` class. Read
[Vaadin Lookup VS Vaadin Instantiator](../vaadin-lookup-vs-instantiator/) blogpost for
more information.

## Fixing this

Place a breakpoint into the `LookupServletContainerInitializer` class somewhere - if
the breakpoint isn't triggered then Vaadin is not initialized properly. It's the responsibility
of the servlet container (such as Jetty) to discover and call `LookupServletContainerInitializer`, however
in certain cases Jetty won't do it:

1. Either because jetty annotation.jar missing on the classpath
2. Or `ContainerIncludeJarPattern` wasn't set, leaving Jetty to not to perform classpath scanning.

Simply use [Vaadin-Boot](https://github.com/mvysny/vaadin-boot) which takes care of proper Vaadin initialization.
