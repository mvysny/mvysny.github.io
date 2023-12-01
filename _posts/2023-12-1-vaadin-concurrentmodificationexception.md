---
layout: post
title: Vaadin and ConcurrentModificationException
---

You're having `ConcurrentModificationException`s that occur randomly and can not be
reproduced at will. The stacktrace doesn't help much since it simply points into `VerticalLayout.add()` or similar, and everything looks okay.
This kind of exception happens when a Vaadin code is accessed from a background thread.
But it's definitely not easy to figure out, exactly who is calling Vaadin code without `ui.access()`.

## Session Replication

The exception may be thrown when you have session replication turned on. Unfortunately,
that's bit of a problem.

The servlet spec lacks the precise specification of at what time Tomcat (or any servlet container) is
allowed to perform the session replication. Therefore, Tomcat is free to
start the session replication process anytime, even if there's an active request ongoing.
That means that the following situation is entirely possible:
there could be one thread manipulating UI components (the Vaadin UI thread),
and another thread concurrently serializing/reading the state of those components.
And that may lead to `ConcurrentModificationException` thrown randomly.

See [Issue #7328](https://github.com/vaadin/framework/issues/7328) for more details
and for a possible workaround; the workaround was found not to be perfect,
for reasons that haven't been investigated yet.

## Enabling Exception Logging

Vaadin calls `VaadinSession.checkHasLock()` periodically, to check whether the UI
code is accessed from a Vaadin UI thread (a thread which [holds the Vaadin Session lock](../event-loop-session-lock-in-vaadin/)).
By default, `checkHasLock()` only calls `assert` which in production does nothing,
since you would have to enable asserts via `-ea` in your JVM, but no-one does that in production.

Starting with Vaadin 24.4, you can reconfigure `checkHasLock()` to do something different:
either log a warning message *including the stacktrace* if the lock is not held, or
fail with an exception. The 'log' variant will be immensely useful since it will contain
the full stacktrace; from that you will be able to spot exactly which thread calls Vaadin
UI code without obtaining the lock first. See [Vaadin Flow #15776](https://github.com/vaadin/flow/issues/15776)
for more details.
