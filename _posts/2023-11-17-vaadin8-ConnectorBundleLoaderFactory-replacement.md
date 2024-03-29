---
layout: post
title: Vaadin 8 ConnectorBundleLoaderFactory Replacement
---

In Vaadin 8, it was possible to use `ConnectorBundleLoaderFactory` to defer loading of
certain components, to speed up the rendering of the initial view, usually the login view.
You can read more about this in the [Optimizing the widget set](https://vaadin.com/docs/v8/framework/articles/OptimizingTheWidgetSet)
Vaadin 8 documentation page. What's the replacement in Vaadin 24?

[Since Vaadin 24.1](https://github.com/vaadin/flow/releases/tag/24.1.0), it is possible to
perform similar optimizations in the webpack bundle.
See the [Production Bundle Component Loading Optimizations](https://vaadin.com/docs/latest/production/production-build#bundle-component-loading-optimizations)
for more details.

Vaadin 24 by default eager-loads components for the main route and the login route,
and lazy-loads all other components, which is exactly what we usually want.
Therefore, the recommended practice is to drop `ConnectorBundleLoaderFactory` completely when migrating from
Vaadin 8, and only introduce the bundle loading optimizations if there is a clear measurable performance
bottleneck.
