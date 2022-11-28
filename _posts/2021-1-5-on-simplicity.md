---
layout: post
title: On Simplicity
---

[Complexity appeals to stupid people](../on-complexity/), and it's pointless
to argue with stupid people.

> Venkat Desireddy: Be adult enough to walk away from the nonsense of idiots around you.

With that cleared out, let's focus on simplicity.

## On Simplicity

> Elon Musk: “The best part is no part. The best process is no process. It weighs nothing. Costs nothing. Can’t go wrong.”

Applied to software, you use frameworks and libraries only when absolutely necessary.
That does *not* imply the Not Invented Here (that you should develop things in-house instead
of using a third-party library), far from it: you definitely *should* reuse effort put in available libraries.
However, you should only use what you need, and not for example slam Spring and JPA mindlessly
into your projects by default, just because. Any library, framework or code added to your project will make
the project harder to understand for newcomers, and harder to maintain for everyone.
Ask these questions about anything you are about to add to your project:

* Will it make maintenance easier?
* Will it make my code more understandable for others?

This is the idea behind the [Frameworkless Movenent](https://www.frameworklessmovement.org/)
which contains more awesome links, for example the [8 lines of code](https://www.infoq.com/presentations/8-lines-code-refactoring/)
amazing presentation.

## Readable Code

> If you struggle to read the code, how the hell are you meant to fix it?

You write code to express ideas to other developers; the ability of computers
to execute that code is just a side effect.
[Why code readability is important](https://thehosk.medium.com/why-code-readability-is-important-e0c228a238a)

## Kill Your Darlings

We do stupid shit all the time. Experienced developers simply learned to know which ideas lead to stupid things,
but still do stupid shit from time to time.

If a class is loved by you but a pain in the ass to understand by everyone else, perhaps
it's time to throw away your darling and start again.

## Undesign

Keep your design as simple as possible. Don't drink the kool aid of MVC, MVP, MVVM, Hexagonal Architecture
and other crap.
From my experience, behind every fancy architecture there
is a bunch of frustrated developers trying to maintain that bullshit. If the architecture
is not making maintenance easier, it is wrong and must be removed. If the architect
disagrees, make him the sole maintainer of the app. Let him live with it. Let him
[eat his own dogfood](../eat-your-own-dogfood/).

## Design Like Elon Musk

[Design like Elon Musk](https://uxdesign.cc/design-like-elon-musk-using-6-fundamental-principles-4aaab08d5e41)

Study how Tesla does things. Also read [On Effective Teams](../on-effective-teams/). Remember:
if a company smells like B there is chance it's populated by idiots. Walk away.
Be adult enough to walk away from the nonsense of idiots around you.
