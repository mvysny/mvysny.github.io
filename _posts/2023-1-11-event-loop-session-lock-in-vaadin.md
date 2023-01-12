---
layout: post
title: Event Loop (Session Lock) in Vaadin
---

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
