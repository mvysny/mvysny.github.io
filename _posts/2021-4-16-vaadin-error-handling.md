---
layout: post
title: Vaadin 14+ Error Handling
---

There are two main entrypoints of error handling in Vaadin:

* The router exception handling, triggered during the navigation phase when the view is constructed, and
* Session's ErrorHandler, triggered after the view has been rendered.

## Router Exception Handling

Described in the [Router Exception Handling Vaadin Tutorial](https://vaadin.com/docs/v14/flow/routing/tutorial-routing-exception-handling).
Triggered when the server failed to produce a view because of an exception.
This is akin to performing HTTP GET and receiving an HTTP 500 Internal Server Error page.

The exception might be thrown in the View class constructor, or by Spring/CDI/JavaEE after
it failed to inject beans into the view.

By default, the `InternalServerError` Java class is rendered, which shows the exception stacktrace.
The stacktrace is however shown only in development mode - it's not shown in production mode.
See the `InternalServerError` java class sources for more details.

To register a custom page, simply create a Java class, extending Vaadin Component,
implementing `HasErrorParameter<Exception>` - Vaadin will then start using this class instead
of the default `InternalServerError` one.

## ErrorHandler

The ErrorHandler takes effect after the navigation is complete and the view is fully displayed.
It handles exceptions coming from:

* Button click listeners, or generally any events coming from components.
* Asynchronous blocks run via `UI.access()` - however beware that the `UI.getCurrent()` will
  be null in the `ErrorHandler` because of [Vaadin bug #10533](https://github.com/vaadin/flow/issues/10533).

> Note: It's not possible to use one unified solution, for example only have an `ErrorHandler` handling
the routing exceptions. The error handler is for example supposed to show a notification or a dialog detailing
the steps to take (e.g. where to report the error), however it's not possible to do
so since View has failed to initialize and render and there might be even JavaScript stuff
missing.

An example of an `ErrorHandler` implementation can be found at [Vaadin Forums: The 'Vaadin Error Handling' Question](https://vaadin.com/forum/thread/18453061/18462964).

You don't have to extend Vaadin Servlet to customize `ErrorHandler` - you can
introduce a custom VaadinServiceInitListener as described in the
[Vaadin VaadinServiceInitListener tutorial](https://vaadin.com/docs/v14/flow/advanced/tutorial-service-init-listener)
(for Spring solution see [this stackoverflow answer](https://stackoverflow.com/a/60773432/377320)).
Then:

```java
public class ApplicationServiceInitListener
        implements VaadinServiceInitListener, SessionInitListener {

    @Override
    public void serviceInit(ServiceInitEvent event) {
        event.getSource().addSessionInitListener(this);
    }

    @Override
    public void sessionInit(SessionInitEvent event) {
        event.getSession().setErrorHandler((ErrorHandler) event1 -> {
            // TODO implement
        });
    }
}
```

## Which one to override for customized error handling?

Both. Usually the `ErrorHandler` shows a Dialog or a Notification while the error
page shows a page, but the contents of the dialog and the page may be made similar.

In all cases, it's a good idea to log the exception.
