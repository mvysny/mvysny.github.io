---
layout: post
title: Java Anti-Patterns
---

Most commonly used anti-patterns in Java ecosystem:

* Dependency Injection (DI): [Dependency Injection hurts ability to navigate and code readability](../code-locality-and-ability-to-navigate/)
* MVC/MVP/MVVM and other MV* garbage: [MVC/MVP/MVVM? No Thanks.](../mvc-mvp-mvvm-no-thanks/)
* JPA is *the* MOA: Mother Of All Leaky Abstractions. It will
  leak out implementation details in the most weird way. [Make SQL Great Again](../back-to-base-make-sql-great-again/)
* [Annotationmania](../post-annotation-programming/).
* Spring. [Spring is an anti-pattern](../java-will-die/). More than that - Spring is a
  *conglomeration* of all Java anti-patterns and basically embodies everything that's
  wrong with the Java world.
* OOP inheritance. OOP on itself is a good thing, but its inheritance part is just
  evil: [On OOP Inheritance](../code-locality-and-ability-to-navigate/#oop-inheritance)
* Application servers, a.k.a. JavaEE. Docker killed application servers.
  JavaEE is based on anti-patterns like DI and JPA. It's like Spring but even
  more complicated.

The right way to develop apps in Java:

* Avoid the abovementioned shit. Specifically, avoid Spring.
* Use SQL directly; use JDBI or other stuff that talks to SQL directly.
* Use [Component-Oriented programming](../mvc-mvp-mvvm-no-thanks/)
