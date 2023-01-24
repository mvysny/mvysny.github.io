---
layout: post
title: Session-Scoped Routes
---

DON'T. Session-scoping a route is **very dangerous** since if the user opens two tabs,
that route instance will be shared between the two tabs, leading to unpredictable errors.

When a new tab is open and the same route is navigated to, the route will detach
from the first tab and attach to the second tab.
However, the JavaScript components in the first tab of the browser will remain
visible and responsive to events such as clicks.
The clicks will be sent to the route which is not attached to this UI anymore;
The clicks may be handled or not, or it may corrupt the internal state.

Scope to UI instead. Note that this can not be done properly, see [Vaadin UI/Tab Scoping](../vaadin-ui-scope/).
Also see [Cached Vaadin Routes](../cached-vaadin-routes/).
