---
layout: post
title: Does Vaadin 14 support session replication
---

In short, **Vaadin 14 does NOT support session replication** and **must be run with Sticky Sessions**. I'll let Leif summarize the situation:

> Flow doesn't support session replication. There are some workarounds but they come with lots of gotchas.

Longer version of the above: [Session Replication in the World of Vaadin](https://vaadin.com/blog/session-replication-in-the-world-of-vaadin).

There is a [Vaadin and Hazelcast](https://vaadin.com/learn/tutorials/hazelcast) tutorial
which describes how to enable automatic session replication in Tomcat with Hazelcast-backed
distributed session storage. However, the article doesn't refute any of the issues stemming from this approach,
as described in the "Session Replication in the World of Vaadin" article above, and
therefore this setup will suffer from issues mentioned in the article.

## Additional issues with session replication

### ConcurrentModificationException

The servlet spec doesn't specify, at what time Tomcat (or any servlet container) is
allowed to perform the session replication. From that follows that Tomcat may
start the session replication process even if there's an active request ongoing.
That means that there could be one thread manipulating UI components (the Vaadin UI thread),
and another thread concurrently serializing/reading the state of those components.
And that may lead to `ConcurrentModificationException` thrown randomly.

See [Issue #7328](https://github.com/vaadin/framework/issues/7328) for more details
and for a possible workaround.

### Session replication not serializing the state of Vaadin 14+

Vaadin 8 stores `VaadinSession` under a single Session attribute key `com.vaadin.server.VaadinSession.MyUIServlet`.
The session lists all active UIs; the UIs in turn list all attached components. Therefore,
the entire UI state is stored under one session key.

The same thing applies to Vaadin Flow as well.
Flow stores `VaadinSession` under a single Session attribute key `com.vaadin.flow.server.VaadinSession.com.vaadin.flow.server.startup.ServletDeployer`.
The session lists all active UIs; the UIs in turn list all attached components. Therefore,
the entire UI state is stored under one session key.

However, Vaadin doesn't call `session.setAttribute()` when the UI is modified.
That leads to Tomcat thinking that the session has not been changed, thus not
triggering the session replication. Quoting Leif:

> Not doing `setAttribute` is in a way a feature, since it helps users
> understand that what they try to do is "impossible" quite early rather than
> getting into the really nasty problems only later.

## Solution

You must enable sticky sessions, otherwise Vaadin will constantly lose session.

With sticky sessions you get 90% of the benefits with 10% of the efforts.
For full session replication you need to spend 90% more effort to gain rest 10%.
Usually not economically viable.

You can also optionally enable session replication. Enabling session replication
will not replicate the UI state (since Vaadin Flow doesn't call `setAttribute()`),
but it should replicate other data and should do no harm to Vaadin Flow state.

On top of that, you can use the following approaches.

### Do nothing

Rely on the fact that rarely you have an app which needs a 99,999% uptime.

Since outages originating from server crashes are rather infrequent, it's quite okay
to simply do nothing and let the users re-login, should the server crash once per year.

Planned outages, such as server upgrades, can be carried during the night, or when
the server usage is minimal.

### Store the data in the database

Disable session replication, enable sticky sessions and keep as much state as possible
in the database. That way, even if a Vaadin node dies, the user can re-login and continue
her work easily since everything is saved in the database.

### Use Vaadin Fusion

Use [Vaadin Fusion](https://vaadin.com/blog/reintroducing-vaadin-flow-and-fusion):
you'll have the entire UI in the browser, reducing backend to a set of stateless service calls.
Downside: you'll need to implement the entire UI in JavaScript or in TypeScript.
