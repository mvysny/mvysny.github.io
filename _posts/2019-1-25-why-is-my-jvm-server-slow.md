---
layout: post
title: Why Is My JVM Server So Slow?
---

If your server-side JVM app chokes up when serving 20 concurrent users, then there is something
very wrong. Luckily, it's usually very easy to find out the initial hint as to
where the problem may lie.

However, before you go all optimization-crazy, a word of warning: [Premature Optimization Is the Root of All Evil](https://stackify.com/premature-optimization-evil/)
which causes highly complex code. Gather a proof of slowness of some place in code, and only then optimize.

The most basic resources every app uses are:
* CPU
* disk
* memory
* network

These are very easy to look at, and they will give you a pretty decent initial impression what's wrong with your app. On a Linux box,
you can simply run `htop` to see CPU and Memory and Swap, `sudo iotop` to see the disk usage,
`sudo nethogs` to see the network usage.

## Constant 100% CPU usage

That usually means that your app is doing some really heavy computation, possibly blocking
your users from receiving responses. If you can reproduce the scenario locally,
then that's great - you can use any profiler such as Intellij's [Async Profiler](https://blog.jetbrains.com/idea/2018/09/intellij-idea-2018-3-eap-git-submodules-jvm-profiler-macos-and-linux-and-more/)
to see what's wrong with your app. If you can't reproduce the scenario locally,
usually connecting your profiler to a remote app is quite hard. Luckily you can
simply include the profiler as a jar to your server, then watch it server-side.
Just wrap the [Suckless Ascii Profiler](https://github.com/mvysny/suckless-ascii-profiler) call around
your servlet methods, dumping profiling stats if the request took more than 20 seconds.

After you discover the hotspot method, you can proceed to optimize the code.

### It May Be GC

However, having high CPU usage could also mean that your JVM is striving to get more memory for your app.
If your `-Xmx` is low and your app memory usage is high, then GC starts to use 100%
of CPU, to collect garbage memory and find free memory blocks. If GC is unable to
do so in a reasonable time (3 seconds usually), then the JVM fails with `OutOfMemoryError`.
However, the JVM may never fail with `OutOfMemoryError` since GC may actually succeed
to find free memory, which is then taken by your app, so the GC has to run
again to find free memory (which may have been released by some thread as we speak),
and again and again, taking more than 30% of CPU.

So, looking at your GC eating up 30% or more of your CPU is a sign that the
app is running out of memory. Either increase the `-Xmx` of your server,
or you really need to memory-profile your server.

You can use [webmon](https://github.com/mvysny/webmon) to embed a tiny JVM monitoring
tool into your app; then you can look at the GC CPU usage, to check if it is constantly anything
above 10-15%.

## 90% Memory Usage

If the CPU is not the main hog, let's look at the memory usage. Often the `-Xmx`
of your JVM exceeds the physical memory of your server. When JVM grows too large,
Linux has to start swapping JVM's memory to disk. If that starts to happen frequently and your disk
is slow, then that could be the cause of slow responses. You can confirm excessive swapping by
looking at `sudo iotop` and see high disk usage, or here:
[How can I tell how much my system is swapping?](https://unix.stackexchange.com/questions/103911/how-can-i-tell-how-much-my-system-is-swapping).
If this happens, either decrease `-Xmx` of your server, or buy more RAM.

## Excessive Disk usage

If CPU usage is low but `sudo iotop` shows high numbers, then the JVM may be
spending lots of time waiting for the disk. If the memory usage is high, then
it might be excessive swapping as discussed above; if not, then it's simply
your app doing too much disk access. You can verify that by profiling your app as suggested
above, to confirm that the majority of time is spent in disk-accessing functions.
When that's confirmed, you need to optimize your app, or buy a new disk.

## Excessive Network Usage

It may be a sign of your app polling a backend system too much. You can profile your
app as suggested above, to confirm that the majority of time is spent in backend.
If true, you can optimize your code to access backend less, maybe cache responses if possible,
or optimize the backend.

## None Of The Above

Sometimes neither the CPU, disk, memory and network is excessively used,
and thus the problem may lie elsewhere:

* Livelock or deadlock: too many threads contending for the same lock. You need to profile
  to make sure on which lock the JVM spends most time waiting for.
* Excessive `Thread.sleep()` - maybe leftovers of some debugging session?
* Slow network hogging down your backend calls - profile to check how much time you
  spent in your backend calls.
