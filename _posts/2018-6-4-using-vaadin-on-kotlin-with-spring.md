---
layout: post
title: Using Vaadin-on-Kotlin with Spring
---

While I don't recommend using Spring because of simplicity reasons, there
are valid reasons to have Spring support. For example when building UI for
an already existing Spring-based backend, or when gradually converting a
legacy application to VoK.

## Use global service registry

The simplest way to go is to build a global service registry: a plain class
with static getters which retrieve particular services from Spring (e.g. using
`ApplicationContext.getBean()` call). To obtain the `ApplicationContext` just
inject it into your `UI` and then simply call `UI.getCurrent().getAppContext().getBean()`.
This approach has the following advantage over field injection approach:

1. You can call service getters from anywhere you want; you don't have to
   trouble yourself with constant worry whether the view/component in question
   was constructed by Spring and has everything injected properly. This fixes
   a lot of `UninitializedPropertyAccessException`s you might have.
2. You can even build the registry as a set of extension methods to a `Services`
   object as recommended by Vaadin-on-Kotlin. Please read
   [Writing Services](http://www.vaadinonkotlin.eu/services.html) for more info.
3. You don't have to worry whether the injected Service Proxy is serializable
   and whether it will be reinjected upon deserialization (it won't, a constant
   cause of `NullPointerException`s).

## Injections

The harder way is to use injections. If you decide to go this way, your views
must be constructed by Spring so that they have all dependencies injected properly.
To achieve this, you must not use the `autoViewProvider` + `@AutoView` VoK mechanism
(since AutoViewProvider constructs views simply by calling their constructors).
Instead you must use `SpringViewProvider` and annotate your views with `@SpringView`.

Often you build custom components which depend on Spring services and use
injection to obtain service instances. Such components must also be instantiated
with Spring otherwise no injection is performed. To achieve this with the
Kotlin DSL just write something like this:

```
fun (@VaadinDsl HasComponents).appToolbar(block: (@VaadinDsl AppToolbar).() -> Unit = {}) = init(UI.getCurrent().appContext.getBean(AppToolbar::class.java), block)
```
