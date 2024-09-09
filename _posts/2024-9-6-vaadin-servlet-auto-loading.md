---
layout: post
title: Vaadin Servlet Auto-Loading
---

When a project defines no `@WebServlet`, how come that `VaadinServlet` gets loaded automatically?
Without automatic loading of `VaadinServlet` there would be no servlet to handle
requests, and Jetty/Tomcat would simply return 404 NOT FOUND.
Let's take a look, both on standard servlet project and on a Spring-Boot project, how
the automatic loading works.

## Servlet project

In this case we're running Vaadin app in a servlet container without Spring (e.g.
embedded container via [Vaadin-Boot](https://github.com/mvysny/vaadin-boot)).
The `ServletDeployer.contextInitialized()` gets called by the servlet container,
since it implements the `ServletContextListener`. It ultimately calls `ServletDeployer.createServletIfNotExists()`
which in turn calls `ServletContext.addServlet()` to register a new `VaadinServlet` dynamically.
The servlet mapping is set to `/*` which means that it will handle all requests by default
(unless there is a servlet mapped to a more specific path).

## Spring-Boot project

When running Vaadin via Spring Boot, the important code is at `SpringBootAutoConfiguration.servletRegistrationBean()`
which creates the servlet binding of `SpringServlet`. Note the `@ConditionalOnMissingBean` annotation
which only creates the binding if the project doesn't have a custom `@WebServlet` extending
from `SpringServlet`.

Note that this annotation was missing for Vaadin 23.4.1 which causes the default servlet to load anyway,
causing WebSocket issues: [#19888](https://github.com/vaadin/flow/issues/19888).

What's interesting is that the default servlet is mapped to `/vaadinServlet/*` and not `/*`,
yet the app apparently works and requests are handled at `/*`. There is a Spring magic which
configures Spring Dispatcher Servlet to dispatch requests accordingly.

### Spring Dispatcher Servlet

Spring uses something called the Front Controller pattern where
a single servlet forwards requests to other controllers. There's
[An Intro to the Spring DispatcherServlet](https://www.baeldung.com/spring-dispatcherservlet)
about the concept.

To debug this monster, just open the `DispatcherServlet` class coming from
Spring, and place a breakpoint to `DispatcherServlet.doDispatch()`.
The `handlerMappings` is a list of all handlers where the dispatcher servlet
will try to dispatch the HTTP request.

One of those is `VaadinServletConfiguration$RootExcludeHandler` which
dispatches requests to `/*` to the `vaadinForwardingController` bean,
which is a `ServletForwardingController`, forwarding requests to `SpringServlet`.
See both beans in the `VaadinServletConfiguration` class.

The handler sets its order to almost the lowest value, so almost any other handler
will come before this one. That's why it's easy to snatch request processing
away from Vaadin `SpringServlet`.

### Open questions

I don't know the answers for these yet.

1. Is there a configuration in `application.properties` which increases the order of `VaadinServletConfiguration$RootExcludeHandler`?
2. If I introduce my own servlet extending `SpringServlet`, `servletRegistrationBean()` still auto-loads `SpringServlet`
   loads anyway because of [#19888](https://github.com/vaadin/flow/issues/19888). Can this auto-loading be
   turned off somehow?
3. If I introduce my own custom servlet extending `SpringServlet`, will the `DispatcherServlet` be turned off,
   or will it merely prioritize my custom servlet above other handlers?

# Vaadin 8

The abovementioned applied to Vaadin 23+. Let's take a look how Vaadin 8 works under the hood.

## Servlet project

There's no `ServletDeployer` and no automatic registration of `VaadinServlet`. You
have to have a servlet registered in your app, in order for Vaadin 8 to work.
That's what you usually do anyway, since Vaadin 8 auto-configures itself via the
`@VaadinServletConfiguration` annotation expected to be present on the servlet.
Usually you have something like this in your code:
```java
@VaadinServletConfiguration(ui = MyVaadin8UI.class, productionMode = false)
@WebServlet(urlPatterns = {"/*"})
public class MyServlet extends VaadinServlet {}
```

## Spring-Boot project

When running Vaadin 8 via Spring Boot, the important code is at `VaadinServletConfiguration.vaadinServlet()`
(which creaetes the `SpringVaadinServlet` itself)
and `VaadinServletConfiguration.createServletRegistrationBean()`
(which creates the `ServletRegistrationBean`).
Note the `@ConditionalOnMissingBean` annotation
which only creates the binding if the project doesn't have a custom `@WebServlet` extending
from `SpringServlet`.

What's interesting is that the default servlet is mapped to `/vaadinServlet/*` and not `/*`,
yet the app apparently works and requests are handled at `/*`. There is a Spring magic which
configures Spring Dispatcher Servlet to dispatch requests accordingly.

See the documentation above for other Spring-related stuff.
