---
layout: post
title: Does Vaadin support storing session id into something else than a cookie?
---

No.

At first glance Vaadin shouldn't even care about how the session ID is tracked,
since it's the servlet container responsibility to track sessions. And it may be true
until the Push+Websockets come into play: Push+Websockets opens a new can of worms since websockets have
a session separate to the http one.

Changing the session tracking could be as easy as configuring a different `SessionTrackingMode`
(it's a javax.servlet enum with three values: COOKIE, URL and SSL):

```java
@WebListener
public class SessionTrackingModeListener implements ServletContextListener {

    @Override
    public void contextDestroyed(ServletContextEvent event) {
    }

    @Override
    public void contextInitialized(ServletContextEvent event) {
        ServletContext context = event.getServletContext();
        EnumSet<SessionTrackingMode> modes = EnumSet
                .of(SessionTrackingMode.SSL);

        context.setSessionTrackingModes(modes);
    }
}
```

However, changing it to anything else than COOKIE will make Vaadin stop working. Read on.

Alternative solution of using the URL session tracking (passing the session via an URL parameter)
as described at [Session Tracking modes in Spring security](https://springhow.com/session-tracking-modes-in-spring-security/)
doesn't work - Vaadin doesn't support URL-based session tracking and will endlessly reload the page,
ultimately giving up with "Cookies Disabled". Also, URL session tracking via HTTP is
a security issue which allows for session hijacking.

According to [Using an external Embeddable Application](https://vaadin.com/docs/latest/flow/integrations/embedding/overview/#using-an-external-embeddable-application)
you can enable the SSL-based session tracking, however according to the [SSL ID StackOverflow Question](https://stackoverflow.com/questions/2817325/retrieve-ssl-session-id-in-asp-net/2885177#2885177)
this way is unreliable and requires HTTPS anyways.
Also it doesn't seem to work according to [8039](https://github.com/vaadin/flow/issues/8039).

So, in short, Vaadin only works with cookie-based session tracking.
