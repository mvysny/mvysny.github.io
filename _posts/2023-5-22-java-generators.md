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
that the generator block needs to be run inside of a virtual thread, and the `yield()` function will
have to call a blocking function, in order to suspend.
