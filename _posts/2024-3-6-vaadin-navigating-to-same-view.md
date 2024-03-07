---
layout: post
title: Vaadin - The Corner-Case of Navigating To The Same View
---

The [Vaadin Navigation Lifecycle](https://vaadin.com/docs/latest/routing/lifecycle)
documents in great depth what happens when there's a navigation from one view to another.
However, it leaves out one important corner-case: what exactly happens when there's a navigation
from a view onto itself. There's a [Request for clarification 3265](https://github.com/vaadin/docs/issues/3265),
but let's go through what actually happens in Vaadin 24.3.6.

Say we have the following view:
```java
@Route("")
public class MainView extends VerticalLayout implements BeforeLeaveObserver, BeforeEnterObserver, AfterNavigationObserver {

    public MainView() {
        System.out.println("init()");
        add(new RouterLink("Main", MainView.class));
    }

    @Override
    public void afterNavigation(AfterNavigationEvent event) {
        System.out.println("afterNavigation()");
    }

    @Override
    public void beforeEnter(BeforeEnterEvent event) {
        System.out.println("beforeEnter()");
    }

    @Override
    public void beforeLeave(BeforeLeaveEvent event) {
        System.out.println("beforeLeave()");
    }

    @Override
    protected void onAttach(AttachEvent attachEvent) {
        super.onAttach(attachEvent);
        System.out.println("onAttach()");
    }

    @Override
    protected void onDetach(DetachEvent detachEvent) {
        System.out.println("onDetach()");
        super.onDetach(detachEvent);
    }
}
```

* If you navigate to MainView from some other view, then the predictable chain is printed: `init()`, `beforeEnter()`, `onAttach()`, `afterNavigation()`.
* If you navigate to some other view from MainView, then the predictable chain is printed: `beforeLeave()`, `onDetach()`.
* However, if you click the "Main" RouterLink, then something strange happens: `beforeLeave()`, `beforeEnter()`, `afterNavigation()`.

Looks like the MainView is not re-created (the constructor is not called), and also it's not detached nor re-attached;
but it looks like the Navigation Lifecycle is triggered and goes through all of its steps. It's not clear whether this is just
an implementation detail or whether this is intended; see+vote for the request for clarification above.

This opens a very important topic: it's possible for `beforeEnter()`, `afterNavigation()` and `beforeLeave()` to run multiple times
on the very same instance of the Java object. If you're for example doing some initialization in `afterNavigation()`, make
sure it's de-inited in `beforeLeave()` otherwise the initialization may run again, duplicating things in your view.

## PreserveOnRefresh

What happens when `@PreserveOnRefresh` enters the scene? We know that UI is thrown away on page reload but MainView itself should be preserved.

* If you navigate to MainView from some other view, then the predictable chain is printed: `init()`, `beforeEnter()`, `onAttach()`, `afterNavigation()`.
* If you navigate to some other view from MainView, then the predictable chain is printed: `beforeLeave()`, `onDetach()`.
* If you click the "Main" RouterLink, then the same thing happens as above: `beforeLeave()`, `beforeEnter()`, `afterNavigation()`.

This gets called on page reload (`F5`): `onDetach()`, `beforeEnter()`, `onAttach()` and `afterNavigation()`.
This is pretty much expected: the view instance should be preserved, that's why view's constructor is
not called. The UI is also recreated as [documented at Vaadin's doc](https://vaadin.com/docs/latest/advanced/preserving-state-on-refresh),
so the view needs to be detached from the old UI and attached to the new UI,
that's why the `onDetach()` and `onAttach()` are called. However, note that `beforeLeave()` was **not called**.
This is where shit hits the fan. I'm not sure whether this is intended or a bug, but you can't rely on it anymore.

What's even crazier, now when you start mashing that "Main" link NOTHING happens: none of the navigation lifecycle methods get called.
This is definitely unexpected and definitely requires an explanation.

## Conclusion

When you want your view to refresh on self-navigation, initialize (and de-initialize) in
`afterNavigation()` and hope that your view doesn't use PreserveOnRefresh AND the user reloaded the page:

* `@PreserveOnRefresh` disables navigation lifecycle after refresh as seen above;
* `@PreserveOnRefresh` causes Vaadin to fail to call `beforeLeave()` on page reload,
   so you can't rely on de-initializing your view there.
