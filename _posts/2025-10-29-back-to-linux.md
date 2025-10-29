---
layout: post
title: Back to Linux from MacOS/MacBook
---

I've moved back to Linux from my brief 1-year experiment with MacOS/MacBook.
It was a very interesting experiment, and I've kept the good parts of the Apple ecosystem -
the iPhone, Apple TV, iPad. But I won't keep my MacBook Pro, and here's why.

# Lock-in

Apple likes to lock things down and tighten the screws. Generally, I don't mind, especially
with iPhone, Apple TV and iPad - those are the devices I generally don't want to tinker with,
and I just want them to work. But, I'm a developer, and my laptop is the polar opposite of the above. I want to tinker with it,
and I want the developer tools to be readily available as first-class citizens.

MacBook feels like being built for specific kinds of jobs: photo editing, video editing,
music editing, but not really for programming (other than XCode): the default terminal is bare-bones,
the default shell is bare-bones, and most importantly: to get any of the tools you need to
install HomeBrew or similar. Let's set aside the fact that you install HomeBrew by running a shell
script off the internet as root (huge red flag), and focus on a bigger problem: HomeBrew is
a 3rd party app. If Apple was serious with their support for developers, they would
introduce some kind of HomeBrew themselves. But I believe they're never going to do that.
And that tells me
that MacBook is not really meant for me as a developer.

What's worse, Apple can at any time decide to tighten the screws and break something that allows
HomeBrew to function and exist. You can make a point that Apple won't ever do that since it would
alienate many developers. True, but here's an idea: with Linux, tools like HomeBrew aren't
even necessary since you have a package manager baked in as a first-class citizen.
The package manager (e.g. apt in Debian/Ubuntu) can install anything you need. And
it's a fundamental part of the OS so it will NEVER go away. Compare that to Apple's approach:
they don't really care about HomeBrew; if Apple changes something and breaks HomeBrew, you must count on the HomeBrew
team to fix it.

# MacOS is buggy as fuck

There are bugs in MacOS that simply shouldn't exist in a pro software. Bugs like keyboard shortcuts
not working all the time or in every app. I won't repeat myself here, for details see my
[Apple rant](../apple-rant/).

The gist is that things like maximizing a window or moving a window to a different monitor should
be baked in the OS and work reliably. They don't in MacOS, and you need third-party tools like Magnet
to fix this most basic stuff.

I am not willing to pay a premium for an operating system that works worse than fucking GNOME, period.

# RAM and SSD is fucking expensive

You can tell me to use a VM like UTM or Parallels, to run Linux. The problem is having to
mentally switch between two different keyboard systems all the time. I can't do that. I can switch once per
year (or once per life), say when moving from Linux to MacOS. That's doable. But switching like 20
times per day and stay productive, that's impossible for me.

Maybe I could use Mac on Mac; install HomeBrew and all dev stuff to guest OS and use that, right?
UTM's support for MacOS-on-MacOS is first-class after all; or pay Parallels 100 eur per year and use that.

The problem is that, when running VMs, you need a lot of RAM and lot of disk space.
And both things are ridiculously expensive. And I don't mean like, maybe 15-20% more expensive than
their x86 counterparts: RAM+SSD from Apple is EIGHT FUCKING TIMES more expensive.
If you want a MacBook Pro with 2TB SSD and 64GB of RAM, you are looking at a machine that's around 6000 EUR.
At least.

You can get a comparable AMD machine for maybe a 2000 EUR and run Linux instead. And you can easily add double the memory if you wish so, either right from the get go, or upgrade later on.

You can argue that x86 is fundamentally worse than ARM and M-Series of CPUs, and you might be right.
But as of 2025, I don't really care. AMD has stepped up their game seriously: the machines generally run
8+ hours and are performant enough to be comparable to M3 Pros. x86 isn't as efficient as ARM, true,
but the CPUs like Ryzen 7 8845HS is efficient enough and powerful enough for my needs.

You can argue that MacBooks are extremely well-built (true - no x86 comes close), but there are
things on my list that simply are more important than this. And Tuxedo, Framework, System76 and
Slimbook machines are reasonably-well built.

# Gaming

I don't game that much, so I tended to be okay with not having games on Mac. I tried Parallels, but
not all games worked well (say StarCraft 2 Nova missions were completely unplayable), telling me that
perhaps gaming in a VM is fundamentally impossible. So I got a Windows laptop and ran games there.

But now I found out that Steam works in Linux, and almost all of the games (including AAA games) work
really well on Linux too (thanks to Proton). And I don't think I'm willing to give that up.

You can argue that Steam will port Proton to MacBook, and you might be right because there's a lot of money
for grabs. But they might fight with Apple which is trying to do the same thing. And, most importantly,
as of 2025, Steam games generally don't work on MacBook.

