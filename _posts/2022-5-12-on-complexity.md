---
layout: post
title: On Complexity
---

I hate complexity. I can't stand it, I can't handle it, and most importantly: I don't want to handle it.
I hate frameworks that expose me to great complexity just in order to achieve something simple,
ultimately producing stacktraces 200 lines deep into some dynamic proxy crap I'm not
possible to understand in a day. And why should I? If it's not simple then clearly the
authors have not done their homework, haven't found the right approach
and thus it's not worth my limited Earth time.

I've walked from complexity to simplicity and never fucking looked back once.

## Basic Properties of Complexity

[Complexity appeals to stupid people](https://www.youtube.com/watch?v=Cun6Uck2cYU).
Differently put, quoting Albert Einstein: Genius is making complex ideas simple,
not making simple ideas complex.

Complexity appeals to evil people which write complex code on purpose
so that they can't be fired from the company.

Complexity appeal to smug people. He wants to be the rocket scientist.
The member of an exclusive club. No way you can be exclusive when everbody can utilize a … PC.

Complexity appeal to companies. If you drank IBM's kool-aid and bought yourself
WebSphere, congratulations - now you need to purchase trainings and consultants from IBM
in order to survive with WebSphere.

It's easy to introduce complexity but hard to get rid of it.

Complexity kills maintainability. If you can't understand the code, you can't fix
it properly - you can hack it at best.

Complexity is the anti-thesis of future-proofness.
The best future-proof strategy I've seen so far is to keep the code simple and
understandable. If the code is simple, then any requirement is easy to
integrate. This is the ultimate future-proof you can get, there's nothing better.

Complexity just attracts the wrong crowd.

## Anti-patterns

This is the common property of anti-patterns: the complexity growth is exponential.
Once you need to achieve something non-trivial with MV*, the complexity skyrockets
until you either need a team or just give up and change your job industry. Shepherding
is nice I heard.

On the other hand, a well designed simple idea naturally combines with other similarly
simple ideas to achieve amazing stuff, while the complexity only climbs slowly, logarithmically at best.

## Germans: Champions of Complexity

[Why Germany has a problem with software](https://medium.com/@Terrania/why-germany-has-a-problem-with-software-a9c0a2eab699).

## 'Just add an annotation'

Not only this is very wrong, but it's also very deceptive. After all, where is 
the complexity in an innocent-looking annotation such as `@Transactional`?

The problem is that in order for the innocent-looking annotation to work, you need
to bring in 20 megabytes worth of Spring junk: the DI, the dynamic proxies, interceptors
and 1238112 of other shit.

Adding an annotation is *easy*, but the outcome does *not* result in simplicity.
On the contrary.
