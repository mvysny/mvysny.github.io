---
layout: post
title: Kotlin Native - Lessons Learned
---

Having excellent language (Kotlin) with a proper full-blown garbage collector (not just
reference counting) compiled to native binary which starts up insanely fast is a god-send.
That being said, a language is almost useless without a set of libraries; and
this is where Kotlin Native lacks severely, especially on ARMs.

This text summarizes my experiences and findings when developing the [solar-controller-client](https://github.com/mvysny/solar-controller-client).

## Working with files

Surprisingly, Kotlin-Native lacks any support for working with filesystem - `File` and `Path` are JVM-only after all.
This is such a glaring omission of such a basic feature it's simply beyond surprising.

In order to work with files, you only have two options:

* Use OKIO, however when you want to run on ARM then you're out of luck: [okio doesn't provide libraries for arm64](https://github.com/square/okio/issues/1171).
* Write your own set of functions, based on posix `open()` function. This is ultimately what I did; see [IO.kt](https://github.com/mvysny/solar-controller-client/blob/master/src/nativeMain/kotlin/utils/IO.kt)
  for more details.

The above fully exposes the basic problem with any Kotlin-Native library: in order to be sure that the
library works on different CPUs, every library has to run the tests on all of those CPUs. Which is obviously
next-to-impossible: [neither GitHub nor GitLab offers ARM-based runners](https://github.com/orgs/community/discussions/25319)
and so you have to set it up yourself. And even if you do, [Kotlin-Native doesn't support building on ARM](https://discuss.kotlinlang.org/t/kotlin-native-getting-unknown-host-target-linux-aarch64-on-raspberry-pi-3b-ubuntu-21-04-aarch64/22874),
so you have to build on x86-64 for ARM, then run the tests on an ARM machine. Which is simply too complicated at the moment;
therefore none of the kotlin-native libraries offer ARM ports. And that makes Kotlin-Native
unusable on ARM.

### Working with serial ports

Even if you use unofficial ARM version of OKIO, it doesn't support serial port configuration. The only way
to access/configure serial port via `tcsetattr()` is to do it manually; see [IO.kt](https://github.com/mvysny/solar-controller-client/blob/master/src/nativeMain/kotlin/utils/IO.kt)
for more details.

To be honest, JVM doesn't offer direct support for serial ports either; you have to use a 3rd party library which
then goes native and brings the massive JNA dependency.

## REST client

Non-existent. OKIO doesn't support sockets, which means that there is no out-of-the-box REST client for Kotlin-Native
apart from ktor-client, which doesn't compile for ARM. See [#6](https://github.com/mvysny/solar-controller-client/issues/6)
for more details.

## Databases

We can only dream of unified standard such as Java's JDBC - there is simply no such thing in Kotlin-Native.
You either figure out how to access database via ODBC (and then install proper drivers, etc etc),
or you try to find a C client for your database and then create bindings for Kotlin-Native.
The easiest way I found is to simply run a native database client from command-line, which obviously
doesn't work for bigger SELECTs etc. See [#12](https://github.com/mvysny/solar-controller-client/issues/12) for more details.

## JSON parsing

There's excellent [kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization) which works really well
and supports ARM too.

## CLI parameter parsing

There's [kotlinx.cli](https://github.com/Kotlin/kotlinx-cli) but unfortunately [it doesn't support ARM directly](https://github.com/Kotlin/kotlinx-cli/issues/89).
Workaround is to copy the sources to your project - it works on ARM well.

## Startup time

Native starts immediately. However, JVM (openjdk 11) on linux x86-64 starts and runs in 170ms which is pretty good as well.

## Conclusion

Experimenting with Kotlin-Native taught me to value the JVM:

* Write-Once-Run-Anywhere (WORA) is simply critical advantage, as can be seen from the text above.
  You don't have to write and test every library on all possible CPUs and platforms: you
  write it only once and leverage JRE to run it properly. Simply amazing.
* Threading with JRE is simply a completely different level than any pthread-based threading.
  Not only we have higher-level abstractions like Executors, but we also have a Java Memory Model
  with the happens-before relationship, guaranteed to work on any CPU and platform.
* Database support is simply on a different level in JDK. Drivers work and are portable
  across all CPUs, because of WORA.
* You don't have to program in Java to use JDK. JDK is awesome, Java is ... average.
  However, JDK+Kotlin is simply brilliant.

## Alternatives

If you need to build for native, it's probably better to use something else, with a
first class support for building to native. [Dart](https://dart.dev/) looks awesome;
you can also try Go but I personally don't like the language at all.
