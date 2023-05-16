---
layout: post
title: My personal favourite general programming language
---

Over the years I've come up with a set of rules for any programming language that
really suit my programming style. It goes without saying that every person has their
own preferences and/or tasks: you may prefer dynamically-typed languages, or you may have to develop
a Linux kernel driver, and then you should not follow these rules.
I would personally miss the benefits of a statically-typed language such as 100% auto-completion
and automatic type checking, however you may not miss those things and instead appreciate other things offered by dynamically-typed
languages. Please take this article as a highly subjective personalized rambling of one old man.

My subjective rules are as follows:

* Has GC and a sound memory model, which rules out C, C++ and Rust.
* Has exceptions and doesn't suggest to use error codes which [rules out Go](../golang-sucks/)
* Everything is a pointer (except for primitive types) and things are passed by reference. No `int* (*f) (char*, int*)` stuff. 
* Statically-typed language, which rules out Ruby, Python, JavaScript and Groovy.
* Has [extension functions](../extension-functions/) which rules out Java.
* Focused on simplicity and maintainability instead of fancy features, which rules out Scala.

I found the following programming languages that survived the sieve above:

* Kotlin on JVM
* [Kotlin Multiplatform Native](https://kotlinlang.org/docs/native-overview.html)
* [Dart](https://dart.dev/); my thoughts [on Dart](../on-dart/)
* C#

My choice is therefore Kotlin and JVM. It implies that I have to have an IDE with the Kotlin plugin,
in order to develop Kotlin-based apps in a sane way, and to take advantage of the auto-completion.
I personally am happy to live with that, and I do not perceive that as a major disadvantage. There are free+OSS IDEs that work really well for me
(Intellij IDEA Community); there are others that may work equally well (Eclipse, Visual Studio Code),
and I don't mind paying for tools that make me productive
(Intellij IDEA Ultimate).

Does it mean that all other languages are objectively worse? Not at all. All that is meant
by this blog is that Kotlin on JVM suits my personal preferences the best. Your personal
preferences may differ, and your personal experience may differ.
I have a fondness towards developers that sworn to never take another at Java
(or at the statically-typed languages in general) because they went through the hell that is
JavaEE, Spring and the "Java Enterprise".
I recognize and admire the simplicity present in the world of Python and Ruby.
Yet I also have to accept that I'm just too old and my mind isn't flexible enough
to learn new APIs and the new world, without the aid if having IDE aided by static types.
On top of that, I have seen the simplicity in the world of JVM. It's a pity that simplicity is often
not practiced by the Java folk. To be extra clear: simplicity is about leaving everything out until
you need it, and not about 'simply having this and this annotation in your code', which is
the narrative of the Spring money-making enterprise lobby.
The annotation-based approach looks simple until you realize it's backed by a massive annotation processor,
which is impossible to debug and understand, and thus impossible to maintain. But I digress.

Why not C#? It looks like an awesome language, however my deep knowledge of the JVM
ecosystem pretty much ties me to the JVM. I would have to throw the majority of that knowledge
away and start from scratch, which is almost impossible in my age. But, you never know;
I was able to pick up bits of Dart rather quickly after all :) I'll probably stick
to JVM in this life, because of the knowledge I amassed over the decades of working with Java.

## On VMs, GC, error codes and exceptions

I grew up developing simple apps and text-based games on the good old Commodore 64 my
dad smuggled from Germany. Back in the days of 1988, Czechoslovakia was occupied by Russia,
which means that all western technical wonders pretty much came through the Germany route.
Of course the Russian doctrine fought hard to suppress the fact that West is much more technologically
advanced; that meant that all trade with the West was firmly supervised and expensive.
Which pretty much meant that things had to be smuggled from Germany, which
meant that the customs needed to be bribed. It's not that dangerous as it sounds since
everyone was in the same game. But thankfully that's a distant past now.

Growing on C64 BASIC and the Assembly language meant trying out random stuff from a photocopied German handbook,
which meant that the computer would frequently brick or crash, which meant that the
program was gone and I had to start from scratch. Compared to that, having a modern OS
which doesn't crash, and a SSD drive where you can save things in an instant, is a night-and-day
kind of difference. On top of that, having a programming environment which protects
you from dumb mistakes, both yours and those of your colleagues, is nothing short of
a minor miracle. This is something I frequently forget about (it's easy to forget about
the good things after all) and I have to learn to constantly remind myself of. 
The talk is of course about the JVM and the idea that the program runs in an environment
that protects you from common mistakes, by disallowing access to just any part of your program's
memory. I learned to love a language that doesn't have pointers.

On top of that, I learned to love a language which doesn't have error codes and does have exceptions.
Those two features single-handedly remove 40% of lines in your program, removing the need of

```
int result = call_something();
if (result != 0) {
  return -1;
}
```

on every call to every function. On top of *that*, GC removed all the need to constantly
having to free up memory, just because a function dared to return something more complex than an `int`.

The wonders of GC and exceptions form a barrier which I'm personally not willing to cross back,
now that I've seen the development speedup of being aided by GC and a VM.

## On sound memory model

Prior Java 5, it was not possible to develop a multi-threaded software that was correct.
Java 5 brought the wonder of JMM and a well-defined happens-before relationship which
is a small wonder in itself too.

That being said, async programming and coroutines lessened the need to do thread programming
somewhat; it's actually a good thing, given that multi-threaded programming is very hard to do correctly.

## Extensions functions

See [Extension functions](../extension-functions/).
