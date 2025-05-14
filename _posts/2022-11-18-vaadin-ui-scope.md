---
layout: post
title: Vaadin UI Scope, Browser Tab Scope, Session Scope
---

[Vaadin supports many additional scopes](https://vaadin.com/docs/latest/flow/integrations/spring/scopes)
(think objects that are bound to e.g. session; when the session terminates, the objects are garbage-collected).

## Session Scope

Most common is the session scope. You usually store the currently logged in user to
the current session, to have access to the user at all times. You use `VaadinSession.getCurrent().setAttribute(User.class, user)`
to store the current user, and `VaadinSession.getCurrent().getAttribute(User.class)` to retrieve it.

When using push with websockets, things get trickier. The thing is that websockets have their
own session which is different from the http session, and many frameworks do not offer
any unifying session to make same objects available both from websocket requests and from
regular http requests. For example Spring's `@UIScope` suffers from this dichotomy.

However, Vaadin's `VaadinSession` is correctly shared between http and websockets, so
you'll get the same data regardless of how Vaadin app is accessed. The same goes for `@VaadinSessionScope`
annotation which is provided by the vaadin-spring.jar.

**Important**: [don't make Vaadin components session-scoped!](../session-scoped-route/).

## UI Scope

The UI Scope scopes objects to the current UI instance. You either annotate your routes
and beans with `@VaadinUIScope`, or you use `ComponentUtil.setData(UI.getCurrent(), class, value)`
to store/retrieve the values.

Beware that Vaadin 8 UI scope is vastly different to Vaadin 23 UI scope:

* Vaadin 8 UI scope would survive page reloads (when `@PreserveOnRefresh` was used) and navigation,
  making it a true tab scope.
* [Vaadin 23 UI scope](https://vaadin.com/docs/latest/flow/integrations/spring/scopes#uiscope) is different:
  the UI gets thrown away and recreated when the page is reloaded, and this can not be prevented,
  not even with `@PreserveOnRefresh`. The only thing that's preserved are layouts annotated with `@PreserveOnRefresh`
  and routes annotated with `@VaadinUIScope`.

On top of that, Vaadin 23 UI scope may not survive browser back/forward button nor user typing a new URL manually.

Non-Spring projects: If you are happy with the UI scope limitations as stated above, and you want to
turn a couple of your routes into UI-scoped, please see [Cached Vaadin Routes](../cached-vaadin-routes/)
for more details.

## Tab Scope

This is what Vaadin 8 UI used to be scoped to. This scope scopes to a browser tab
and survives page reloads, navigation, browser back/forward button nor user typing a new URL manually.

For Spring, there is a solution, it just requires
Spring and a shitload of annotations, namely:

1. The Route must be annotated with `@SpringComponent`, `@RouteScope` and `@RouteScopeOwner(MainLayout.class)`
2. The `MainLayout` must be annotated with `@PreserveOnRefresh`. If your `MainLayout` is not available at all times (e.g. during login),
   just create a technical layout extending a full-screen div, which wraps all routes and layouts and is `@PreserveOnRefresh`, then scope
   to this technical layout.

This feature is available since Vaadin 23.

There are small bugs:

* if the user re-enters the URL manually and presses Enter, the scope is gone and MainLayout+Route gets re-created with a new scope: [issue #21139](https://github.com/vaadin/flow/issues/21139)
  * Same thing when running `document.location = url` javascript command.
  * 21139 is now fixed; to preserve MainLayout instances set `@PreserveOnRefresh.partialMatch` to `true`
* When that happens, Flow will start behaving erratically and will fail with `java.lang.IllegalStateException: Unregistered node was not found based on its id. The tree is most likely corrupted.`.
   The solution is to detach the route in MainLayout manually, via `content.getElement().removeFromTree()`:

```java
@PreserveOnRefresh
public class MainLayout extends VerticalLayout implements RouterLayout {
    // ...
    @Override
    public void showRouterLayoutContent(HasElement content) {
        content.getElement().removeFromTree();
        RouterLayout.super.showRouterLayoutContent(content);
    }
}
```

Another problem is that the scope isn't available in the UI init listener -
it requires fetching window name via `ExtendedClientDetails` which are fetched asynchronously.
The [Issue #13468](https://github.com/vaadin/flow/issues/13468) contains a request to have window name available eagerly,
so that tab scope is available in the UI init listener.

For a non-Spring project there is a prototype app [vaadin-tab-scope-example](https://github.com/mvysny/vaadin-tab-scope-example)
but the implementation is a bit fragile: see & vote for [Issue #13468](https://github.com/vaadin/flow/issues/13468).
