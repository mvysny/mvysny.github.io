---
layout: post
title: Java Anti-Patterns
---

Have you ever found yourself using certain library or approach, but instead of
feeling empowered by it, you constantly have to fight back, go against the flow and bend
the rules in order to achieve things? Congratulations, you've found your
personal anti-pattern.

Some anti-patterns are generic in nature: they just don't work with programmers in general.
Some anti-patterns are very subjective: some people love rx and async while
others hate it and proclaim it anti-pattern. Some things work for complexity-loving
Germans while not for the simplicity-loving me. Just wanted to clarify this beforehand,
before another holy war is started.

My personal list of anti-patterns in Java ecosystem:

* Dependency Injection (DI): [Dependency Injection hurts ability to navigate and code readability](../code-locality-and-ability-to-navigate/)
* MVC/MVP/MVVM and other MV* garbage: [MVC/MVP/MVVM? No Thanks.](../mvc-mvp-mvvm-no-thanks/)
* JPA is *the* MOA: Mother Of All Leaky Abstractions. It will
  leak out implementation details in the most weird way. [Make SQL Great Again](../back-to-base-make-sql-great-again/)
* [Annotationmania](../post-annotation-programming/). I'd much rather write some code
  than figure out a magic combination of annotations to make something happen.
* Spring. [Spring is an anti-pattern](../java-will-die/). More than that - Spring is a
  *conglomeration* of all Java anti-patterns and basically embodies everything that's
  wrong with the Java world.
* OOP inheritance. OOP on itself is a good thing, but its inheritance part is just
  evil: [On OOP Inheritance](../code-locality-and-ability-to-navigate/#oop-inheritance)
* Application servers, a.k.a. JavaEE. Docker killed application servers.
  JavaEE is based on anti-patterns like DI and JPA. It's like Spring but even
  more complicated.

The right way to develop apps in Java:

* Avoid the abovementioned shit. Specifically, avoid both Spring and JavaEE. You
  can run your app just fine on Jetty or Tomcat.
* Learn and use Docker. You can build and run a production image anywhere: both
  on your dev machine and on production.
* Use SQL directly; use JDBI or other stuff that talks to SQL directly.
* Use [Component-Oriented programming](../mvc-mvp-mvvm-no-thanks/)
* Use SOA: wrap your data with services then call them from your UI code.

## My preferred Vaadin architecture

The best way that worked for me was a simple SOA architecture,
no Spring, no JPA, no DI. Only use what you really need.

If you use SQL database, plain JDBC is a pain in the ass. Use [jdbi-orm](https://gitlab.com/mvysny/jdbi-orm),
or maybe [ActiveJDBC](https://javalite.io/activejdbc) even though I hated that you need a Maven plugin for that.
Don't use JPA.

Don't use DI in any form or shape (no Spring, no Guice, no Dagger). Instead, create a static repository of services:

```java
public static class Services {
  public static LoginService getLoginService() {}
  public static ThatService getThatService() {}
}
```

For stateful services you can use JVM singletons. For session-scoped services you can
make the getter look up the service from Vaadin session.

Use [Karibu-Testing](https://github.com/mvysny/karibu-testing/) to test your app server-side.
Either:

* don't mock anything: use your services as-is and assert on the database contents, using
an in-memory db like H2 or a throwaway db-in-docker; maybe rolling back transactions at the end of each test
* If you can't do that, e.g. because you're using REST server, you can fake the REST server.
* If you can't do that, set fake implementations of services before every test.

Don't drink the kool aid of MVC, MVP, MVVM, Hexagonal
and other crap. Have a simple layer of services, then make your components call those
services directly. Simple SOA.

Don't use JavaEE nor Spring-Boot: JavaEE is dead and an anti-pattern, Spring is anti-pattern (and should be dead):

* [Use an embedded Jetty](https://github.com/mvysny/vaadin-embedded-jetty-gradle)
* Or develop in Intellij with Tomcat, then [deploy into the Tomcat Docker image](../Launch-your-Vaadin-on-Kotlin-app-quickly-in-cloud/)

For Vaadin-related suggestions: Vaadin actually can be used in a simple way, without Spring, Hibernate, JavaEE
and other crap. Additional rules apply:

* (If you must use DI) Don't ever mark Vaadin components as beans otherwise you may get strange parent-child-relationship-broken issues
* Don't use PolymerTemplates nor LitTemplates: they don't work with Karibu-Testing and
  the abstraction leaks in multiple ways:
   * see [Karibu-Testing+PolymerTemplates](https://github.com/mvysny/karibu-testing/tree/master/karibu-testing-v10#polymer-templates--lit-templates)
   * `@Id`-mapped elements within a vaadin-dialog template are not properly initialized. (TODO github ticket link)
* Use Component-oriented approach over MVP
* Avoid EventBus unless your app is highly asynchronous in nature. Otherwise it will be hard
  for you to reason about code flow (since it's hard/impossible to tell which observers will react to given event).
* Use TestBench for happy-flow testing, use Karibu-Testing for everything else
* Create a reusable set of Java layouts such as GreyDetailsPane; then create a view called Sampler which
  demoes all layouts and proper ways to use components. This creates a go-to posterboy recipes
  for new developers to follow.

