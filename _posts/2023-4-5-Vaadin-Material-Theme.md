---
layout: post
title: Vaadin And Material Theme
---

Vaadin does [officially support the Material theme](https://vaadin.com/docs/latest/styling/legacy/material-theme),
however it's not actively developed and not recommended for new projects.
The situation differs for Vaadin 14 and Vaadin 23+.

## Vaadin 14

1. The [Custom Themes](https://vaadin.com/docs/v14/flow/styling/custom-theme) is the recommended way
   to develop your app with, but it's not supported with Material theme: see [Limitations](https://vaadin.com/docs/v14/flow/styling/custom-theme/#limitations).
2. The Badge styling works properly.

## Vaadin 23

1. The [Application Themes](https://vaadin.com/docs/latest/styling/application-theme) is the recommended way
   to develop your app with, but that's not supported with the Material theme: [Vaadin #15746](https://github.com/vaadin/flow/issues/15746).
2. You can't use the [LumoUtility.java class](https://vaadin.com/docs/latest/styling/lumo/utility-classes) since
   LumoUtility.java only works with custom themes: [Vaadin #13716](https://github.com/vaadin/flow/issues/13716).
3. For the same reason [Badge](https://vaadin.com/docs/latest/components/badge)
   doesn't work: [#4916](https://github.com/vaadin/flow-components/issues/4916).