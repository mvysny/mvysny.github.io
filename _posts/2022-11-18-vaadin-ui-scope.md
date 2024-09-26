---
layout: post
title: Vaadin UI Scope/Browser Tab Scope
---

Vaadin doesn't support proper Tab scoping out-of-the-box. Consider a scenario where
you would cache a route for a tab. Such a cache is very hard to implement at the moment:

* Tying the information to `ComponentUtil.setData(UI.getCurrent())` doesn't survive F5.
* Having a `@PreserveOnRefresh`-annotated parent layout survives F5 but
  it doesn't survive browser back/forward button nor user typing a new URL manually.

See [Issue #13468](https://github.com/vaadin/flow/issues/13468) for more details.

If you are happy with the UI scope limitations as stated above, and you want to
turn a couple of your routes into UI-scoped, please see [Cached Vaadin Routes](../cached-vaadin-routes/)
for more details.

## No But Actually Yes

Actually I just realized that there is a solution for tab scoping, it just requires
Spring and a shitload of annotations, namely:

1. The Route must be annotated with `@SpringComponent`, `@RouteScope` and `@RouteScopeOwner(MainLayout.class)` 
2. The `MainLayout` must be annotated with `@PreserveOnRefresh`

This is available since Vaadin 23.

There are small bugs:

1. if the user re-enters the URL manually and presses Enter, the scope
is gone and MainLayout+Route gets re-created with a new scope.
2. When that happens, Flow will start behaving erratically and will fail with `java.lang.IllegalStateException: Unregistered node was not found based on its id. The tree is most likely corrupted.`.
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
