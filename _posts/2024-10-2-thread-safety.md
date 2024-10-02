---
layout: post
title: On thread safety (in JVM)
---

Many people think they understand thread programming, but unfortunately
only a handful of people really do. If you think you can write thread-safe
program, you can't.

There is no such thing as "this program is mostly thread-safe". The program either
is thread safe, or it isn't, in the same way as the program is either correct or not,
but nothing in between. You must not accept "mostly correct programs" as correct,
in the same way that you wouldn't accept that
"salary sometimes doesn't arrive to my bank account".

Rule of thumb: arguing about thread safety with a programmer that doesn't know all the
intricacies of *happens-before* relationship is a waste of time. It's like arguing
about a mathematical proof with a person that has no math background -
unless the other party accepts his incompetence in the area, the argument is a waste of time.

## Pitfalls

A thread-unsafe program may seem to be running correctly but will fail randomly, usually
in production and under heavy load. Such class of bugs are almost impossible to fix
since they're not reproducible in controlled environment of your development machine;
fixing these bugs require a proof of correctness of the program with respect to the *happens-before*
relationship, and only a few people are capable of doing this.

If this sounds scary, wait until you're tasked in your job to fix such a randomly occurring problem.
You can start randomly throwing in thread-safe collections such as `CopyOnWriteArrayList`
and things might improve, but the program is not thread-safe unless you have a proof that the program is.

The [Java Concurrency In Practice](https://www.oreilly.com/library/view/java-concurrency-in/0321349601/)
book is an excellent read on the topic, and therefore I won't try to babble much about it.
I'll mention the two most basic properties of parallelism, just for the sake of further text:

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

That's why all commonly used UI frameworks are single-threaded:
for example, Swing and AWT require that components are manipulated from one thread only:
there is one thread that runs the *event queue* and all component mutation happens
in code run in the queue. By the way the event queue technique does not apply
to UI frameworks only; for example node.js runs all JavaScript code in an event queue.

The reason for that is that event queue is simple to reason about and easy to understand.
Even in a cluster of machines, it's very common to elect a leader and have the leader
make all decision in an event queue. The reason is not just that sane programmers
are scared of threads (and rightfully so!), but also developing a parallel algoritm
is FUCKING HARD and only a handful of people can do it correctly.

Again: **If you think you can write thread-safe program, you most probably can't.**

### Web Frameworks

Web frameworks, such as Vaadin, need to process multitude of requests at the same time.
Having just one event queue for all users would slow things down to a crawl.
Therefore, Vaadin uses the mechanism of session locks which synchronize requests
coming from the same user; requests from multiple users are allowed to run in parallel.
This is a good model since Vaadin components are never shared between sessions.

Read more at [Event Loop (Session Lock) in Vaadin](../event-loop-session-lock-in-vaadin/).

## Further reading

* [JSR-133 Java Memory Model and Thread Specification 1.0](https://download.oracle.com/otndocs/jcp/memory_model-1.0-pfd-spec-oth-JSpec/)
* [Java Concurrency In Practice](https://www.oreilly.com/library/view/java-concurrency-in/0321349601/)
