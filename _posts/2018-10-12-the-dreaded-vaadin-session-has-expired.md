---
layout: post
title: The Dreaded "Vaadin Session has Expired"/"Cookies Disabled"
---

This happens to me every now and then. I'm developing a Vaadin app, then I switch to another one and suddenly the Vaadin session expires immediately, or Vaadin complains that the cookies are disabled. What does this bug mean and how can we work around that?

The user session is typically identified by the `JSESSIONID` cookie. If the cookie isn't there, then the session will be `null` server-side. This is actually managed by the web container such as Jetty or Tomcat, so Vaadin is quite innocent in here. Still, what can we do when this issue happens? What typically is the reason for this issue?

## Cookies Are Actually Disabled In Your Browser

Yes I know, unlikely. Still, just make sure that `Allow sites to save and read cookie data (recommended)` is enabled in your Chrome. Make sure there is no extension in your browser that's deleting the cookie (e.g. the [Clear Session](https://chrome.google.com/webstore/detail/clear-session/maejjihldgmkjlfmgpgoebepjchengka) extension).

## Conflicting Cookies

This happens especially on development machines. You tend to develop and launch different webapps, and cookies with the same name but from different context roots may stay around. Especially if there is separate `JSESSIONID` cookie for `/` and separate `JSESSIONID` cookie for an app posted to another context root:

![screen_shot_2018-10-09_at_15.26.25.png]({{ site.baseurl }}/images/chrome_conflicting_cookies.png)

To verify this, launch development tools in your Chrome (press `F12`), then go to *Application* tab, *Storage* / *Cookies* and simply delete all cookies and reload your app.

## Old Cruft

There may be old cruft in browser's cache. Make sure the DevTools are opened(`F12`); then find the *Reload* button (it's not in DevTools, it's to the left of the URL bar :-D ) and *long-click it* (yeah that's right). A menu will appear (the menu only appears when DevTools are active), from the menu just choose `Hard Reload`.

## Serve favicon From External Sources With IE 11

The problem is caused by the internally generated request for favicon. This request is generated internally by IE and uses wrong session ID (jsessionID). Server creates a new session and answers with its ID. Unfortunately the IE then uses this new session ID for other requests. You can find more information in this excellent [Stack Overflow Answer](https://stackoverflow.com/questions/40722395/vaadin-session-expired-immediately).

## Unstable Session ID

Go to DevTools, the *Network* tab. Press F5 to repopulate, then click on individual requests. If the request has a *Cookies* tab, make sure there is the `JSESSIONID` cookie and that the value doesn't change between requests. If it does, there is something very wrong with your web container.

I currently do not know what could be the cause of this; if you know the cause, please let me know so that I can update this (and give you credits!)

# Vaadin Push With WebSockets

The problem with WebSockets is that websockets have their own session which is separate from the typical http session. Websocket `Session` interface doesn't even give you the attributes map, as opposed to the standard `HttpSession`; the websocket listener instance therefore needs to store everything into its own state.

Vaadin uses the [Atmosphere](https://github.com/Atmosphere/atmosphere) library to handle async transparently; Atmosphere then [mimicks the HttpSession for websockets](https://github.com/Atmosphere/atmosphere/wiki/Enabling-HttpSession-Support).

## "Session Expired" Right After Enabling Vaadin Push with WebSockets

The important bit here is that it's apparently not possible to tie `HttpSession` to websocket `Session` just by using the JSR-356 API, so Atmosphere has hooks for Jetty (various versions since Jetty 9.1.x differs to Jetty 9.2.x and 9.3.x regarding the websocket support), Tomcat, Glassfish, etc etc. And sometimes these hooks blow. Especially on older Atmosphere (e.g. Vaadin 7 uses Atmosphere 2.2.x which is ancient. You should upgrade to Vaadin 8 and newest Atmosphere 2.4.x, it just might help).

The alternative would be to upgrade your web server (e.g. if you embed, say, Jetty 9.2.x into your app, you can simply upgrade that). For example, Karaf 4.2.1 with Jetty 9.4.x fails; Karaf 4.1.5 with Jetty 9.3.x still works with Vaadin 7's Atmosphere 2.2.9.vaadin2.

The simplest workaround is to use HTTP Long Polling, by annotating your UI with `@Push(value = PushMode.AUTOMATIC, transport = Transport.LONG_POLLING)`. That way websockets aren't used at all, just the standard http mechanism you've already been using. To compare those two, please check the [Long Polling vs WebSocket](http://mavi.logdown.com/posts/7814158-7814158-long-polling-vs-websockets) article.

# Something Else

There may always be something else that's wrong. For example I vaguely remember that push wouldn't work on WebLogic with Spring Boot. We couldn't figure out why, but everything started to work when we removed Spring.

If you discover any other cause, or a stack with particular combination of Vaadin, Atmosphere and servlet container that is known to fail, just mail me at mavi@vaadin.com and I'll update this blog post.
