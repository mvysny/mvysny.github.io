---
layout: post
title: Post-Annotation Programming
---

The absence of any sane way to parse XML in Android (the [official Google-endorsed way of parsing XMLs](https://developer.android.com/training/basics/network-ops/xml)
is ridiculous, low-level, hard to use and error-prone, as are [all other aspects of programming with Android](../Android-SDK-Why-literally-any-other-platform-is-better/))
pushed me to write yet-another-XML-parsing-library
called [konsume-xml](https://gitlab.com/mvysny/konsume-xml), and that made me realize just how horrible and evil annotations
are.

I generally hate writing libraries - it's not an easy task to get API right, test all corner cases and write a documentation
that makes sense. I always strive to use existing libraries first.
And so I tried to use [simple-xml](http://simple.sourceforge.net/download/stream/doc/tutorial/tutorial.php).
It kept spamming me with non-sensical error messages, however the worst thing is that at some point I was unable to use
multiple `@ElementList`-annotated fields - Simple XML always failed somewhere deep inside of its mysterious bowels when it
tried to parse two consecutive element lists such as `<a><b/><b/><b/>...<c/><c/><c/></a>`.
I've tried
numerous combinations of `@ElementList(this)`, `@Element(that)` to no avail. Ultimately I gave up and walked away with
the following lessons:

* The annotated code looks simple, but when it fails, the error comes with a stacktrace deep into a huge unfamiliar code base.
* The compiler can't help you much - it can't prevent you from creating meaningless annotation combinations
* Parsing a bit different XML may require strikingly large effort and a completely different set of annotations.
* Writing a for loop is easy with an actual programming language, but next-to-impossible with annotations

Instead of a set of annotations, I wrote a set of functions that you call at any time when you need to parse an element
or an attribute. True, now you need to write the XML-to-object mapping code yourself, but it's not that much of a work,
and now you have total control of

* what functions you call, to parse XML elements,
* when you call those functions
* how will your objects look like; you can
* debug easily since it's just code
* it's a code you've written so it's familiar and explicit,
* it's easy to modify
* it's maintainable

TODO example side-by-side?

As I embarked to replace annotations with simple function calls, everything started to simplify:

* Instead of JPA and its horrible idea of managed entities I've used [vok-orm](https://github.com/mvysny/vok-orm)
* Instead of injections I've used extension functions to create a type-safe [repository of services](http://www.vaadinonkotlin.eu/services.html).
* Instead of `@Transactional` interceptor I simply used `db {}` method ([vok-orm](https://github.com/mvysny/vok-orm))
* Since I've managed to get rid of all [evil annotations](https://dzone.com/articles/evil-annotations) I had no further need
  of huge annotation interpreters - containers such as JavaEE or Spring.
* I got rid of JAX-RS annotations and simply used [Javalin](https://javalin.io/)

[Simplicity is the prerequisite not only for reliability](https://medium.com/production-ready/simplicity-a-prerequisite-for-reliability-8d000f8d18df)
but also for maintainability. I'll even go as far as say that:

> It's impossible to write an easily maintainable software with annotation-based frameworks. Magic is the enemy of maintainability.

The [The case against annotations](https://blog.softwaremill.com/the-case-against-annotations-4b2fb170ed67) article
hints the existence of an post-annotation world behind the the valley of annotations - maybe it's time to let the
evil annotations rest and [move beyond](http://samatkinson.com/why-i-hate-spring/). I think Java world needs to evolve
toward world that lacks annotations and uses as few inheritence as possible. The post-annotation world where the functionality
is attached not by the means of annotations, but by adding tiny pieces of code directly into appropriate places
  
I've built the [Vaadin-on-Kotlin](http://vaadinonkotlin.eu/)
framework based on these ideas - please check it out and experience the joy of writing software that is once again maintainable.
