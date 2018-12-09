---
layout: post
title: Using JPAContainer with Vaadin 8's v7 compatibility Grid
---

When one tries to migrate her project to a newer version of a framework,
it usually helps if the transition is smooth and the original code works
without any modifications. This way, you can convert the code to the new
API gradually, and never encounter this _OMG-shit-doesn't-compile-everybody-blocked_ period for a long time.

Migration from Vaadin 7 to Vaadin 8 isn't as straightforward since some modifications to Java source files are required, but [the guide of migrating to Vaadin 8](https://vaadin.com/vaadin-fw8-documentation-portlet/framework/migration/migrating-to-vaadin8.html) may assist you well in converting your imports from Vaadin 7's `com.vaadin.ui.*` components to their Vaadin 8's compatibility counterparts in the `com.vaadin.v7.ui.*` package.

Unfortunately the actual problem lies with Add-ons since they depend on `com.vaadin.ui.*` components and need to be modified as well. For example all `Container`-based addons need to import `com.vaadin.v7.data.Container` instead of `com.vaadin.data.Container` - a small change indeed, but will cause the addon to malfunction in runtime.

Luckily, the change is straightforward. I have converted the JPAContainer 3.2.0 to be compatible with Vaadin 8 and thus to be compatible with the `com.vaadin.v7.ui.Grid`. This will allow you to gradually convert your Grids to v8 Grids and the old Container-based code to the `DataProvider` niceness.

EDIT: the changes have been merged to the official JPAContainer Add-on, so just use JPAContainer 4.0.0 with Vaadin 8: https://vaadin.com/directory#!addon/vaadin-jpacontainer
