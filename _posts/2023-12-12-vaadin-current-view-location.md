---
layout: post
title: Vaadin Current View or Location
---

You can use the following methods to retrieve the current view, location or the browser URL:

* `UIInternals#getActiveViewLocation()` to get currently active `Location`
* `UIInternals#getActiveRouterTargetsChain()` to get currently active route chain
  (a list of RouterLayout components with the active location component)
* `Page#fetchCurrentURL` to asynchronously fetch the URL from the browser ([documentation](https://vaadin.com/docs/latest/advanced/browser-access#getting-the-window-location-url))
* `VaadinServletRequest.getRequestURL()` as [documented on StackOverflow](https://stackoverflow.com/a/54556001/377320) but
  this one is buggy: [flow #17602](https://github.com/vaadin/flow/issues/17602)
* `UI.getCurrentView()` is a handy utility method which consults `getActiveRouterTargetsChain()`

The location is also available in `BeforeEnterObserver`'s `BeforeEnterEvent#getLocation()`
and `AfterNavigationObserver`'s `AfterNavigationEvent#getLocation()`.
