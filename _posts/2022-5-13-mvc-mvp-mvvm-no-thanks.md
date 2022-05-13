---
layout: post
title: MVC/MVP/MVVM? No Thanks.
---

The Model-View-Controller, Model-View-Presenter and related patterns are very
popular with page-oriented frameworks such as Ruby on Rails, Groovy on Grails
and Python Django. There is typically a lot of things going on in the page, and
the MVC pattern helps keeping the code separated into smaller, more easily
digestable packages.

However, all of those patterns have the following fundamental flaws:

* You can split your code three way (M V and C) but not any further, unless you
  go sub-controllers, sub-models and sub-views. That way lies insanity.
* It is fucking complicated. You need to read shitload of [MVP](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller)
  articles and books (which often contradict each other), just to be able to
  maintain a MVP codebase.
* The page-oriented frameworks are effectively dead for anything more complex than
  a static blogpost site. They're old and can't hold a candle
  against React or component frameworks. They force you to produce complex code
  for even simple pages.
* They're never enough. Often you find yourself going against the MVC ideas (or bending
  the rules just to achieve something), then be told that MVP solves that (but it's more complex);
  once MVP is not enough then MVVM solves everything, at the cost of being even more complex.

This is the common property of anti-patterns: the [complexity](../on-complexity/) growth is exponential.

## Component-Oriented Programming

If you ever used a component-oriented framework such as Java's Swing or Vaadin,
then you're familiar with components such as buttons and checkboxes. The 

Components are a much smaller unit of reuse than pages, employing
MVC with Component-oriented frameworks does not make that much sense: for
example it will usually leave you with nearly empty Views. We thus believe that
using MVC does more harm than good since it adds unnecessary complexity.
Therefore this tutorial will not use MVC.

