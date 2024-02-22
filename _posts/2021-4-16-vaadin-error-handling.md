---
layout: post
title: Vaadin 14+ Error/Exception Handling
---

There are two main entrypoints of error handling in Vaadin:

* The router exception handling, triggered during the navigation phase when the view is constructed, and
* Session's ErrorHandler, triggered after the view has been rendered.

## Router Exception Handling

Described in the [Router Exception Handling Vaadin Tutorial](https://vaadin.com/docs/latest/routing/exceptions).
Triggered when the server failed to produce a view because of an exception.
In the browser there is HTTP GET request which receives an HTTP 500 Internal Server Error page
(actually oddly enough the HTTP GET returns 200 OK! Filed as [#18781](https://github.com/vaadin/flow/issues/18781)).

This handling is triggered when the Route class fails to initialize:
for example an exception is thrown in the View class constructor, or Spring/CDI/JavaEE failed to inject beans into the view.

By default, the `InternalServerError` Java class is rendered, which shows the exception stacktrace and returns HTTP 500 (actually 200 OK, see [#18781](https://github.com/vaadin/flow/issues/18781)).
The stacktrace is however shown only in development mode - it's not shown in production mode.
See the `InternalServerError` java class sources for more details. The exception stacktrace is always logged in to slf4j though.

To register a custom page, simply create a Java class, extending Vaadin Component,
implementing `HasErrorParameter<Exception>` - Vaadin will then start using this class instead
of the default `InternalServerError` one.

Example of the page in dev mode:

![error-route-dev.png]({{ site.baseurl }}/images/2021-4-16/error-route-dev.png)

Example of the page in production mode:

![error-route-prod.png]({{ site.baseurl }}/images/2021-4-16/error-route-prod.png)

## ErrorHandler

[Official Vaadin documentation](https://vaadin.com/docs/latest/advanced/custom-error-handler).
The ErrorHandler takes effect after the navigation is complete and the view is fully displayed.
It handles exceptions coming from:

* Button click listeners, or generally any events coming from components.
* Asynchronous blocks run via `UI.access()` - however beware that the `UI.getCurrent()` will
  be null in the `ErrorHandler` because of [Vaadin bug #10533](https://github.com/vaadin/flow/issues/10533).

> Note: It's not possible to use one unified solution, for example only have an `ErrorHandler` handling
the routing exceptions. The error handler is for example supposed to show a notification or a dialog detailing
the steps to take (e.g. where to report the error). However, when the view failed to initialize and
render, it might not even be possible to show a Dialog on a blank page since the JavaScript stuff
might be missing etc.

By default the ErrorHandler only logs the exception to slf4j: it **doesn't display anything**
in the UI, so the user has no feedback that there was an exception. The best way is
to display a dialog which says "We're sorry but an application error occurred: #123871".
You would generate some random number, log it along with the exception and show it in the error message.
That way, you can search for the stacktrace easily, without revealing the exception message to the user,
since the message may contain sensitive data such as username or even password.

Another example of an `ErrorHandler` implementation can be found at [Vaadin Forums: The 'Vaadin Error Handling' Question](https://vaadin.com/forum/thread/18453061/18462964).

You don't have to extend Vaadin Servlet to customize `ErrorHandler` - you can
add a session initializer which sets the `ErrorHandler` as described in the
[Vaadin SessionInitListener](../vaadin-sessioninitlistener/).
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

For quick-and-dirty experiments you can set the error handler from your route:
```java
@Route("")
public class MainView extends VerticalLayout {

    public MainView() {
        VaadinSession.getCurrent().setErrorHandler((ErrorHandler) event -> {
            // TODO implement
        });
    }
}
```

**Important:** the `UI.getCurrent()` might be `null` in ErrorHandler, and in such case
it is not possible to display a Dialog or a Notification. In such case only log the exception,
don't try to show a Dialog or a Notification.
[#10533](https://github.com/vaadin/flow/issues/10533) made sure
that `UI.getCurrent()` is non-null in more cases; please make sure you're using newest Vaadin.
In certain very specific cases `UI.getCurrent()` may still be null though; employ the null check in ErrorHandler.
Also if you encounter such case, please report it to [Vaadin bug tracker](https://github.com/vaadin/flow/issues).

### When ErrorHandler itself throws

What happens when the `ErrorHandler` itself throws? E.g.
```java
@Route("")
public class MainView extends VerticalLayout {

    public MainView() {
        VaadinSession.getCurrent().setErrorHandler((ErrorHandler) event -> {
            throw new RuntimeException("Simulated");
        });
        add(new Button("Click me", e -> {
            throw new RuntimeException("Failed!");
        }));
    }
}
```
This is where things get interesting. Vaadin 24.3.5 doesn't re-handle the exception with
the `DefaultErrorHandler` - instead it lets the exception bubble out from VaadinServlet,
which causes the servlet container to catch the exception, log it to stdout and then respond with HTTP 500 Internal Server Error.
The browser will **not display anything**. This applies both for development and for production mode.

The best way is to wrap ErrorHandler in `try{}catch` block; when it throws, log the exception
and then try to display the "Internal error #31313" dialog; when that fails, try to show a notification at least.

## JavaScript errors

Third category of errors are JavaScript errors, for example when an incorrect JavaScript code is executed:
```java
@Route("")
public class MainView extends VerticalLayout {
    public MainView() {
        add(new Button("Click me", e -> UI.getCurrent().getPage().executeJs("aksdalkdalk")));
    }
}
```

Such exceptions are not logged in server-side slf4j unfortunately; see+vote for [#17485](https://github.com/vaadin/flow/issues/17485).
Workaround is to call `then()` as follows:
```java
@Route("")
public class MainView extends VerticalLayout {
    public MainView() {
        add(new Button("Click me", e -> UI.getCurrent().getPage().executeJs("aksdalkdalk").then(
                json -> {},
                error -> { throw new RuntimeException("JS failed: " + error); }
        )));
    }
}
```
Now the exception goes through `ErrorHandler` which by default logs it to slf4j, including the class name and line number,
so you can quickly fix the JavaScript script:
```
2024-02-22 10:40:21.910 [qtp1484171695-28] ERROR com.vaadin.flow.server.DefaultErrorHandler - 
java.lang.RuntimeException: JS failed: ReferenceError: aksdalkdalk is not defined
	at com.vaadin.starter.skeleton.MainView.lambda$new$2f364bb9$2(MainView.java:20)
	at com.vaadin.flow.component.internal.PendingJavaScriptInvocation.completeExceptionally(PendingJavaScriptInvocation.java:112)
```

In development mode, the exception is logged in the JavaScript console in the browser and a red Vaadin logo starts blinking, to notify
you that there's a problem in JavaScript. Unfortunately when you call `then()` in Java, this functionality
gets disabled: [#18782](https://github.com/vaadin/flow/issues/18782).

![error-js-dev.png]({{ site.baseurl }}/images/2021-4-16/error-js-dev.png)

In production mode, the exception is logged in the JavaScript console in the browser
but the red Vaadin logo isn't shown. Unfortunately when you call `then()` in Java, this functionality
gets disabled: [#18782](https://github.com/vaadin/flow/issues/18782).

![error-js-prod.png]({{ site.baseurl }}/images/2021-4-16/error-js-prod.png)

See [Vaadin - Troubleshooting the Browser](../Vaadin-troubleshooting-browser/) for more tips
on troubleshooting JavaScript, e.g. to deobfuscate the JavaScript stacktrace.

## Bootstrap Error

When Vaadin Servlet fails to start, for example because Vite failed to compile your JavaScript files,
the following screen is shown (this screen is servlet container dependent; on Tomcat it looks like this but on Jetty
it might look differently):

![error-bootstrap.png]({{ site.baseurl }}/images/2021-4-16/error-bootstrap.png)

To reproduce, just place this file into your project into `frontend/src/my-test-element.js`:
```javascript
class MyTestElement extends LitElement {
  render() {
    return html`
      <h2>Hello ${throw}</h2>
    `;
  }
}
```

Customizable maybe by placing an `error.html` into your webapp root folder.

## Which one to override for customized error handling? Best Practices

Both. Usually the `ErrorHandler` shows a Dialog or a Notification while the error
page shows a page, but the contents of the dialog and the page can be made similar.

In all cases:

* It's always a good idea to log the exception; by default Vaadin always logs the exception.
* It's always a good idea to notify the user about the error; Vaadin's DefaultErrorHandler breaks this
  so you should implement your own ErrorHandler, but make sure that your ErrorHandler doesn't throw
  an exception while processing the original exception.
  * Remember that `UI.getCurrent()` might be null in ErrorHandler.
* JS `executeJs()`: Until [#17485](https://github.com/vaadin/flow/issues/17485) is fixed, make sure to
  call `then()`; simply throw an exception in the error closure which will cause Vaadin to call `ErrorHandler`.
