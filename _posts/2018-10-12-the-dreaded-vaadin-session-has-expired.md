---
layout: post
title: The Dreaded "Vaadin Session has Expired"/"Cookies Disabled"
---

This happens to me every now and then. I'm developing a Vaadin app, then
I switch to another one and suddenly the Vaadin session expires immediately,
or Vaadin complains that the cookies are disabled. What does this bug mean
and how can we work around that?

The check is done by Vaadin in `VaadinServlet.ensureCookiesEnabled()`.
It basically checks that `request.getRequestedSessionId() != null`;
`request.getRequestedSessionId()` then comes directly from the servlet container.
That means that it's a misconfiguration of the servlet container and NOT Vaadin's fault;
Vaadin is just trying to be helpful and trying to detect that there's no session
even though there should be one.

The user session is typically identified by the `JSESSIONID` cookie. If the
cookie isn't there, then the session will be `null` server-side. This is
actually managed by the web container such as Jetty or Tomcat, so Vaadin
is quite innocent in here. Still, what can we do when this issue happens?
What typically is the reason for this issue?

## Cookies Are Actually Disabled In Your Browser

Yes I know, unlikely. Still, just make sure that
`Allow sites to save and read cookie data (recommended)` is enabled in your Chrome.
Make sure there is no extension in your browser that's deleting the cookie
(e.g. the [Clear Session](https://chrome.google.com/webstore/detail/clear-session/maejjihldgmkjlfmgpgoebepjchengka) extension).

* Could be that the cookie has `Secure` set to true, and you're accessing the webpage
  via `http://`
* Could be that `SameSite` is set to `Strict` and it's an AJAX request (unlikely)
* Take a look at the requests in your browser, whether the `JSESSIONID` cookie was
  received during the first request, and was then sent subsequently by the browser in
  all follow-up requests.

## Conflicting Cookies

This happens especially on development machines. You tend to develop and
launch different webapps, and cookies with the same name but from different
context roots may stay around. Especially if there is separate `JSESSIONID`
cookie for `/` and separate `JSESSIONID` cookie for an app posted to another context root:

![screen_shot_2018-10-09_at_15.26.25.png]({{ site.baseurl }}/images/chrome_conflicting_cookies.png)

To verify this, launch development tools in your Chrome (press `F12`), then
go to *Application* tab, *Storage* / *Cookies* and simply delete all cookies
and reload your app.

## Session Cookie with Empty Value

If the cookie is present in the browser but has empty value, it could be
a web server misconfiguration. Please try removing/commenting out the 
`<session-config>` element from your `web.xml`.

## Old Cruft

There may be old cruft in browser's cache. Make sure the DevTools are opened(`F12`);
then find the *Reload* button (it's not in DevTools, it's to the left of the URL bar :-D )
and *long-click it* (yeah that's right). A menu will appear (the menu only
appears when DevTools are active), from the menu just choose `Hard Reload`.

## Serve favicon From External Sources With IE 11

The problem is caused by the internally generated request for favicon.
This request is generated internally by IE and uses wrong session ID (jsessionID).
Server creates a new session and answers with its ID. Unfortunately the IE
then uses this new session ID for other requests. You can find more information
in this excellent [Stack Overflow Answer](https://stackoverflow.com/questions/40722395/vaadin-session-expired-immediately).

## Unstable Session ID

Go to DevTools, the *Network* tab. Press F5 to repopulate, then click on
individual requests. If the request has a *Cookies* tab, make sure there
is the `JSESSIONID` cookie and that the value doesn't change between requests.
If it does, there is something very wrong with your web container.

I currently do not know what could be the cause of this; if you know the
cause, please let me know so that I can update this (and give you credits!)

## Clusters

If the application is deployed in a clustered installation, then a misconfigured cluster
could redirect follow-up requests to different nodes; if the session is not replicated
the session will only reside on one node.

Try using a fixed node algorithm like IP hashing or sticky session which forces
particular user to always communicate with one node only, and see whether the situation
improves.

Alternatively try making sure that session replication is enabled and configured
properly.

## (Reverse) Proxy

Are the users accessing the application behind a proxy?
Sometimes proxies can cause problems with Vaadin applications - e.g. if the reverse
proxy rewrites paths (e.g. a Vaadin app publicly hosted at https://something.com) is
internally hosted at http://host/myapp and there's a reverse proxy unwrapping https
and rewriting those paths, from `/` to `/myapp` and back), then care must be taken
that the cookies paths are rewritten as well. For nginx take a look at [proxy_cookie_path](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_cookie_path).

## Vaadin Closing Sessions

If you're using `closeIdleSessions=true`, then lack of activity will kill the
session since heartbeats will not refresh the session. Try setting `closeIdleSessions`
to `false` temporarily, to see whether the situation improves.

## Embedding Vaadin 14 Apps In iframe

Embedding Vaadin apps in an iframe will cause the JSESSIONID cookie to be filtered
out by the browser, which means that the session can not be tracked. This is on
purpose: see the [SameSite cookies explained](https://web.dev/samesite-cookies-explained/)
for more details.

One of the solutions is to enable the JSESSIONID cookie (or all cookies) to be passed to third-party sites,
by setting the `SameSite=None` parameter to each cookie.
See [Issue In Vaadin while using in Embeded](https://vaadin.com/forum/thread/18124830/issue-in-vaadin-while-using-in-embeded)
for more details on how to configure the servlet container to add that parameter to all cookies.

However, according to the [SameSite Cookie Changes in February 2020](https://blog.chromium.org/2020/02/samesite-cookie-changes-in-february.html)
article, this only works with https (and not with http) since the "Secure" attribute is required with `SameSite=None`.

Alternatively you could try to use URL session tracking, or SSL-based session tracking,
but neither of those seem to be working with Vaadin well:
[Does Vaadin support storing session id into something else than a cookie?](../vaadin-sessionid-cookie/).

Judging from the above, the best bet is to use `SameSite=None` and enable HTTPS,
for example [HTTPS using Self-Signed Certificate in Spring Boot](https://www.baeldung.com/spring-boot-https-self-signed-certificate).
Note that this will disable http; to bring it back simply follow
the [Enable both http and https on Spring Boot](../spring-boot-enable-http-https/) guide.

Please vote for [Vaadin Issue #7736](https://github.com/vaadin/flow/issues/7736)
to have this solved and documented.

# Vaadin Push With WebSockets

The problem with WebSockets is that websockets have their own session which
is separate from the typical http session. Websocket `Session` interface
doesn't even give you the attributes map, as opposed to the standard `HttpSession`;
the websocket listener instance therefore needs to store everything into its own state.

Vaadin uses the [Atmosphere](https://github.com/Atmosphere/atmosphere) library
to handle async transparently; Atmosphere then
[mimicks the HttpSession for websockets](https://github.com/Atmosphere/atmosphere/wiki/Enabling-HttpSession-Support).

## "Session Expired" Right After Enabling Vaadin Push with WebSockets

The important bit here is that it's apparently not possible to tie `HttpSession`
to websocket `Session` just by using the JSR-356 API, so Atmosphere has hooks
for Jetty (various versions since Jetty 9.1.x differs to Jetty 9.2.x and
9.3.x regarding the websocket support), Tomcat, Glassfish, etc etc. And
sometimes these hooks blow. Especially on older Atmosphere (e.g. Vaadin 7
uses Atmosphere 2.2.x which is ancient. You should upgrade to Vaadin 8 and
newest Atmosphere 2.4.x, it just might help).

The alternative would be to upgrade your web server (e.g. if you embed,
say, Jetty 9.2.x into your app, you can simply upgrade that). For example,
Karaf 4.2.1 with Jetty 9.4.x fails; Karaf 4.1.5 with Jetty 9.3.x still
works with Vaadin 7's Atmosphere 2.2.9.vaadin2.

The simplest workaround is to use HTTP Long Polling, by annotating your UI
with `@Push(value = PushMode.AUTOMATIC, transport = Transport.LONG_POLLING)`.
That way websockets aren't used at all, just the standard http mechanism
you've already been using. To compare those two, please check the
[Long Polling vs WebSocket](../long-polling-vs-websockets/) article.

## Two Vaadin app instances in the same web container

Fredi Šarić was kind to send his experience with this topic. Fredi has
two Vaadin app instances in the same web container, both using websockets.
With his kind consent I'm posting his experiences below.

I've encountered the same problem where I would start two instances of the Vaadin app
(with the Jetty embedded server) and once I open the second app the session on the first would expire.
I've gone through all of the possible explanations you provided but none matched the description of my
problem, except the one without solution "Unstable Session ID". When I would send a
first request to the server I would have one JSESSION cookie value, and by the time the app loads it would have the other.

I'm pretty sure the reason for this is that browsers will store the cookies in a
CookieStore under the host key, hence both sites will have access to the same CookieStore and the same cookies.

When we start the second application (after the first has been started and loaded
by the browser), we will send the JSESSION cookie which is already stored in the browser.
This sessionId will not be present in the Jetty's SessionManager and it will create
a new session and put the session id in the `Set-Cookie` header of the response.
This new sessionId will then overwrite the previous one for both applications. Then on
the next heartbeat of the first application we will get a `403 session expired` response
(because heartbeats are handled differently from the normal request which would create a new session).
The  WS communication will still work up until that point since it uses a cookie
that was set when we initiated the connection. Then the vaadin app will close the
WS connection since it thinks the session has expired.

An easy solution is to disable heartbeats in the dev mode or use different cookie
names for the session in different applications, or maybe opening a second app in a different browser or an incognito mode.

# Something Else

There may always be something else that's wrong. For example I vaguely remember
that push wouldn't work on WebLogic with Spring Boot. We couldn't figure
out why, but everything started to work when we removed Spring.

If you discover any other cause, or a stack with particular combination of
Vaadin, Atmosphere and servlet container that is known to fail, just mail
me at mavi@vaadin.com and I'll update this blog post.
