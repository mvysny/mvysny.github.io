---
layout: post
title: Linux and Hardware
---

Now that I dissed on [Apple](../apple-rant/) and [Windows](../windows/), you probably want
to tell me to get a Linux machine and shut up about it, and you are probably right. And there lies the problem.

Don't get me wrong. Linux support for hardware is top-notch these days. I'm sure you can
buy any laptop and Linux would boot on it and most of the things would work, if not all *

Asterisk:

- Obviously Linux suspend is a hit-and-miss. On my Ryzen 7 PRO 4750U suspend works out-of-the-box (maybe with potential battery drain);
  on my other system with a discrete Nvidia suspend doesn't work, both with nouveau and proprietary Nvidia drivers
- virt-manager GPU acceleration doesn't work with proprietary nvidia drivers; with nouveau it's choppy and doesn't feel right.
  On AMD Ryzen + Integrated Radeon, it's buttery-smooth
- Steam generally works, both on Nvidia proprietary drivers and on AMD Ryzen integrated Radeon
- Screen sometimes doesn't wake up on nouveau; probably because screen dimming doesn't work (GeForce RTX 4060 Max-Q)
- Firefox still doesn't support accelerated videos in 2025, both on Radeon and on Nvidia
  - Even worse, on Nvidia proprietary driver, Firefox switches to software rendering, making [webgl aquarium demo](https://webglsamples.org/aquarium/aquarium.html) painstakingly slow.
- Basically avoid Nvidia on Linux Desktop

With Apple, I know that if I pay the Apple Tax, I'm getting a top-notch machine.
The machine:

- [won't get sticky by just sitting in the closet](https://youtu.be/4wrJE3SBTBU?si=Jdif0FV9gsEYDU5V&t=110),
- will charge off any USB-C port
- won't slow down to a crawl when I try to screenshare a VM via Google Hangouts (looking at you, Lenovo ThinkPad T14s)
- won't suddenly print error messages that USB hub failed to allocate resources then start disconnecting USB devices randomly
  (again Lenovo ThinkPad T14s, same thing on Linux and on Windows, leading me to believe that it's Lenovo saving on USB subsystem)
- Video playback in browser will be accelerated out-of-the-box

My last machine was Lenovo ThinkPad T14s, which was a pretty expensive machine (2000 eur) yet [it constantly failed to deliver](../networking-lenovo-t14s-sucks/).
And there's no way to tell these things up-front - you have to get the machine, try it out, find these kinds of issues as soon as possible,
then return it quickly and try out something else. x86 feels like a steam engine - huffin' and puffin' with vents spinnin' noisily -
compared to MacBook.

So, Linux is not the problem here. The problem is that the x86 machines are all shit - either they lack performance, or they are loud,
or there's something else wrong with them internally. But then again, I love the fact I can get a 2 TB SSD for 150 eur and expand the memory
as well, and [take the machine apart if I want to](https://frame.work).
I'll get one of those, put Linux on top and I'll be a happy camper.

