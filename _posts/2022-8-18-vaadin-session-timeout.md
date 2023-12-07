---
layout: post
title: Vaadin Session Timeout
---

The Vaadin documentation at [Application Lifecycle: UI Expiration](https://vaadin.com/docs/latest/advanced/application-lifecycle#application.lifecycle.ui-expiration)
is not very clear. The [Stack Overflow: Session Stays Open Indefinitely Answer](https://stackoverflow.com/a/60560014/377320)
by Erik Lumme is much clearer.

In short, if you want to set the session timeout to 30 minutes, make sure that you set all the following:

* The web container session timeout is set to 30 (see below)
* Set Vaadin's `DeploymentConfiguration.closeIdleSessions` from the default `false` to `true` (see below)

## Configuring web container session timeout

It's not possible to set the value via an annotation, but you can set it programmatically:

```java
@WebListener
public class MyWebListener implements ServletContextListener {
    @Override
    public void contextInitialized(ServletContextEvent sce) {      
        ServletContextListener.super.contextInitialized(sce);
        sce.getServletContext().setSessionTimeout(45); // session timeout in minutes
    }
}
```

or by calling `VaadinSession.getSession()).getHttpSession().setMaxInactiveInterval(30 * 60)` for every session created.

If you're still using `web.xml`, you can set `<session-timeout>30</session-timeout>`, see [Java Session Timeout](https://www.baeldung.com/servlet-session-timeout).

## Setting Vaadin DeploymentConfiguration via servlet init parameters

The [official Vaadin documentation on configuration properties](https://vaadin.com/docs/latest/configuration/properties)
is quite well hidden, therefore I'll repost it here.
In order to change `DeploymentConfiguration` properties, pass them as a servlet init parameter.
Simply define your own servlet which extends VaadinServlet:

```java
@WebServlet(urlPatterns = "/*", name = "myservlet", asyncSupported = true, initParams = {@WebInitParam(name = InitParameters.SERVLET_PARAMETER_CLOSE_IDLE_SESSIONS, value = "true")})
public class MyServlet extends VaadinServlet {
}
```

To check whether the configuration was applied, call the following e.g. from your main route:
```java
@Route("")
public class MainView extends VerticalLayout {

    public MainView() {
        System.out.println(VaadinServlet.getCurrent()); // to verify that the servlet class is MyServlet
        System.out.println(VaadinService.getCurrent().getDeploymentConfiguration().isCloseIdleSessions()); // should print "true"
    }
}
```

## Explanation

If there are open UIs but no active browsers and thus no heartbeats, the web container
will invalidate and close the session after 30 minutes. The session reaper thread usually
runs once per minute, so in the worst case the session should be closed in 31 minutes since
the last request was made.

If there are active browsers, they will periodically send heartbeats, preventing the
web container from closing the session. This is where `closeIdleSessions` steps in. Since
`closeIdleSessions` is true, Vaadin will run the `VaadinService.cleanupSession()` function
on every request, including the heartbeat request. The function will check whether
last non-heartbeat request was 30 minutes ago or more; if it was, the session and all UIs are closed.
By default, heartbeats are sent every 5 minutes; in the worst case the session should be closed in 35 minutes since
the last non-heartbeat request was made.

In short, either Vaadin or web container will eventually close the session, regardless of
whether there are browsers open or not.

### Heartbeats

The default heartbeat setting is 5 minute or 300 seconds. See `DefaultDeploymentConfiguration.getHeartbeatInterval()`
for more details. You can override this value via Java System properties or via Servlet init parameter,
see [Configuration Properties](https://vaadin.com/docs/latest/configuration/properties) for more details.

The numeric value of the `heartbeatInterval` property denotes a number in seconds.

## FAQ

* Q: If `closeIdleSessions` is set to `false`, will the session ever close if the user just idles?
* A: When `closeIdleSessions` is `false`, heartbeat requests will effectively keep the session active for as long as the user has at least one tab open.
* Q: Will Tomcat's session-to-disk storage help with memory consumption?
* A: No. Session-to-disk only works for passivated sessions, which doesn't happen by default. That also requires all session objects to implement `Serializable`.
* Q: How long does it then take for the session to close if there's an open browser tab but the user is doing nothing?
* A: If `closeIdleSessions` is `false` then never since heartbeat requests will effectively keep the session active.
     Otherwise, Vaadin will eventually close the UI (after the age of the UI surpasses the session timeout) which will stop the communication from the browser to the server.
     Servlet container will then close the session after the session timeout elapses. That means that the session is closed roughly after the session timeout times two.
