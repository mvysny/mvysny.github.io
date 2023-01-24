---
layout: post
title: Vaadin UI Scope/Browser Tab Scope
---

Vaadin doesn't support proper UI scoping out-of-the-box. Consider a scenario where
you would cache a route for a tab. Such a cache is very hard to implement at the moment:

* Tying the information to `ComponentUtil.setData(UI.getCurrent())` doesn't survive F5.
* Having a `@PreserveOnRefresh`-annotated parent layout survives F5 but
  it doesn't survive browser back/forward button nor user typing a new URL manually.

See [Issue #13468](https://github.com/vaadin/flow/issues/13468) for more details.

If you are happy with the UI scope limitations as stated above, and you want to
turn couple of your routes into UI-scoped, please see [Cached Vaadin Routes](../cached-vaadin-routes/)
for more details.
