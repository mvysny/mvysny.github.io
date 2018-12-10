---
layout: post
title: Tutorial - Writing Vaadin apps in Kotlin Part 5
---

Let's discuss the most useful cases for the extension methods. First use-case:
extension methods allow to apply themselves only selectively. For example, the
following method only applies to a list of Person:

```kotlin
fun Iterable<Person>.averageAge(): Double = map { it.age }.filterNotNull().average()
```

No longer it is necessary to create classes which only perform summarization
functionality over a collection of objects - you can now attach that functionality
directly to a `Iterable` or a `Collection`.

Second use-case is even more interesting. Let's create a `Session` object as follows:

```kotlin
object Session {
    operator fun get(key: String): Any? = VaadinSession.getCurrent().getAttribute(key)
    operator fun set(key: String, value: Any?) = VaadinSession.getCurrent().setAttribute(key, value)
}
```

This will allow to store stuff into the Session as follows: `Session["key"] = value`.
But this is not the interesting part. The interesting part comes here:

```kotlin
fun login(person: Person) {
    Session["user"] = person
}
fun logout() {
    Session["user"] = null
}
val Session.loggedInUser: Person? get()= Session["user"] as Person?
```

Yes, yes, login/logout, standard stuff, what's your point? The main point is that
we extended the `Session` with the `loggedInUser` property. And by "we" I mean
that anyone can do this - another class, another jar file, another module.
Consider this: lots of jars, lots of modules contributing stuff to the central
Session class. You can use that stuff, as long as those jars are on your classpath.
This is not about pluggability, this is about modularity and about discoverability
of services. Your IDE will auto-discover all services and will provide you a neat
list in the form of auto-completion on the Session object. And in some applications,
this approach may even replace simple injections - that is, injections with one
implementation and with no interceptors. But - don't we strive for all injections
to be simple?

Interesting times we live in ;) And that's all folks, thank you for reading
these ramblings ;) If you wish to see these ideas in practice, please check
out the [Vaadin on Kotlin](https://github.com/mvysny/vaadin-on-kotlin) project on
Github - it includes the production-ready `db{}` function, Grid integration
for rendering of your DB tables in your page and more. Check out the sample project as well.
