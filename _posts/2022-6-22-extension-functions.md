---
layout: post
title: Extension Functions
---

Garbage Collector is a big thing, even though it doesn't receive much spotlight in the news.
Do you remember the feeling of relief when you moved to a language with garbage collector?
Suddenly you didn't had to remember all the time who's responsible for memory allocation and freeing -
is it the caller? Or the callee? This for even the most basic things like strings.

Garbage Collector:
* Removed the need for the memory management boilerplate code
* Having lots of small classes was no longer scary since you didn't had to remember to
  free them. That directly improved the coding style since lots of small classes
  is in line with the UNIX philosophy - do one thing and do it well.

I'd even go as far as to say that garbage collectors allowed languages to go "one level higher"
by removing the constant need to deal with memory management. GC is the line between
"dumber" languages and "smarter" languages, or less productive languages and more productive
languages (extremes like Linux Kernel and Embedded aside please). It is a good abstraction
which leaks only a little, simplifies your code the right way and makes you so much more
productive.

Okay but why am I babbling about GC when the article is clearly about extension functions?
The thing is, I believe extension functions are another "level up" for languages.

## Extension Functions

I'm going to talk about Kotlin and its support for [Extension Functions](https://kotlinlang.org/docs/extensions.html).
