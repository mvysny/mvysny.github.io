---
layout: post
title: I don't like Golang
---

Tried out golang, and I personally don't like the language at all. Thoughts:

* Fast compile to native, with static types and GC - awesome.
* Lack of collection API, global functions - lackluster.
* Pointers, errorcodes, no [extension functions](../extension-functions/),
  no compiler-verifiable "implements" contract, no function blocks - dealbreaker.

Go feels too low-level for my tastes, especially the strange decision of still
having to deal with the pointers.

Go has exceptions, however I really don't understand the recommendation to still use error-codes
for library APIs. I think that the exception mechanism is vastly superior to error-codes and shrinks
the code base by 40% by removing the following lines: `if(result != 0) return 1`. If the
language has a proper GC and exceptions, using error-codes is just dumb.

Missing collection API
is a huge slap-in-the-face - having to deal with global functions to use arrays is unacceptable.

Interfaces and their implementation is just horrible: either the interface uses pointers all over the code,
or the interface is a struct, and there's no way to change this later on. This is just so dumb;
Swift does this in a much better way.

Would I prefer golang over C and C++? Definitely.

Over Kotlin-native? That's a toughie. Kotlin is IMHO far better language than golang,
but [kotlin-native on arm64 is severely crippled](../kotlin-native-lessons-learned/). So, if I'd target x86 then Kotlin definitely;
if not, well, I've heard that okio works on arm64 these days...

I'd definitely go Swift over Go: even though Swift only has reference counting as opposed to full GC,
I like Swift's language much more than Go's.

Also, am I the only one who thinks that the Go mascot looks retarded?
