---
layout: post
title: Re> Thoughts After 6 years
---

Awesome blogpost by Chris Kiehl:
[Software development topics I've changed my mind on after 6 years in the industry](https://chriskiehl.com/article/thoughts-after-6-years).
Excellent thoughts, and I agree with almost everything. A couple of thoughts from me below.

**Java isn't that terrible of a language.**

True, [but it isn't that great either](../java-will-die/).

**Functional programming is another tool, not a panacea.**

True, but it's far better than AOP/Interceptors/Annotationmania/Spring bullshit
usually employed by Java practitioners instead. See my thoughts in the link above.

**YAGNI, SOLID, DRY. In that order.**

YAGNI: 100% agree.

SOLID: coined by Uncle Bob with whom I disagree on almost everything:

* The 'L' in Liskov substitution principle is useless since you shouldn't use inheritance anyway; see
  [OOP Inheritance](../code-locality-and-ability-to-navigate/)
* the 'I' in interface segregation principle is refuted in [Fallacy of future-proof](../fallacy-of-future-proof/);
* the 'D' - I don't agree since crazy abstraction will affect maintainability.

DRY: sure, but not zealously.

**90% – maybe 93% – of project managers, could probably disappear tomorrow to either no effect or a net gain in efficiency.**

Haha, music to my ears :-D Just make sure [you have a team of A+ players](../on-effective-teams/), then you can drop almost all
managers.
