---
layout: post
title: MVC/MVP/MVVM? No Thanks.
---

The Model-View-Controller, Model-View-Presenter and related patterns are very
popular with page-oriented frameworks such as Ruby on Rails, Groovy on Grails
and Python Django. There is typically a lot of things going on in the page, and
the MVC pattern helps keeping the code separated into smaller, more easily
digestable packages.

However, all of those MVx patterns have the following fundamental flaws:

* You get exactly three buckets: M, V and C. You *can* subdivide into sub-models, sub-views
  and sub-controllers, but that quickly degenerates into a mess of controllers and views calling
  each other (more on this below). There's no clean way to grow past three pieces.
* It is fucking complicated. You need to read shitload of [MVP](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93presenter)
  articles and books (which often contradict each other), just to be able to
  maintain a MVP codebase.
* Page-oriented frameworks are a poor fit for rich, stateful UIs: React and
  component-oriented frameworks handle interactivity far more naturally. On top of that,
  MVx makes you produce complex code even for simple pages.
* They're never enough. Often you find yourself going against the MVC ideas (or bending
  the rules just to achieve something), then be told that MVP solves that (but it's more complex);
  once MVP is not enough then MVVM solves everything, at the cost of being even more complex.

This is the common property of anti-patterns: the [complexity](../on-complexity/) growth is exponential.

## Never a perfect fit

The [Difference Between MVC, MVP and MVVM](https://www.geeksforgeeks.org/difference-between-mvc-mvp-and-mvvm-architecture-pattern-in-android/)
article rates the three patterns like this:

* MVC: *"Ideal for small scale projects only."*
* MVP: *"Ideal for simple and complex applications."*
* MVVM: *"Not ideal for small scale projects."*

Take that with a grain of salt. MVC and MVP are nearly the same pattern — MVP just makes
the view passive and inserts a presenter to mediate every access to the model — yet the
table cheerfully rates one "small scale only" and the other "fits everything". When two
near-identical patterns earn opposite verdicts, the verdicts are guesswork; and MVP's
"fits everything" is exactly the vague, means-all-things claim that (see below) leaves
nobody agreeing what MVP even is.

Either way the takeaway is the same: there is no safe default. MVC caps out early, MVVM is
overkill for anything small, and MVP is a moving target. So the architecture can not grow
with your needs: you pick one, outgrow it, and rework the entire codebase into the next.
Different architects will have different opinions: time will be wasted with endless ivory
tower discussions while the maintenance team struggles to fix tickets, digging through
endless abstractions.

## Refuting MVx 'pros'

Pro: One great thing about MVP is that you could essentially swap out your view
implementation to something completely different.

The problem with that is while that
looks good on paper, it's often impossible in practice. It's as "easy" as swapping your
SQL database for a different one. Doesn't happen that often, does it?

Pro: It makes it possible to replace Vaadin with a different UI framework without rewriting everything.

Yeah, well, see above.

Pro: It makes it possible to reuse the UI logic in both desktop and mobile UIs.

Not at all. The mobile screens are much smaller, which means that the UX is completely different.
Not only that, but often the mobile app serves a different purpose. You would not
do your tax forms on your mobile phone, right? Tops, you could check that a tax form has been processed.

Pro: It makes it easier to test the UI logic without setting up the entire runtime
environment or simulating user interactions (clicks, text inputs, etc.).

In my experience not worth the added complexity. Plus, often there's a framework which
allows you to do that without having to abstract everything, e.g. [Karibu-Testing](https://github.com/mvysny/karibu-testing/) for
Vaadin. The point is that you shouldn't screw up your codebase in the name of testability,
since maintainability is going to suffer.

## MVx cons

MVP is a vague pattern that can be interpreted and used in many different ways.
There is no MVP Vaadin framework: it’s recommended for the MVP framework to be
implemented from scratch in every project that uses them. Well, good luck with that.

For each view in the application, you have to create and maintain at least three separate Java files:
the view interface, the presenter class and the view class. You might have to change all
of them just to make a small addition to a form.
Also the comms between those. Adds complexity.

Pure MVP implementations do not allow the presenter to be aware of the existence of Vaadin.
This makes some things more complicated than they need to be.

Presenter unit tests are easy to write, but are often very technical in nature:
you first write the presenter, then you write a unit test that systematically goes through every
line in the presenter. The result is a test that is several times bigger
than the original class, took a lot of time and money to implement,
has great testing coverage and provides little real value.

The role of the presenter and its relation to the view is not fully understood.
This becomes especially clear when a large view is split up into subviews and subpresenters.
The end result is often a mess of presenters and views calling each other or asking each other to call each other.

Architects often discourage the use of MVC and MVP for the MVVM, but that's not widely used yet
(read: nobody fucking knows what MVVM should do. It's an "architectural proposal"
which means it's useless in real world, but it makes a good academical paper I guess).

Also see [Is MVP a Best Practice?](https://vaadin.com/blog/is-mvp-a-best-practice-).

## MVx: Conclusion

It's an anti-pattern, fuck it. If you're using a component-oriented framework
such as Vaadin, there's something better: [Components](../component-oriented-programming/).
