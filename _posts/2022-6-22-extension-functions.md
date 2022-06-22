---
layout: post
title: Extension Functions
---

Garbage Collector is a big thing, even though it doesn't receive much spotlight in the news.
Do you remember the feeling of relief when you moved to a language with garbage collector?
Suddenly you didn't had to remember all the time who's responsible for memory allocation and freeing -
is it the caller? Or the callee? This for even the most basic things like strings.

Garbage Collector:
* Removed the need for the memory management boilerplate code
* Having lots of small classes was no longer scary since you didn't had to remember to
  free them. That directly improved the coding style since lots of small classes
  is in line with the UNIX philosophy - do one thing and do it well.

I'd even go as far as to say that garbage collectors allowed languages to go "one level higher"
by removing the constant need to deal with memory management. GC is the line between
"dumber" languages and "smarter" languages, or less productive languages and more productive
languages (extremes like Linux Kernel and Embedded aside please). It is a good abstraction
which leaks only a little, simplifies your code the right way and makes you so much more
productive.

Okay but why am I babbling about GC when the article is clearly about extension functions?
The thing is, I believe extension functions are another "level up" for languages.

## Extension Functions

I'm going to talk about Kotlin and its support for [Extension Functions](https://kotlinlang.org/docs/extensions.html).

So what's so magical about Extension Functions? After all, they simply compile to static functions
and the only difference between them and static functions is that they get auto-completed
in your IDE. Well, as it turns out, that is enough.

### The Nice-To-Have stuff

Extension Functions = adding stuff to code you don't own. You can add utility functions
to existing Vaadin components, Java objects, even Strings and ints.
For example, you can learn a list of tabs from a `Tab` Vaadin component, simply by declaring:
```kotlin
fun Tabs.getTabs(): List<Tab> = children.toList().filterIsInstance<Tab>()
```
From now on, the auto-completion of your IDE will always offer you this helpful utility function.
If your language lacks extension functions then you have no other choice but to introduce
static utility functions and document them thoroughly.

Another case: you can add functionality to JAXB-generated classes. Very hard in Java,
you basically need to reconfigure the generator and/or add templates to generate code you need.
Easy-as-pie in Kotlin, just define extension methods for those classes.

You can also add a builder pattern on top of every Vaadin component, to enable
your code to be created in a DSL fashion. See the [DSLs: explained](https://www.vaadinonkotlin.eu//dsl_explained/)
for more details; see the [Karibu-DSL](https://github.com/mvysny/karibu-dsl) project
for further examples.

The common denominator for all the features above is that without them, the code becomes
more messy, and you need to replace these features with workarounds that are complex and harder to read and maintain.
For example you can replace the DSL pattern with lots of wrapper classes with fluent API, but that's just
messy.

### The Ground-Breaking Stuff

See the [Services](https://www.vaadinonkotlin.eu//services/) chapter of VoK documentation.
The extension function mechanism essentially allows you to populate the `Services` object with
services, thus building a service repository. The IDE will auto-complete everything it
can find on the classpath, and the calls will be statically checked at compile-time.
This completely eliminates the need for the dependency injection and improves your code:

* The calls will be statically checked at compile-time. No longer you'll have to wait for
  runtime to start booting then fall over in 30 seconds because you can't inject something
  somewhere because of a misconfiguration somewhere.
* It's clear which implementation of the class you're getting. Abstractions help, but only
  to a point; going wild with abstractions is a maintenance nightmare.
* The call is easy to debug: when you step into the function then you immediately hit
  that function instead of having to go through tons of proxies and othery dynamic whatnot.
* There's no runtime magic - it ultimately compiles to static calls. They run faster, and they
  don't require a massive dependency injection framework like Spring or JavaEE.

The implications are immense. The simple mechanism of extension functions single-handedly
replaced highly complex concept of dependency injection, rendering the dependency injection
concept completely obsolete. You can even go further, replace Hibernate/JPA with
vok-orm, JDBI, JOOQ, ActiveJDBC or something equally simple, and manage transactions
not via interceptors+annotations (which is an [anti-pattern](../java-antipatterns/))
but instead with functions - see [Back To Base (Make SQL Great Again)](../back-to-base-make-sql-great-again/).

This is *big*. With the help of basic features like functions and extension functions,
you are able to remove Spring and JavaEE from your projects, making them faster to run,
faster to build, faster to deploy, faster to start and much faster to understand,
which directly translates to easier to maintain => cheaper.
