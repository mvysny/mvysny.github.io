---
layout: post
title: Java Generators
---

Python has had a concept of [generators](https://wiki.python.org/moin/Generators) for a long time. In short,
you generate sequence by calling `yield` repeatedly in a block, instead of splitting your code into a nasty state machine.
Kotlin implemented the generators via coroutines, see [Kotlin Sequences: Chunks](https://kotlinlang.org/docs/sequences.html#from-chunks)
for more detail. And now that we have virtual threads, we can do the same thing in Java.

Check out the generator code for generating fibonacci numbers:

```java
public class Iterators {
    public static Iterator<Integer> fibonacci() {
        return iterator(y -> {
            int t1 = 0;
            int t2 = 1;
            while (true) {
                y.yield(t1);
                final int sum = t1 + t2;
                t1 = t2;
                t2 = sum;
            }
        });
    }
}
```

The function logic is coherently co-located in a nice function block, as opposed to the traditional
`Iterator` implementation with the logic scattered across the class, essentially becoming a state machine:

```java
public class FibonacciIterator implements Iterator<Integer> {
    private int fib1 = 0;
    private int fib2 = 1;

    public boolean hasNext() {
        return true; 
    }

    public Integer next() {
        int current = fib1;
        fib1 = fib2;
        fib2 = fib1 + current;
        return current;
    }
}
```
Trust me, the state machine solution becomes much more complex for a more complicated generator, especially when
`try{}catch` or for-loops become involved.

## Virtual threads to the rescue!

It all boils down to having a proper implementation of the `yield()` function:

1. `Iterator.next()` gets called.
2. It calls the generator block synchronously.
3. When the generator block calls `yield()`, its execution suspends and returns to the `next()` call.
4. `next()` returns the item produced.
5. `Iterator.next()` gets called.
6. generator block continues running until `yield()` is called. Then, the execution is suspended and returns to the `next()` call.
7. `next()` returns the item produced.
8. `Iterator.next()` gets called.
9. And so on and so forth, until the generator block terminates.

The big question is how to implement `yield()` in a way that it suspends the block? The answer is the new Java feature called virtual threads (or Project Loom).
Please read the [Oracle article on virtual threads](https://blogs.oracle.com/javamagazine/post/java-loom-virtual-threads-platform-threads)
for more information.

Virtual threads have the capability to suspend when a blocking call is called - for example `Thread.sleep()`,
or `blockingQueue.take()`, or `future.get()` and similar. That's exactly what we need! It's therefore clear
that the generator block needs to be run inside a virtual thread, and the `yield()` function will
have to call a blocking function, in order to suspend.

The other problem is calling the virtual threads synchronously. By default, virtual threads execute
asynchronously, in their own dedicated ForkJoinPool. However, with a bit of reflection, it is possible
to create a virtual thread which executes on an `Executor` supplied by us. The `Executor`
will then simply execute submitted continuations synchronously.

> Note: Continuation is a partial execution: you execute a function up to a point, then you suspend,
> then you continue executing that function further. In order to do that,
> all the variables and the stack gets remembered
> while the execution is suspended.

Let's therefore implement the iterator one more time:

1. `Iterator.next()` gets called.
2. It creates a virtual thread for the generator block, with synchronous execution of continuations.
3. It calls `VirtualThread.start()`, which submits the execution for the first continuation. Since the executor is synchronous,
   the execution starts right away.
4. The generator block runs until it calls `yield()`. `yield()` has to block somehow, in order for
   the virtual thread to suspend. We can e.g. use an empty `BlockingQueue`; `yield()` can block while
   trying to take an item from the queue.
5. Since the virtual thread is blocked, the continuation returns, which causes `VirtualThread.start()` to return as well.
6. `Iterator.next()` can now return the value passed to the `yield()` function.

What happens when the `Iterator.next()` gets called again?

1. `Iterator.next()` gets called again.
2. We know that a virtual thread is blocked on a `BlockingQueue`. We'll call `BlockinQueue.offer()` with some dummy item to unblock the virtual thread.
3. Offering an item will unblock the virtual thread immediately - it will immediately submit a new continuation for execution.
   The continuation takes the item from the queue and continues the generator code.
   Since we're using the same synchronous executor as above, the continuation starts running immediately, from within the `BlockingQueue.offer()` call.
4. The generator runs until it suspends itself again, by calling `BlockingQueue.take()` on a queue which is now empty again. Note that
   the `BlockingQueue.offer()` is *still* running :-D
5. Suspending of the generator concludes the execution of the continuation, and we're finally allowed to bail out of `BlockingQueue.offer()`.
6. We continue executing the `Iterator.next()`, checking what happened: if the generator ended,
   we'll end the iteration. Otherwise, we return the value passed to the `yield()` function.

Phew, that's complicated. Hopefully the explanation above makes sense. Just try to re-read it
a couple of times if it isn't clear on the first read.

## Example Code

Please see the [vaadin-loom](https://github.com/mvysny/vaadin-loom) example project for the actual
implementation of the generator pattern; namely, see the `Iterators.fibonacci()` static function
for more details.
