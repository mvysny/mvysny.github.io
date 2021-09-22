---
layout: post
title: Java will die
---

A bit of a clickbait title there; sure, there has been countless articles in this regard (die/won't die/blah).
I'm not interested in when or how; here I'll talk about the why. In my [Java Is Not Dead, Java Is Obsolete](../java-is-not-dead-java-is-obsolete/)
article I touched the subject from an evolutionary point of view (think of Java as a meme - it is alive only when
there are Java practitioners around. Since the stream of new practitioners shrinks every year because there are more lively memes,
the "Java" meme will shrink and die as the pool of its hosts will shrink). Here, I'll touch other topics.

Note that Java will still offer well-paid jobs in the next ~10 years, to maintain that mountain of existing code.
I'm just suggesting that the amount of new code in Java will shrink.

## Java The Language Sucks

Let me be crystal clear: Java is still far better than PHP and Perl, and 
arguably better than Ruby and Python IF AND ONLY IF your preference is a strongly typed language.
But it's **not** the best language, by far.

In my [Java VS Kotlin](../java-vs-kotlin/) article I detailed in which ways
Java is inferior to Kotlin. However, this lack of helpful APIs has severe repercussions.
Mammoth libraries like Spring had to be invented, simply because Java 7 and older lacked closures
and it was a huge pain in the ass to manage transactions in plain Java code. Compare the following
code snippets:

Java 7: just a fucking nightmare:

```java
db.beginTransaction();
try {
    // running in transaction
    db.commit();
} catch (Exception ex) {
    try{
        db.rollback();
    } catch (Exception ex2) {
        ex.addSuppressed(ex2);
    }
    throw ex;
}
```

Spring to the rescue! All you need to do is to create an interface, annotate with `@Transactional`
and pull in 20 megabytes worth of Spring shit which will manage your transactions
in a [completely unrelated codebase](../code-locality-and-ability-to-navigate/) and
will force you to use dependency injection, so that you can avoid the abomination
code above and instead write:

```java
interface Blah {
    @Transactional
    public void doStuff() {
        // woot, running in transaction.
    }
}
```

Spring is the biggest disaster that happened to Java, and I'll discuss below on why is that. Let's get back
to the code snippets.

Java 8: vast improvement over Java 7, but it's such a pain in the ass to type all of those fucking braces:

```java
Db.db(() -> {
   /* woot, running in transaction */
});
```

See? All Java solutions suck balls. It's impossible to have a nice transaction handling
in Java. To be crystal clear:
 
* Java the language and its design prevents you to have a nice transaction handling;
* Spring attempts to fix Java shortcomings and fails spectacularly.

For comparison, see the same snippet in Kotlin. It's an actual pleasure to type this:

```kotlin
db { /* woot, running in transaction */ }
```

## Spring is an anti-pattern

As demoed above, Spring was invented to circumvent Java's shortcomings, and
has since mysteriously grown to somehow become a de-facto go-to when starting Java project.
Quoting [Why Spring?](https://spring.io/why-spring):

> Spring makes programming Java quicker, easier, and safer for everybody.
> Spring’s focus on speed, simplicity, and productivity has made it the world's
> most popular Java framework.

What a load of bullshit. Let's debunk this marketing turd.
But first, a very important distinction between simplicity and easiness.
Spring allows you to manage transactions in an easy way, true, but in doing so
it brings in 20 megs worth of crap and forces you to use complex patterns like the dependency
injection. And that can hardly be perceived as "simple". Try debugging a 200-line-long
stacktrace pointing somewhere within deep bowels of Spring transaction magic, within
the spaghetti of abstractions and proxies before lecturing me on simplicity.

> Writing code easily doesn't mean at all that the resulting solution will be simple.

* So, Spring code snippets may look easy, but the iceberg below is definitely NOT simple.
* It's not "safer" in any meaning of this word: just remember how safe it is when it suddenly
  starts applying a rogue interceptor because there was a beans.xml hidden somewhere within
  a jar pulled in as a transitive dependency.
* Speed: yeah right. In applications I work on with Spring, you hit run, wait for
  30-60 seconds whilst it initialises beans, before falling over, because a runtime misconfiguration
  somewhere deep within Spring XMLs or `@Component` or whatever.
* Productivity in outputting code perhaps, but definitely not in runtime speed and maintainability.
* Quicker? In what universe? Definitely not in runtime: the CPU needs to waste tons of
  cycles going through tons of Spring abstractions and dynamically
  generated proxies in order to reach your code. Maybe quicker to write code than in plain Java 7.

Sure, I can sacrifice some of the runtime speed just fine, given that I'll receive something in return.
For example, I would never do C++ now that I have JDK and GC. But sacrificing speed
and gaining anti-pattern in return, that doesn't sound like a good business to me.

Just read [Why I hate Spring](https://samatkinson.com/why-i-hate-spring/).

So, let's rewrite the above Spring quote, shall we?

> Spring makes programming Java quicker, easier for programmers.
> Spring somehow made it to the world's most popular Java framework.

Yeah, nobody got fired because they bought from IBM, right? Spring has excellent marketing,
but that's all it is, marketing. It is an anti-pattern and has no place in
a programming language that doesn't suck. And even its usage with Java8+ is questionable.

## Dependency Injection is an anti-pattern

Right, the topic of maintainability. As your code base grows bigger, maintenance of the code becomes
far more important than development. When maintaining, you absolutely need to have
a complete control over your code base. You must be able to tell with crystal clarity
what given function does. See my [Code Locality](../code-locality-and-ability-to-navigate/)
article for more details.

What Spring and **any dependency injection framework** does is the exact and complete opposite.
When `@Inject`ing stuff, you have absolutely no control over what's going to be injected. Is it a class, or
a proxy class dynamically bytecode-created and classloaded by using the dark magic of some
class definition library? Is it serializable anymore? Immutable? POJO? Hardly!
And when you call methods on that injected something, which interceptors will be applied?
Where are they defined? How can I debug this crap, when my debugger constantly enters dynamically created methods
named `$$$Proxy$Whatever`?

What if I include a jar which suddenly reconfigures Spring to add some interceptor that I didn't wanted
in the first place? How can I reason about the correctness of the code now?

You can't. With dependency injection, it's not possible to reason about code correctness, since
you can't possibly know what else will get executed.

But not only the dependency injection itself is an anti-pattern, the **loose coupling** itself
is an antipattern. Sure, throw in an interface or two if it makes it clearer to relay your idea to
your fellow programmers (also see [literate programming](http://www.literateprogramming.com/) -
the core idea is that you're writing the code for your fellow human beings rather for the computer).
But the more abstractions and loose coupling you throw in, the harder it will be for a maintainer
to reason about the code itself.

All abstractions are enemy of a maintainable code. Use them when they bring clarity, but use them sparingly
and with caution.

## Spring is Killing Java

Spring is fucking hard to learn: the "easy" learning curve image is shattered with the first mammoth
stacktrace pointing deep into Spring bowels. Spring is also an anti-pattern. It's evil,
and the best way to program is to not to use Spring.

However, Spring has now embedded deeply into the Java community. So deeply, many consider Java and Spring
as one atomic inseparable thing. However, Spring being hard to learn and annoying to maintain, it is
effectively harming the Java community, deterring programmers to find other solutions. A parasite,
sucking on the Java host and killing its host in the process. If Java can't ditch this parasite,
it will die along with it. And, [Java being, well, Java](../java-vs-kotlin/),
I can't say it will be missed.

Java 8 is... okay I guess (since it has closures). But Java can't compete with Kotlin
and will have difficult times in the future; it makes its position much worse
by tainting itself by Spring.

Java with Spring will die for sure. Java without Spring will probably die too,
but it will take much more time.

Also, don't learn Spring - there's no point in investing gigantic amount of time
to learn a dead technology.
