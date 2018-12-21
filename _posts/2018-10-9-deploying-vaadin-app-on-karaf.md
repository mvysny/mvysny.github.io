---
layout: post
title: Deploying Vaadin app on Karaf
---

Karaf is an OSGi container rather than a WAR container. Hence it is not as
easy to deploy your WAR into Karaf as opposed to, say, Tomcat. You basically
have three options:
* Split your WAR into separate jars, add OSGi descriptors to all of those
  so that Karaf recognizes them as OSGi bundles, then plug your servlets
  into Karaf's pax-web something. That's a **lot** of work.
* Repackage your WAR as JAR with JARs, add OSGi descriptor so that Karaf
  recognizes that as a big bundle, then plug your servlets into Karaf's
  [Pax-Web](https://ops4j1.jira.com/wiki/spaces/paxweb/overview). That's
  *still* a lot of work.
* Use WAR Deployer and just copy your WAR to the `deploy/` folder. Ta-daa!
  This is the easiest way of deploying WAR to Karaf, the one that doesn't
  require you to add OSGi manifests to your WAR and/or tackle the XML bundle
  configurations. Let's go.

## Using Karaf WAR Deployer

First, [download Karaf](https://karaf.apache.org/download.html), the Karaf
Runtime is enough. Unpack it, go into the `bin/` folder and run it: `./karaf`.
Karaf will start and will present you with a console. Great. First lesson
is inspired by vim: we'll learn how to quit. Luckily that's easy, just press `Ctrl+D`.

We'll use the Karaf [WAR deployer](http://karaf.apache.org/manual/latest/#_war_deployer)
which is able to take a WAR file, add all necessary OSGi descriptors automatically
and deploy the WAR file on an internal Jetty server (or whatever is configured
to be used by the [Pax-Web](https://ops4j1.jira.com/wiki/spaces/paxweb/overview)
OSGi Http Service). In the Karaf console, type in:

```
karaf@root()> feature:install war
```

This will install the `http` feature (which is a basic support for serving
http in OSGi), `http-whiteboard` (which allows for mapping servlets to context
roots I guess) and `war` which is the WAR Deployer itself. You can verify
that everything is installed, by listing features:

```
feature:list | grep war
feature:list | grep http
```

WAR Deployer is old-fashioned and requires `web.xml` to be present in the
WAR file in order to be recognized and deployed properly by Karaf. Just add
the following dummy `web.xml` to your WAR project's `src/main/webapp/WEB-INF/` folder:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://java.sun.com/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
		  http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
         version="3.0">

</web-app>
```

That is enough - Jetty will properly autodiscover all of your servlets and
other annotated stuff. Now build your WAR file. You can use any Vaadin-based webapp;
for the purpose of this text we're going to experiment on the
[karibu-helloworld-application](https://github.com/mvysny/karibu-helloworld-application)
Vaadin 8 webapp. Just don't forget to add the `web.xml`, then run `./gradlew`
and find the WAR file in `build/libs`.

> *Note*: Vaadin 10 apps will crash with NPE for some reason, please feel
free to [report a bug to the Vaadin folk](https://github.com/vaadin/flow).

Copy the WAR file into Karaf's `deploy/` folder. The WAR file should be picked
up automatically and launched. You can follow the log of your app in Karaf
by using the `log:tail` Karaf command - consult the log for any exceptions
or other deployment failures. You can also use the `web:list` command to
check that your app is up and running, for example:

```
karaf@root()> web:list
ID  │ State       │ Web-State   │ Level │ Web-ContextPath                │ Name
────┼─────────────┼─────────────┼───────┼────────────────────────────────┼──────────────────────────────────────
105 │ Active      │ Deployed    │ 80    │ /karibu-helloworld-application │ karibu-helloworld-application (0.0.0)
```

Now you can go and see your app running on
[http://localhost:8181/karibu-helloworld-application](http://localhost:8181/karibu-helloworld-application). Enjoy.

## Enabling Push

`@Push` via WebSockets will not work with Vaadin 7.7.x and Karaf 4.1.6 and
will fall back to longpolling, because the bundled Jetty is newer than Vaadin
expects and Vaadin will fail with `java.lang.ClassNotFoundException: org.eclipse.jetty.websocket.server.WebSocketServerFactory`.
You need to force Vaadin to use JSR356 in Atmosphere:

```
@WebServlet(urlPatterns = "/*", name = "MyUIServlet", asyncSupported = true, initParams = {@WebInitParam(name = "org.atmosphere.cpr.asyncSupport", value = "org.atmosphere.container.JSR356AsyncSupport") })
```

Now we'll get `java.lang.RuntimeException: Cannot load platform configurator`,
because OSGi doesn't support standard stuff like ServiceLoader out-of-the-box.
On [Stackoverflow](https://stackoverflow.com/questions/39740531/jetty-websocket-java-lang-runtimeexception-cannot-load-platform-configurator)
there is a solution, but luckily a proper artifact is already provided by
the servicemix people. First remove all of your WAR files from the `deploy/`
folder. Stop Karaf and run it with `./karaf clean`. Then, in your karaf console:

```
$ feature:install war
$ bundle:install mvn:org.apache.servicemix.bundles/org.apache.servicemix.bundles.javax-websocket-api/1.1_1
$ la -u|grep websocket-api
 55 │ Active    │  30 │ 1.1                   │ mvn:javax.websocket/javax.websocket-api/1.1
 87 │ Active    │  30 │ 9.3.24.v20180605      │ mvn:org.eclipse.jetty.websocket/websocket-api/9.3.24.v20180605
105 │ Installed │  80 │ 1.1.0.1               │ mvn:org.apache.servicemix.bundles/org.apache.servicemix.bundles.javax-websocket-api/1.1_1
$ bundle:start 105
$ bundle:uninstall 55
```

And now try to redeploy your WAR file. If you don't to start from a clean
state, you can get `java.lang.ClassCastException: org.eclipse.jetty.websocket.jsr356.server.ServerContainer cannot be cast to javax.websocket.server.ServerContainer`
(that's your app loaded by a classloader which references old javax-websocket-api classloader);
if you fail to remove the old `javax.websocket-api` you can still get the
`Cannot load platform configurator` error.

Karaf, employing OSGi and class loaders, may suprise you with lots of nasty
exceptions. Be careful to start with a clean state, and repeat the steps if necessary.
