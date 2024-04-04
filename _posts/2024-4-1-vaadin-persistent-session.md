---
layout: post
title: Vaadin - Persistent Sessions
---

To enable session persistence, set the `server.servlet.session.persistent=true` setting in your Spring Boot `application.properties`
The property value is `false` by default; however, it is overwritten by spring-devtools, which sets it to true.
It's quite convenient since you remain logged in over redeploys without any special configuration.

Advantages of enabling persistent sessions:

* The session survives server restarts and app upgrades. In theory, you can upgrade your app, and the users
  stay logged in and can continue working as if nothing happened.

Disadvantages of enabling persistent sessions:

* Everything stored in the session has to be serializable. All the basic building blocks of Vaadin are already serializable, 
  but the application developer also needs to ensure all their own classes are also serializable.
  Furthermore, third party classes that are directly or indirectly referenced from the UI state also need to be serializable.
* Some performance degradation from the extra work for each request. The degradation is small when the session is stored on disk (the default),
  but might be considerable when the session is stored to a database. The reason for that is that the size of the UI state affects
  how long it takes to process the session data and transfer it to the database. The size of a single session is typically measured in hundreds of kilobytes,
  or in some cases even megabytes, depending on how the application manages its data.
  Because the state is expressed as Java classes that might have arbitrary references to each other, there is no practical
  way of storing individual pieces separately and thus only process the parts that have actually changed.
* Every HTTP request to a Vaadin application will lead to some changes in the session. Even in trivial cases where nothing in the
  application itself changes, there are still internal things such as timestamps and sequence numbers that are updated.
  This means that it's of utmost importance that multiple requests for the same session are never handled in parallel.
* You need to make sure that sessions stored with an old version of the application will still be deserializable with a new version of the application.
  * This becomes extra tricky over Vaadin version updates since Vaadin is explicitly not guaranteeing this kind of compatibility.
* The UI state will still not be persisted in dev mode, so that only the relevant part of the session (logged-in user for example)
  can still be serialized. You need to also set Vaadin's `devmode.sessionSerialization.enabled`.
  See [Vaadin configuration properties](https://vaadin.com/docs/latest/configuration/properties) for more info.

## Fallback strategy

You can enable the persistent session and observe what’s going on with the system. In the worst case, if the session is incompatible,
there will be a deserialization exception and the session will simply be thrown away, which may be acceptable from time to time.
You can also place all of your session state into one class, say `MySession`, and then make extra sure to modify the class
in a compatible way serialization-wise.

Even better, you can prepare a `MyUserStorage` interface with two implementations: one would store stuff into session,
the other one into cookies. If you discover the need to disable the session persistency,
this will allow you to quickly switch to alternative implementation of `MyUserStorage` which uses cookies.
