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
  can run your apps on Jetty or Tomcat.
* Use SQL directly; use JDBI or other stuff that talks to SQL directly.
* Use [Component-Oriented programming](../mvc-mvp-mvvm-no-thanks/)
* Use SOA: wrap your data with services then call them from your UI code.
