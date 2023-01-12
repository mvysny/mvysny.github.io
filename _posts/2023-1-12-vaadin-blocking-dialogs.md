---
layout: post
title: Vaadin And Blocking Dialogs
---

In Swing, it was possible to write a function which shows a confirm dialog, waits until the user clicked the "Yes"
or "No" button, then does something on confirmation and only then finishes. Something akin to the following:

```java
public class ConfirmDialog {

    public static void confirm() {
        int input = JOptionPane.showConfirmDialog(null, "Do you like bacon?");
        // 0=yes, 1=no, 2=cancel
        System.out.println(input);
    }
}
```

Is it possible to do such a thing in Vaadin? No it's not. But first, let's see how this actually works.

## The Event Loop

All Swing apps have exactly one event loop which processes all UI events - mouse cursor moves, mouse clicks,
etc. All the UI code is called from the event loop, and it is actually forbidden to manipulate
UI components from outside the event loop. There is one thread, dedicated to run the event loop.

If the event loop gets blocked (e.g. by `Thread.sleep(10000)`), Swing app freezes - it won't respond to any mouse clicks, the windows
won't move.

**Important note:** In this text, **Blocking** will always refer to an actual old-school Thread
that is blocked (it's sleeping/waiting for lock/etc) and can not continue its execution at the moment.


So, if a blocking dialog blocks the event, how come that it still responds to the clicks
on the "Yes"/"No" button? The secret is that `JOptionPane.showConfirmDialog()` function
runs a nested event loop which processes UI events until one of the buttons get clicked.
That way, the `JOptionPane.showConfirmDialog()` function blocks until a button is clicked.

## Blocking Dialogs in Vaadin

Consider the following Vaadin click handler:

```java
deleteButton.addClickListener(e -> {
  if (confirmDialog("Are you sure?")) {
    entity.delete()
  }
});
```

Is there an implementation of `confirmDialog()` function that would show a Vaadin Dialog and block until a button
is shown? The answer is no. The above code can not be implemented with the regular Thread-based approach.

The problem here is as follows: assume that `confirmDialog()` function blocks the Vaadin
UI thread to wait for the user to click the "Yes" or "No" button. However,
in order for the dialog to be actually drawn in the browser,
the Vaadin UI thread must finish and produce response for the browser. But Vaadin UI
thread can't finish since it's blocked in the `confirmDialog()` function.

This is a fundamental problem of all web frameworks, not just of Vaadin.

Such a code can be implemented using [Kotlin Coroutines](../vaadin-and-kotlin-coroutines/), but even then
the code will not block - the kotlin compiler will break the code down into chunks and run
them sequentially, to create an illusion of a blocking code.

## Event Loop in Vaadin

Vaadin (actually every web framework) runs *two* UI loops:

1. One event loop is a JavaScript event loop running in the browser,
2. The other "UI event queue"-like thingy runs on the server.

That's why the webpage seem to respond to mouse clicks even if the server is busy
processing request - the JavaScript event loop calls server requests asynchronously
and is not blocked until the request is processed; therefore it is available to
respond to mouse clicks.

Things are different on the server-side. There's really no event queue or event loop on the server - the servlet container
runs a bunch of threads, which are randomly picked to handle a request.
However, Vaadin must prevent multiple threads from manipulating same Vaadin components.
The reason is that all attempts to write a multi-threaded UI framework failed miserably;
all sane UI frameworks are single-threaded; or, rather, they only allow one thread to manipulate UI components at a time.

Vaadin solves this by using session locks.
If the server is blocked and busy in the Vaadin UI code, any follow-up request will get blocked server-side, on a Vaadin Session lock.
Every Vaadin Session has its own
lock, and any UI code run within that session must obtain the session lock first; this is done
automatically by the Vaadin Servlet. That prevents multiple threads from manipulating a Vaadin component at the same time.

The premise is that Vaadin components are not shared between different sessions.
But that's how 100% of Vaadin apps work. Every user has his own session, and his own set of UI components
he interacts with; and thus every user has his own Vaadin Session Lock. Requests from
different users can be (and are) processed in parallel; however requests coming from a single
user are *serialized* - a request obtains a Vaadin Session Lock and does its thing, while other requests await for the lock
to become available.
