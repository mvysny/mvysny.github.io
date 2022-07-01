---
layout: post
title: On Complexity
---

I hate complexity. I can't stand it, I can't handle it, and most importantly: I don't want to handle it.
I hate frameworks that expose me to great complexity just in order to achieve something simple,
ultimately producing stacktraces 200 lines deep into some dynamic proxy crap I'm not
possible to understand in a day. And why should I? If the library is not simple, then clearly the
authors have not done their homework, haven't found the right approach or abstraction,
or they don't care about simplicity, and thus it's not worth my limited Earth time.

I've walked away from complexity and never looked back once.

## Basic Properties of Complexity

[Complexity appeals to stupid people](https://www.youtube.com/watch?v=Cun6Uck2cYU).
Differently put, quoting Albert Einstein: Genius is making complex ideas simple,
not making simple ideas complex.

Complexity appeals to evil people which write complex code on purpose
so that they can't be fired from the company.

Complexity appeal to smug people. He wants to be the rocket scientist.
The member of an exclusive club. Complex problems for the *real* engineers.
Wizards in their ivory towers, mumbling arcane incantations. The "Emperor Is Naked"-kind of guys
are natural enemies of a wizard.

Complexity appeal to companies. If you drank IBM's kool-aid and bought yourself
WebSphere, congratulations - now you need to purchase trainings and consultants from IBM
in order to survive with WebSphere.

> E.W.Dijkstra: "Simplicity is a great virtue but it requires hard work to
> achieve it and education to appreciate it. And to make matters worse: complexity sells better."

It's easy to introduce complexity but hard to get rid of it.

Complexity kills maintainability. If you can't understand the code, you can't fix
it properly - you can hack it at best.

Complexity is the anti-thesis of future-proofness.
The best future-proof strategy I've seen so far is to keep the code simple and
understandable. If the code is simple, then any requirement is easy to
integrate. This is the ultimate future-proof you can get, there's nothing better.

> Ray Ozzie: Complexity kills. It sucks the life out of developers, it makes products difficult to plan, build, and test.

Complexity just attracts the wrong crowd.

## Germans: Champions of Complexity

[Why Germany has a problem with software](https://medium.com/@Terrania/why-germany-has-a-problem-with-software-a9c0a2eab699).

A German will never choose the easiest way if he can help it.

## Anti-patterns

This is the common property of anti-patterns: the complexity growth is exponential.
Once you need to achieve something non-trivial with [MV*](../mvc-mvp-mvvm-no-thanks/), the complexity skyrockets
until you either need a team or just give up and change your job industry. Shepherding
is nice I heard.

On the other hand, a well designed simple idea naturally combines with other similarly
simple ideas to achieve amazing stuff, while the complexity only climbs slowly, logarithmically at best.

### 'Just add an annotation'

Not only this is very wrong, but it's also very deceptive. After all, what's
so complex about an innocent-looking annotation such as `@Transactional`?

The problem is that in order for the innocent-looking annotation to work, you need
the following:

1. An annotation processor which implements the transaction management itself;
2. You need to call the annotation processor for every class+method annotated with `@Transactional`

Behind the scenes, Spring will bring in 20 megabytes worth of Spring junk, as a
dependency of the transaction annotation processor: the DI, the dynamic proxies, interceptors
and other shit. Spring then needs to add interceptors to your annotated class or interface
in runtime, which means either proxies (if it's an interface that's annotated) or
create a dynamic class which extends your class and intercepts all method calls.
This is not simple - there is a lot of dark JVM magic going on behind the scenes.

If something goes wrong, you may have to debug the annotation
processor which is hidden deep within all of that junk; you'll jump through dynamically-loaded
classes with weird names such as `Proxy$0`.

Adding an annotation is *easy*, but the outcome does *not* result in simplicity.

It's much simpler to have a function `db()` which runs given `Runnable` in transaction.
The syntax for that sucks in Java though, you need to use Kotlin.

### Throw DI Away

To make my point crystal-clear: I am *not* implying that you should use JavaEE instead
of Spring. Far from it. Both are based on dependency injection which is
an [anti-pattern](../java-antipatterns/) and thus garbage. To be crystal-clear:
anything based on DI (Guice, Dagger) is inherently an anti-pattern and thus should
be avoided. Use [Extension Functions](../extension-functions/) instead; if your
language doesn't support those then it's time to switch.

## Advantages Of Complexity

The problem with simplicity is that simple things are easy to understand, which may not necessarily be a good thing:

- People like to prove their worth by suggesting changes. It's hard to suggest changes to something
  you have no idea about, therefore most suggestions will target simple things.
  Want to please your manager? Leave some labels
  untranslated or with wrong fonts. They will spot it out, point it out, suggest a change and
  walk away from the meeting feeling happy and fulfilled.
- Simple things provoke endless discussions (suggestions about changes).
- [bike shedding](https://en.wiktionary.org/wiki/bikeshedding).
- You can create a simple problem as a decoy, to get those monkeys off your back (see the "label" idea above).
- Turning simple things complex, people will look at you with respect (see the "Wizard" note above).

> Side note: In traditional large companies, lots of energy is wasted on bike shedding and politics bickering.
  Such company can not evolve and can not compete with faster competitors; survival strategy is
  to buy competitors out, sue them or otherwise eliminate them (if you're big enough).
