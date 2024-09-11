---
layout: post
title: Vaadin Lookup VS Vaadin Instantiator
---

Keywords: Vaadin Initialization. Quoting Javadoc,
"Lookup Provides a way to discover services used by Flow (SPI). Dependency injection
frameworks can provide an implementation that manages instances according to
the conventions of that framework. This is similar to the Instantiator class but a Lookup
instance is available even before a VaadinService instance is created
(and as a consequence there is no yet an Instantiator instance)."

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

# Spring

Vaadin 23+ Spring plugin initializes Lookup differently. The old Lookup Provider SPI is disabled.
Instead, `SpringLookupInitializer` is called from `VaadinServletContextInitializer`.
The `VaadinServletContextInitializer` is created as a bean in `SpringBootAutoConfiguration.contextInitializer()`;
since it's `ServletContextInitializer` it's probably loaded by Spring automatically
as long as `SpringBootAutoConfiguration` Spring configuration is activated.

## Non-Boot project

Some projects may use Spring but not Spring Boot, they would package themselves to WAR and
would be deployed to a servlet container such as Tomcat. Is it possible to use Vaadin-Spring
plugin in such Boot-less environment?

Since `ServletContextInitializer` interface (implemented by `VaadinServletContextInitializer`) comes from `spring-boot.jar`,
it would suggest
that either the plugin would fail with a `NoClassDefFoundError` (if Spring Boot is missing from classpath), or the `VaadinServletContextInitializer`
(and by extension, `SpringLookupInitializer`) is not initialized (if Spring Boot is pulled in to classpath transitively, but not activated).

Either way, the `SpringLookupInitializer` is not called, leading to this error:

```
Sep 09, 2024 4:58:09 PM org.apache.catalina.core.StandardContext listenerStart
SEVERE: Exception sending context initialized event to listener instance of class [com.vaadin.flow.server.startup.ServletContextListeners]
java.lang.IllegalStateException: The application Lookup instance is not found in VaadinContext. The instance is suppoed to be created by a ServletContainerInitializer. Issues known to cause this problem are:
- A Spring Boot application deployed as a war-file but the main application class does not extend SpringBootServletInitializer
- An embedded server that is not set up to execute ServletContainerInitializers
- Unit tests which do not properly set up the context for the test

	at com.vaadin.flow.server.startup.ApplicationConfiguration.lambda$get$0(ApplicationConfiguration.java:47)
	at com.vaadin.flow.server.VaadinServletContext.getAttribute(VaadinServletContext.java:66)
	at com.vaadin.flow.server.startup.ApplicationConfiguration.get(ApplicationConfiguration.java:41)
	at com.vaadin.flow.server.DeploymentConfigurationFactory.createPropertyDeploymentConfiguration(DeploymentConfigurationFactory.java:74)
	at com.vaadin.flow.server.startup.ServletDeployer$StubServletConfig.createDeploymentConfiguration(ServletDeployer.java:178)
```

Seems like the fix is to use `@EnableWebMvc` instead of `@SpringBootApplication`,
but you might still need to have Spring Boot on the classpath. See
[Using Vaadin With Spring MVC](https://vaadin.com/docs/v23/integrations/spring/spring-mvc) for more details.

Also make sure the Spring MVC `DispatcherServlet` is running: [Vaadin Servlet Auto-loading](../vaadin-servlet-auto-loading/)
otherwise none of the servlets will be served.
