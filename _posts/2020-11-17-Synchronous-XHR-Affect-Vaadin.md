---
layout: post
title: Getting rid of synchronous XHR - does it affect Vaadin?
---

Long time ago (in 2012) the browsers deprecated Synchronous XMLHttpRequest (XHR)
support: [Getting rid of Synchronous XHR](https://developers.google.com/web/updates/2012/01/Getting-Rid-of-Synchronous-XHRs).
Most recently, [Chrome 80 dropped Synchronous XHR in Page Dismissal handler](https://developers.google.com/web/updates/2019/12/chrome-80-deps-rems)
altogether. Do/did these changes affect Vaadin?

## The case of Vaadin 8

Vaadin 8 client-side is built with GWT and therefore uses XHR provided by GWT:
either the `com.google.gwt.xhr.client.XMLHttpRequest` class directly, or
the `RequestBuilder` class (which wraps `com.google.gwt.xhr.client.XMLHttpRequest` in
a more friendly API). Looking closer, we can see that all of
`com.google.gwt.xhr.client.XMLHttpRequest`'s `open()` methods always pass `true`
as the `async`  parameter to JavaScript's `XMLHttpRequest`. Therefore,
anyone using those classes will always use XHR in async mode.
And indeed, Vaadin's GWT code uses `RequestBuilder` from its `XhrConnection` class and
`XMLHttpRequest` in `VDragAndDropWrapper` and `FileDropTargetConnector`. So this part
of Vaadin is safe.

What about native JavaScript code? Vaadin creates new `XMLHttpRequest`
in `vaadinBootstrap.js` but then uses async mode - OK.

[Atmosphere-JavaScript](https://github.com/Atmosphere/atmosphere-javascript) client
is used for Push, which uses async (see `atmosphere.js` containing the line `ajaxRequest.open(request.method, url, true);` which indicates async mode).
However, Vaadin uses its own forked version of `atmosphere.js` named `vaadinPush.js`,
which modifies the call as follows:

```
ajaxRequest.open(request.method, url, request.async);
```

By default, the `request.async` comes from `_request.async` (which is true - OK),
however in function `_disconnect()` at line 461 it comes from `_request.closeAync`
which is false. That's the only place where Vaadin uses sync request, potentially
failing in modern browsers.

This can cause problems when trying to reinitialize the session from Vaadin, for
example to prevent the Session Fixation attack as seen at [Vaadin bug #7526](https://github.com/vaadin/framework/issues/7526); the
workaround is to use the following code (taken from Tatu's [DemoUtils](https://github.com/TatuLund/cdi-demo/blob/master/src/main/java/org/vaadin/cdidemo/util/DemoUtils.java#L9)):

```java
public class DemoUtils {
	public static void sessionFixation() {
		// Chrome 80 does not support synchronous XHR during page dismissal anymore
		// thus Push needs to be disabled during session re-initialization
		UI.getCurrent().getPushConfiguration().setPushMode(PushMode.DISABLED);
		VaadinService.reinitializeSession(VaadinService.getCurrentRequest());
		UI.getCurrent().getPushConfiguration().setPushMode(PushMode.AUTOMATIC);
	}	
}
```

## The case of Vaadin 14+

Vaadin's Flow is compiled with GWT, and therefore is using the `XMLHttpRequest` class
which is async. All of Vaadin's XHR-related code (`DefaultConnectionStateHandler.java`,
`Heartbeat.java`, `XhrConnection.java`) ultimately go through Vaadin's `Xhr`
helper class (which uses GWT's `XMLHttpRequest` class), therefore this part is okay.

However, `vaadinPush.js` uses the same modified call as Vaadin 8 does:

```
ajaxRequest.open(request.method, url, request.async);
```

Therefore, the code suffers from the same issues related to session reinitialization as the Vaadin 8 code does.
