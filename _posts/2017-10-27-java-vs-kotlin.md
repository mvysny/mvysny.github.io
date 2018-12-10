---
layout: post
title: Java VS Kotlin
---

In his blog about [comparing Kotlin and Java features](https://blog.simon-wirtz.de/kotlin-features-miss-java/), Simon was IMHO too kind. Creating a prototype of some app in Kotlin, then converting the code painfully to Java (simply because Java is company's lingua franca) and watching it inflate and obfuscate itself is quite an eye-opening experience.

Of course doing something in C/Assembly/Ruby quickly resets my world view and makes me appreciate Java more - simply because it has GC and is statically-typed. But still, here's my list of things where Kotlin shines.

# Kotlin: The Good

## Streams

After I have grown used to Kotlin streams, it always makes me shiver with horror when writing this in Java:
```java
final String commaSeparatedNames = StreamSupport.stream(tabSheet.spliterator(), false)
  .map(it -> tabSheet.getTab(it).getCaption()).collect(Collectors.joining(", "))
```
The `TabSheet` is a Vaadin component which itself is an `Iterable<Component>`, providing its tab components in the iterator. But Java offers no direct way of creating stream out of Iterable! On the other hand, Kotlin adds handy extension methods to `Iterable`, and thus we can simply type:
```kotlin
val commaSeparatedNames: String = tabSheet.map { tabSheet.getTab(it).caption } .joinToString()
```
* No retarded `StreamSupport` for converting `Iterable` to streams for whatever obscure reason,
* `joinToString()` provided out-of-the-box as a handy utility method, as opposed to the horrible `Collectors.joining()` (which is a method with three generic types, yeah, that's truly the simplest way).

We can even fix `TabSheet` and add missing `tabs` iterable:
```kotlin
val TabSheet.tabs: Iterable<TabSheet.Tab> get() = (0 until componentCount).map { getTab(it) }
```
Now we can simplify the statement to
```kotlin
tabSheet.tabs.map { it.caption } .joinToString()
```
Short, concise, but most importantly, easy to understand and opaque in meaning. No syntax noise as opposed to `StreamSupport.stream(tabSheet.spliterator(), false)` - what the fuck is that `StreamSupport` deus-ex-machina? How the hell can I even figure *that* out without Stack Overflow?

## Optional

I've seen Optional masturbation which made me want to rip my eyeballs out. One of the less horrible examples:
```java
optionalString=Optional.ofNullable(optionalTest.getNullString());
optionalString.flatMap(s->something).ifPresent(s->{System.out.println(s.toString());}).orElseThrow(()->new RuntimeException("something"));
```
Not only you have polluted your API with `Optional<String>`, but you've just created a fluent debugging and readability nightmare. Good job.

In Kotlin, `optionalTest` is already of type `String?`, so the compiler will disallow us to call `.toString()` on it. All that's needed is this:
```kotlin
val s = optionalString ?: throw RuntimeException("something")
println(s.toString())  // now s is String so we can call functions on that.
```

Nullable types and language constructs instead of retarded `Optional` class FTW.

## Extension methods

A.K.A adding stuff to code you don't own. The `TabSheet` example above shows the `tabs` extension property, which is *auto-completed* by the IDE. In Java world, you typically do
```java
class TabSheets {
  public static Iterable<TabSheet.Tab> tabs(TabSheet ts) { ... }
}
```
which is hardly discoverable by the IDE.

Extension methods are immensely helpful. It is amazing how underestimated this amazing feature is. You can for example establish a `Session` class and make all modules add stuff there, e.g. security module could add the `Session.loggedInUser` property etc. Goodbye dependency injection (and all that DI-based crap like Spring and JavaEE), you won't be missed.

Another case: adding functionality to JAXB-generated classes. Very hard in Java, easy-as-pie in Kotlin, just define extension methods for those classes.

Another case: creating a server-side testing framework for Vaadin. Often you don't need to test with the browser - just creating the component graph server-side and asserting on that is enough. Adding an extension method named $ (yeah Java can have a method named $, that's actually a good thing :-D ) to Vaadin `Component` allows you to do a simple search for descendants of that component, for example:
```Kotlin
expect(0) { mainLayout.$(Grid::class.java, caption("Service List")).dataProvider.size(Query())
```
In Java there's no way to do that, so you either create a static method in some class (undiscoverable), or you wrap all Vaadin components in a wrapper class and add the $ method to that wrapper class (lot of work, unnecessary wrappings). And thus Java forces me once again to create a complex solution for a simple problem.

# Kotlin: The Bad

## The invoke operator

Not everything is shiny in Kotlin world. You can get wild with operator overloads; for example the following code, which may be used with the Gradle build system:
```kotlin
class DependencyBuilder
class DependenciesBuilder {
    operator fun String.invoke(block: DependencyBuilder.() -> Unit) { DependencyBuilder().block() }
}
fun dependency(block: DependenciesBuilder.()->Unit) = DependenciesBuilder().block()
```
This will allow you to write the following code:
```kotlin
dependency {
    "compile" { println("oookay what the hell?") }
}
```
That's too magicky for my tastes. Luckily you can always Ctrl+Click in Intellij to learn what the hell the code does: in this case you need to click the curly brace after `"compile"` to navigate to that `invoke` fun. Of course you need to understand what Kotlin syntax is in effect, but at least you *are able* to navigate, as opposed to Ruby and other dynamic garbage.

## The complex guys

The power of Kotlin can be used for Evil, thus creating undecypherable constructs. Just consult [Exposed](https://github.com/JetBrains/Exposed) source code for more details.

# The End

I thus believe Simon is a bit wrong in his statement:

> It’s just a selection of things, which will hopefully find their way into the Java language soon.

No they will not - the Java guys focus on completeness instead of simplicity. This is a difference of mindset and this is very important, since the typical way of Java guys to solve a problem is to solve all related problems as well, creating useless complex mother-of-frameworks in the process.

Also, Java guys can not undo things they've done. For example, now that Java 8 has the horrible stream API, that API can not go away or be made simpler. The same goes for `Optional`.

Java's mindset of complexity is what will ultimately kill Java. Put yourself into shoes of an 18-year old, trying to pick a language to learn. Why bother with Java? It's the Cobol of today. I don't know what next generation of programmers will program in, but I bet it won't be Java.

Kotlin is for people who appreciate simplicity. And having an expressive language is far more important than people do realize.
