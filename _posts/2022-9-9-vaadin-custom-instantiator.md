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

## Alternative Hacky Way

More hacky way is to introduce your own custom `VaadinService` and override either
`VaadinService.loadInstantiators()` or `VaadinService.createInstantiator()`.
Please see [Vaadin: Custom VaadinServlet and VaadinServletService](../vaadin-custom-servlet-service/)
on how to do that.
