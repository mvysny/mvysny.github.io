---
layout: post
title: Vaadin Session Timeout / Heartbeats
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

or by calling `VaadinSession.getSession()).getHttpSession().setMaxInactiveInterval(30 * 60)` for every session created;
or by setting `server.servlet.session.timeout=1h` when using Spring Boot.

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
Or set `vaadin.closeIdleSessions=true` in `application.properties` if using Spring Boot.

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

### The purpose of heartbeats

The purpose of heartbeats is to close unused UIs sooner than when the session is destroyed. Say you have two open tabs
and you close one of them. With the default heartbeat of 5 minutes, the UI for that tab is closed after 15-20 minutes.
Closing a UI requires an ongoing request; since there's the second tab/UI which sends heartbeats, these requests will
eventually detect three missed heartbeats of the closed UI/tab and will close it.

However, this mechanism doesn't work when there's just one tab and is closed. The heartbeats stop coming to the server;
since there's nobody else performing requests, Vaadin Servlet is not invoked and can not run the UI cleanup loop.
Therefore, the UI is kept open until the session is eventually closed by the servlet container.

#### Turning off heartbeats

What happens when we turn off the heartbeat mechanism? You can turn off the heartbeat mechanism by setting it to `-1` or any negative value.
The documentation says that UIs are closed after 3 missed heartbeats;
however there are no heartbeats and so the UI cleanup loop never closes any UI. The UIs are therefore kept around until
the session is ultimately destroyed by the servlet container.

In the case of having just one tab open, the situation doesn't really change when disabling heartbeats: the UI stays open until the session is destroyed.

However, when we have multiple tabs open and we close some of them, the UIs will still stay opened until the session is destroyed,
potentially keeping lots of unused UIs around in memory. That means that the heartbeat mechanism helps save server memory.

Therefore, the best way is to keep the heartbeat mechanism turned on.

#### Hypothetical case: no heartbeats

Hypothetical case: what if there would be no heartbeat mechanism, but we still want to close UIs sooner? We can override `VaadinService.isUIActive()`,
keep track of requests and return false if the last request is older than, say, 15 minutes.

In case of having just one tab open, nothing changes: the UI stays open until the session is destroyed.

When multiple tabs are open and we close some of them, the UIs are closed, but only after there is a request from some of the UIs still active.
If there's no activity on the open tabs, there are no heartbeats to keep the server processing requests, and therefore the UIs
stay around until the session is destroyed by the servlet container.

## FAQ

* Q: If `closeIdleSessions` is set to `false`, will the session ever close if the user just idles?
* A: When `closeIdleSessions` is `false`, heartbeat requests will effectively keep the session active for as long as the user has at least one tab open.
* Q: Will Tomcat's session-to-disk storage help with memory consumption?
* A: No. Session-to-disk only works for passivated sessions, which doesn't happen by default. That also requires all session objects to implement `Serializable`.
* Q: How long does it then take for the session to close if there's an open browser tab but the user is doing nothing?
* A: If `closeIdleSessions` is `false` then never since heartbeat requests will effectively keep the session active.
     Otherwise, Vaadin will eventually close the UI (after the age of the UI surpasses the session timeout) which will stop the communication from the browser to the server.
     Servlet container will then close the session after the session timeout elapses. That means that the session is closed roughly after the session timeout times two.
* Q: Can UI survive session closing?
* A: No. UIs are owned by the session; closing a session closes all UIs.
* Q: Is UI equal to the browser tab?
* A: Yes - there's one UI per browser tab. However, in Vaadin 23+ when the page is reloaded, the old UI instance is thrown away and a new one is constructed,
  so in practice there's no way to reliably identify browser tab instance from the UI instance. See [Vaadin UI Scope](../vaadin-ui-scope/) for more details.
