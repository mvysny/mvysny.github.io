---
layout: post
title: Writing a Command-Line Utility - Lessons Learned
---

I wanted to write a small command-line utility (no UI), to run on a Raspberry PI 3,
which is an Ubuntu-based ARM64 machine. (Yup, I've installed the [Ubuntu 64-bit over Raspbian](../raspberrypi-ubuntu/)).
Here are some lessons learned.

Now I'm too old to start experimenting with fancy languages, so my requirements
are pretty much set in stone:

* Statically-typed language, which rules out Ruby, Python and JavaScript.
* Has GC, which rules out C, C++ and Rust.
* [Doesn't have pointers and error codes](../golang-sucks/) which rules out Go.
* Has [extension functions](../extension-functions/)

I've tried three programming platforms:

* [Kotlin Multiplatform Native](https://kotlinlang.org/docs/native-overview.html)
* [Dart](https://dart.dev/); my thoughts [on Dart](../on-dart/)
* Kotlin on JVM

## Lessons learned

Kotlin Multiplatform Native is [severely limited at the moment, at least for Linux/ARM64](../kotlin-native-lessons-learned/).
Almost no libraries support ARM64 atm - no File API, no JDBC...

It's not easy to create those libraries since the library has to compile and test for all OSs+CPU combinations - pure CI nightmare.

That reminded me of one thing: JVM WORA is a God-send. JVM is brilliant.

## Numbers

I've written the same code three times:

* Kotlin Multiplatform Native: [solar-controller-client](https://github.com/mvysny/solar-controller-client/)
* Dart: [Renogy Client](https://github.com/mvysny/renogy-client/)
* Kotlin+JVM: [Renogy-Klient](https://github.com/mvysny/renogy-klient/)

Here are some stats on Linux/ARM64. Memory usage (RSS as shown by htop):

* Kotlin Multiplatform native: 5-10mb, by far the smallest memory footprint.
* Dart: 25-50mb, pretty good too.
* Kotlin+JVM: I use `-Xmx20m -Xss200k -client`. The memory usage starts at 80mb, climbs up to 100mb,
  but goes down to 51mb after a day or so. That's pretty good too.

Startup speed: pretty much instantaneous for Kotlin/Native and Dart, around 1 second for Kotlin+JVM which is quite acceptable.

Compiling speeds:

* Kotlin/Native supports cross-compile, so you can compile an linux/arm64 binary on your fast x86-64 machine 
  pretty much in 10 seconds.
* Dart can only produce linux/arm64 binary when compiling on RaspberryPI, which takes at least 2 minutes.
* Kotlin+JVM: It's a WORA so you compile it anywhere and run it anywhere. It compiles on my x86-64 machine in 4 seconds.

Code size (only the stuff I had to develop, excluding any third-party libraries I was able to use):

* Kotlin/Native: 116760 characters, 47% bigger than Kotlin/JVM. By far the biggest since I had to develop File IO and Date-Time support from scratch.
* Dart: 87415 characters, 10% bigger than Kotlin/JVM. Much smaller code-base than Kotlin/Native since
  I was able to reuse many existing Dart libraries and the awesome Dart stdlib. Still, some bits are missing (e.g. `LocalDate`).
* Kotlin/JVM: 79346 characters. Even more reuse of both existing libraries AND the massively useful Java+Kotlin stdlib.

To be clear, this is not a competition to get a codebase with as few characters as possible.
If I wanted that, I could write the whole thing
in Scala, use smiley face operators everywhere and make the code completely unreadable.
The metric here is to reuse as many libraries as possible to 'out-source' common tasks
like parameter parsing and serial port comms, and being able to focus on just the main meat
of the app.

Roughly speaking, a sensible code-base can be done in 79346 characters; anything on top of it
is code caused by missing libraries.

## Conclusion

Looks like there is no free lunch: Kotlin/Native takes the least resources to run, but most resources to develop;
Dart is somewhere in the middle, while Kotlin/JVM is on the other side of this spectrum.

I was hoping for Kotlin/Native to deliver the free lunch: offer fast development known from Kotlin/JVM
and fast runtime because of native. There could be a fundamental problem here though:
in order to be sure that the library works on different CPUs, every library has to run all of its tests on all of those CPUs.
That creates a CI nightmare: [neither GitHub nor GitLab offers ARM-based runners](https://github.com/orgs/community/discussions/25319)
and so you have to set it up yourself. And even if you do, [Kotlin-Native doesn't support building on ARM](https://discuss.kotlinlang.org/t/kotlin-native-getting-unknown-host-target-linux-aarch64-on-raspberry-pi-3b-ubuntu-21-04-aarch64/22874),
so you have to build on x86-64 for ARM, then run the tests on an ARM machine. Which is simply too complicated at the moment;
therefore none of the kotlin-native libraries offer ARM ports.

My preferred solution could be to have a very lightweight JVM which is slightly slower
but eats up way less memory. Something like the `-client` switch but actually working.
Alternatively I could use [GraalVM](https://graalvm.github.io/native-build-tools/latest/gradle-plugin.html)
to cross-build arm64 binaries on my x86-64.
Dart is an excellent middle-ground here: it offers built-in way to build native binary,
and offers excellent development speed.
