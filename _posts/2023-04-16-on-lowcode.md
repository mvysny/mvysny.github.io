---
layout: post
title: On Low Code and BDD
---

The more you try to avoid coding, the more ridiculous the result will be. Prime examples: no-code, BDD.

* What low-code promises: anyone can create apps
* What low-code delivers: a new class of developers that specialize for particular low-code platform.

If that sounds like a contradiction, it's because it is. There's no way around coding. The promise
here is that managers would be able to take specs and write apps using low-code.
The hard fact is that managers can't program, and they start hiring programmers on their first
hurdle.

## The case of BDD

Take BDD as an example. The promise is to be able to write a story like the following, in plain English, by non-technical people:

```
Given a stock of symbol STK1 and a threshold of 10.0
When the stock is traded at 5.0
Then the alert status should be OFF
```

(Example taken from [JBehave](https://jbehave.org/)). Looks good at first sight until you realize
that there is no interpreter that understands the English language and the sentences written in it.
In other words, the set of acceptable sentences is pretty much 'set' in stone. Any
slight variation (e.g. `Then the alert status should be DISABLED`) result in a failed test.

A set of tokens, where even a slight variation gives an error, is pretty much what a programming
language is. This language in particular is horribly inexpressive:
no `for` loops, no `if` statements, no variables, nothing.
The Robot Framework realized this; instead of giving up on the idea they
took a bold step towards complete madness and [implemented for loops](https://robocorp.com/docs/languages-and-frameworks/robot-framework/for-loops)
over this english-sentence-mini-programming-"language".

Non-technical folk are generally not able to handle the for loops. That means that a programmer
will be hired, to write testing programs, using a ridiculous programming "language".

## Java Annotationmania

Now that I think about it: lots of Java frameworks tend to try to replace code with annotations,
promising 'convention-over-configuration' but actually delivering a horrible mini-programming-"language"
written in annotations. More on the topic at [post-annotation programming](../post-annotation-programming/).
