---
layout: post
title: Are Threads Obsolete With Vaadin Apps?
---

Let me start by saying that threading model (or, rather, *single* thread model) provides the most *simplistic* programming paradigm - the imperative synchronous sequential programming. It is easy to see [what the code is doing](../code-locality-and-ability-to-navigate/), it is easy to debug, and it is easy to reason about (unless you throw in dynamic proxies, injected interfaces with runtime implementation lookup strategy and other "goodies" of the DI) - that's why having such paradigm is generally desirable. Of course that holds only when you have *one* thread. Adding threads with no defined communication restrictions overthrows this simplicity and creates the most *complex* programming paradigm.

A new async hype of using Rx/Promises/Actors/whatever is high right now. `node.js` guys preach the new, event-based model to be superior to the current threading model. This marketing makes sense since they only have one thread (or, rather, one event queue), thus they can't do otherwise. However, compared to the simplicity of the single thread model, any code using async techniques will be order of magnitude harder to understand and debug:

* callback-based programming introduces Callback Hell/Pyramid of Doom; implementing error-handling on top of that turns the pyramid into unmaintainable mess.
* Rx/Promises introduces combinators such as `thenCompose`, `thenAccept` and others. While native to functional programming, it is quite foreign to imperative programming style and introduces a completely new programming vocabulary instead of reusing language constructs such as `if`, `try{}catch` etc. This vocabulary also tend to differ from library to library; also the API-to-code ratio is quite high and creates high verbosity (Java programmers could tell stories ;)
* Misusing Actors to create complex app tends to create a mesh of messages which is impossible to debug or reason about; any bug is hard to spot, reason about its origin and fix.

True, these techniques *do* offer a programming paradigm which is easier to use than "here, have multiple threads and do whatever you like" - that's a ticket to hell (unless you use 1-master-n-slave threads paradigm). But they produce code far more complex than the single thread model does.

## Simplicity Is Discarded Too Easily

With Vaadin, you only have one thread per session (or user). Since sessions are generally independent and do not tend to communicate, with Vaadin you effectively have one thread where you do things synchronously - update the UI, fetch stuff from REST/database synchronously, update the UI some more and return. That is the most simple programming paradigm you can get. Moving to Rx/Promises/Actors for whatever reasons will make your program more complex by an order of magnitude.

Unfortunately, simplicity is typically discarded too easily since it only creates indirect costs: the development is slower since the code is way more complex and harder to modify/add features to, there are more bugs so the maintenance is slower. When simplicity is discarded, the result is typically a big ball of mud nobody dares to refactor.

You don't want to go there. Make it work correctly; only then make it work fast. Don't include Rx in your project solely as an excuse to learn something new.

## Debunking Arguments Against Threads

Typically there is the performance argument against threads: the threads are too heavyweight, and JVM can only create 3000 native threads anyway before something horrible happens, hence we *must* pursue alternatives. But that is simply not true, at least for a typical Vaadin app.

Vanilla OpenJDK on my Ubuntu Linux can create 12000 threads just fine, before failing to create additional thread with OutOfMemoryError. But that's only because there is a systemd hard limit on user process number which is around 12288; lifting that limit will allow JVM to create 33000 threads (in 4 seconds, so quite fast) before failing. To go even further, we need to increase the available heap size, or decrease stack size, fiddle with Linux ulimits etc. It's doable, and it is worth the preserved simplicity. And we don't even need that many threads after all.

According to the [Vaadin scalability study](https://vaadin.com/framework/scalability), Vaadin supports up to 10000 concurrent users on one machine. That's 10000 native threads which JVM and the OS can perfectly handle. Typically your page will go nowhere that limit. You're not Google nor Facebook, and thus you don't need to employ complex techniques those guys need to employ. Start small, start simple; when the page grows, the business catches up, the idea is validated and your budget increases, only then you can fiddle with performance.

Regarding native threads performance: Ruby had green threads but they moved to native threads; Python had native threads from the start. Well, to be honest they still have GIL so they can still use but one CPU core, but the point is that those guys considered OS threads lightweight enough so that they started to use them.

As the time passed and JVM got more optimized:

* Intra-process context switching became more cheap
* locks on JVM are now [based on CAS and thus very cheap](https://blogs.oracle.com/dave/biased-locking-in-hotspot)
* JVM can ramp up 30000 threads in 3-5 seconds on my laptop without any issues
* 10000 threads with default stack trace of 512k will consume 5GB of memory; that could be handled by the virtual memory OS subsystem - if I don't use Spring/JavaEE/other huge stack generators then the stack is typically nearly empty and can be left unallocated/swapped out
* Majority of threads typically sleep/are parked, and thus they are not eligible for preemptive multitasking/context switching and thus generate no observable CPU overhead
* The overhead is mostly memory upkeep for stack and some thread metadata.

Therefore, using the threaded imperative model with Vaadin is completely fine and will create no obvious bottlenecks.

## Conclusion

[Quoting Donald Knuth](http://wiki.c2.com/?PrematureOptimization):

> Programmers waste enormous amounts of time thinking about, or worrying about, the speed of noncritical parts of their programs, and these attempts at efficiency actually have a strong negative impact when debugging and maintenance are considered. We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil. Yet we should not pass up our opportunities in that critical 3%.

I suggest you [start simple](http://www.codingninja.co.uk/best-programmers-quotes/) unless it's absolutely clear that it won't suffice anymore; only then employ more complex techniques. Also, if you're not a functional paradigm guy, don't hop on the Rx/Promises bandwagon - use Kotlin's Coroutines since they produce code that's vastly simpler and superior.
