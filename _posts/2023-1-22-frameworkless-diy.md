---
layout: post
title: Frameworkless/DIY
---

I love the [Frameworkless Movement](https://www.frameworklessmovement.org/), and,
most importantly, the [Frameworkless Manifesto](https://github.com/frameworkless-movement/manifesto).
The manifesto can be misunderstood; here are a bunch of thoughts to clear things up.

The movement doesn't mean that you must avoid frameworks and libraries at all times.
There is merit in the saying "standing on the shoulders of giants"; reusing a well-documented
well-tested well-written code has its merits. The movement merely advises caution:

* Some teams/architects would blindly and hastily include their favourite framework into the project,
  regardless of whether the framework has a value or not. The Movement simply exposes this
  kind of behavior as an anti-pattern.
* Every framework has a tradeoff: it needs to be taught to all team newcomers - it introduces
  a learning curve.
* The more magic the framework uses, the harder the project maintenance will be. [No Magic!](../no-magic/)
* Case in study: Spring. Spring is a massive framework with 20 megabytes worth of jar files,
  the documentation is mediocre, there is a lot of magic going on behind the scenes, it introduces
  startup overhead, yet every team seem to mindlessly include Spring into their projects from the beginning.
* The Movement simply states to use caution when including frameworks. Ask yourself: does the framework
  solve the problem and only that problem? If yes, go ahead!
* In large companies, the project often turns into an orgy of architectural approaches, design patterns, frameworks and best
  practices *even before* it actually starts to solve any of its original goals! Remember:
  *The value of a software is not the code itself but in the reasons behind the existence of that code.*

This leads me back to the DIY approach I firmly believe in:

* Start with the Java `main()` function.
* Add framework/library lazily, and only when you need it.
* Either the architecture emerges, or think about a very basic architecture upfront. Also [My Favourite Vaadin Architecture](../my-favorite-vaadin-architecture/).

I prefer to create their own solution, DIY exactly to fit my needs.
I don't like to start by including a pre-fabricated application framework,
complex and abstract enough to handle hundreds of use-cases.
I don't have hundreds of use-cases: I only have one.
I only use what you need. There lies maximum [simplicity](../on-simplicity/) which I can own, understand and can rely on.
