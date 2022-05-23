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
That doesn't mean you should develop stuff from scratch instead (aka Not Invented Here Syndrome),
far from it: that means that you should not for example slam Spring and JPA mindlessly
into your projects, just because. Any library, framework or code will make
the project harder to understand for newcomers, and harder to maintain for everyone.
Ask these questions about anything you are about to add to your project:

* Will it make maintenance easier?
* Will it make my code more understandable for others?

## Readable Code

> If you struggle to read the code, how the hell are you meant to fix it?

You write code to express ideas to other developers; the ability of computers
to execute that code is just a side-effect.
[Why code readability is important](https://thehosk.medium.com/why-code-readability-is-important-e0c228a238a)

## Kill Your Darlings

We do stupid shit all the time. Experienced developers realize ideas that are stupid,
but still do stupid shit from time to time.

If a class is loved by you but a pain in the ass to understand by everyone else, perhaps
it's time to throw away your darling and start again.

## Undesign

Keep your design as much as possible. Don't drink the kool aid of MVC, MVP, MVVM, Hexagonal
and other whatnot architectures. From my experience, every time someone used a fancy architecture, there
was a bunch of frustrated developers trying to maintain that bullshit. If the architecture
is not making maintenance easier, it is wrong and must be removed. If the architect
disagrees, make him the sole maintainer of the app.

## Eat Your Own Dogfood

The only way humans really learn is by their own mistakes. Make a programming mistake,
live with it, maintain it, fix it, then move on. That is the only way to grow as a developer.
If you're not also the maintainer of your own code, you can not grow as a developer.

[Design like Elon Musk](https://uxdesign.cc/design-like-elon-musk-using-6-fundamental-principles-4aaab08d5e41)

Study how Tesla does things. Also read [On Effective Teams](../on-effective-teams/). Remember:
if a company smells like B there is chance it's populated by idiots. Walk away.
Be adult enough to walk away from the nonsense of idiots around you.
