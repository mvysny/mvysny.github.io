---
layout: post
title: On thread safety
---

Many people think they understand thread programming, but unfortunately
only a handful of people really do. Unfortunately, many programmers are prone
to big ego and little skills combo: they think they can write thread-safe programs
while they produce thread-incorrect programs.

## Pitfalls

A thread-unsafe program may seem to be running correctly but will fail randomly, usually
in production and under heavy load. Such class of bugs are almost impossible to fix
since they're not reproducible in controlled environment of your development machine;
fixing these bugs require a proof of correctness of the program with respect to the *happens-before*
relationship, and only a few people are capable of doing this.

If this sounds scary, wait until you're tasked in your job to fix such a randomly occurring problem.

* Synchronization - which parts of the program may not run in parallel?
* Memory visibility - one thread writes to a variable, when will other threads see the effects?

## Java Memory Model

If you ask Java developers what was so ground-breaking about java 5,
many will say that it's either generics or annotations.
But arguably the biggest feature was the introduction of Java Memory Model (JMM),
or JSR-133 Java Memory Model and Thread. The
[Specification 1.0](https://download.oracle.com/otndocs/jcp/memory_model-1.0-pfd-spec-oth-JSpec/)
is very well written and I encourage you to read it.

Before Java 5, it was impossible to write programs in Java that used threads
and were thread-safe. There were locks and synchronization, yes, but the
memory visibility was not specified at all. It was hoped and believed that
the `synchronized{}` block triggers a memory barrier (flush of all thread caches),
but it was not actually specified anywhere in the Java specification itself,
and the actual behavior differed between different JVMs.

The best example for this is the [Java Double-Locking Idiom](https://stackoverflow.com/questions/1625118/java-double-checked-locking).
The discussion says it can't work in Java 1.4 but doesn't explain why.
To learn this, please read the "Java Concurrency in Practice" book linked below.

## UI Frameworks

All UI frameworks are single-threaded, no exceptions. What's the reason for that?
The answer is in this StackOverflow question
[Why are most UI frameworks single-threaded?](https://stackoverflow.com/questions/5544447/why-are-most-ui-frameworks-single-threaded)
and, mainly, in this excellent blog post [Multithreaded toolkits: A failed dream?](https://web.archive.org/web/20160402195655/https://community.oracle.com/blogs/kgh/2004/10/19/multithreaded-toolkits-failed-dream).
In short, multithreaded UI frameworks are extremely prone to
deadlocks since the locks would frequently be obtained in opposite order.
It would require extreme caution to write programs in such framework, and only
a handful of people would be capable of writing correct UI programs.



## Further reading

* [JSR-133 Java Memory Model and Thread Specification 1.0](https://download.oracle.com/otndocs/jcp/memory_model-1.0-pfd-spec-oth-JSpec/)
* [Java Concurrency In Practice](https://www.oreilly.com/library/view/java-concurrency-in/0321349601/)

