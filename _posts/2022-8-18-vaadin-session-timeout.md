---
layout: post
title: Vaadin Session Timeout
---

The Vaadin documentation at [Application Lifecycle: UI Expiration](https://vaadin.com/docs/latest/advanced/application-lifecycle#application.lifecycle.ui-expiration)
is not very clear. The [Stack Overflow: Session Stays Open Indefinitely Answer](https://stackoverflow.com/a/60560014/377320)
by Erik Lumme is much clearer.

In short, if you want to set the session timeout to 30 minutes, make sure that you set all of the following:

* The web container session timeout is set to 30 (see below)
* Set Vaadin's `DeploymentConfiguration.closeIdleSessions` to `true` (see below)

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

## FAQ

* Q: If `closeIdleSessions` is set to `false`, will the session ever close if the user just idles?
* A: When `closeIdleSessions` is `false`, heartbeat requests will effectively keep the session active for as long as the user has at least one tab open, using up server memory.
* Q: Will Tomcat's session-to-disk storage help with memory consumption?
* A: No. Session-to-disk only works for passivated sessions, which doesn't happen by default. That also requires all session objects to implement `Serializable`.
