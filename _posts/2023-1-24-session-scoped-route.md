---
layout: post
title: Session-Scoped Routes
---

DON'T. Session-scoping a route is **very dangerous** since if the user opens two tabs,
that route instance will be shared between the two tabs, leading to unpredictable errors.

When a new tab is open, and it shows the same route as the first tab, the route will detach
from the first tab and attach to the second tab. Remember: every tab has its own `UI` instance.
Effectively, the route detaches from the UI in first tab and attaches to the UI in the second tab.

The problem is that JavaScript components in the first tab of the browser are still
visible and responsive to events such as clicks; the clicks will be sent to the
route which is not attached to this UI anymore. That can lead to strange behavior.

I've created an example Vaadin 23.3.4-based project which demoes this issue, and observed the behavior.
When a button is clicked in the first tab, Vaadin detects that the route is no longer attached to this
UI, and assumes that the component is no longer there.
The intuitive corrective measure is to correct the client-side state by removing
the JavaScript components from the DOM tree, and that's exactly what happens.

However, the behavior may change in the future, so don't depend on it.

Scope to UI instead. Note that this can not be done properly, see [Vaadin UI/Tab Scoping](../vaadin-ui-scope/).
Also see [Cached Vaadin Routes](../cached-vaadin-routes/).
