---
layout: post
title: Vaadin 14+ Custom Instantiator
---

The official recommended way now is to introduce your own custom `InstantiatorFactory` which creates
Instantiators:

* If you're using Spring, simply create a class implementing the `InstantiatorFactory` interface and
  annotate it with `@Component`.
* When not using Spring, the standard `ServiceLoader` machinery is used: you create a file named
  `com.vaadin.flow.di.InstantiatorFactory` whose content is the fully qualified name of your class
  implementing the `InstantiatorFactory`. The file goes into the `/src/main/resources/META-INF/services`
  folder.

## How to implement an Instantiator

All Vaadins 14 - 23.2.0 does not implement instantiator chaining: there's no mechanism
for "your instantiator returns null and thus the `DefaultInstantiator` is used".
Therefore, you must extend the `DefaultInstantiator` to properly implement all the
default behavior yourself. Example:

```java
public class MyInstantiator extends DefaultInstantiator {
    public MyInstantiator(VaadinService service) {
        super(service);
    }

    // this one creates all @Routes
    @Override
    public <T extends HasElement> T createRouteTarget(Class<T> routeTargetType, NavigationEvent event) {
        if (routeTargetType == MainView.class) {
            // some special construction perhaps
            final MainView view = RouteSessionCache.getOrCreate(MainView.class);
            return ((T) view);
        }
        return super.createRouteTarget(routeTargetType, event);
    }
    
    // perhaps override other methods? For example SpringInstantiator overrides
    // also createComponent() (simply creates a bean), getI18NProvider() (creates a bean or falls back to super)
    // getServiceInitListeners() (looks up all beans implementing VaadinServiceInitListener.class and concats that with super)
    // and getOrCreate() - creates a bean
}
```

For a full-blown example see the `SpringInstantiator` class (present in `vaadin-spring.jar`,
simply clone the [skeleton-starter-flow-spring](https://github.com/vaadin/skeleton-starter-flow-spring)
project.

## Alternative Hacky Way

More hacky way is to introduce your own custom `VaadinService` and override either
`VaadinService.loadInstantiators()` or `VaadinService.createInstantiator()`.
Please see [Vaadin: Custom VaadinServlet and VaadinServletService](../vaadin-custom-servlet-service/)
on how to do that.
