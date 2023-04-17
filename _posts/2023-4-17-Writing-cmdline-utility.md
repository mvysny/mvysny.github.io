---
layout: post
title: Writing a Command-Line Utility - Lessons Learned
---

I wanted to write a small command-line utility (no UI), to run on a Raspberry PI 3,
which is an Ubuntu-based ARM64 machine. (Yup, I've installed the [Ubuntu 64-bit over Raspbian](../raspberrypi-ubuntu/)).
Here are some lessons learned.

Now I'm too old to start experimenting with fancy languages, so my requirements
are pretty much set in stone:

* Statically-compiled language, which rules out Ruby, Python and JavaScript.
* Has GC, which rules out C, C++ and Rust.
* [Doesn't have pointers and error codes](../golang-sucks/)

I've tried three platforms:

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
* Kotlin+JVM: 80-100mb. The memory usage simply wouldn't decrease regardless of `-Xmx32m`, `-Xmx20m`, `-Xmx16m` and `-Xss200k`.
  The JVM definitely needs some kind of 'client' profile where it would focus on using as few memory as possible.

Startup speed: pretty much instantaneous for Kotlin/Native and Dart, around 1 second for Kotlin+JVM which is quite acceptable.

Compiling speeds:

* Kotlin/Native supports cross-compile, so you can compile an linux/arm64 binary on your fast x86-64 machine 
  pretty much in 10 seconds.
* Dart can only produce linux/arm64 binary when compiling on RaspberryPI, which takes at least 2 minutes.
* Kotlin+JVM: It's a WORA so you compile it anywhere and run it anywhere. It compiles on my x86-64 machine in 4 seconds.

Code size (only the stuff I had to develop, excluding any third-party libraries I was able to use):

* Kotlin/Native: 116760 characters, 47% bigger than Kotlin/JVM. By far the biggest since I had to develop File IO and Date-Time support from scratch.
* Dart: 87415 characters, 10% bigger than Kotlin/JVM. Much smaller code-base than Kotlin/Native since I was able to reuse many existing Dart libraries and the awesome Dart stdlib.
* Kotlin/JVM: 79346 characters. Even more reuse of both existing libraries AND the massively useful Java+Kotlin stdlib.
