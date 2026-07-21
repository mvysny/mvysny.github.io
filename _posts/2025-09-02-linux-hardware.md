---
layout: post
title: Linux and Hardware
---

Now that I dissed on [Apple](../apple-rant/) and [Windows](../windows/), you probably want
to tell me to get a Linux machine and shut up about it, and you are probably right. And there lies the problem.

Don't get me wrong. Linux support for hardware is top-notch these days. I'm sure you can
buy any laptop and Linux would boot on it and most of the things would work, if not all *

Asterisk:

- Obviously Linux suspend is a hit-and-miss. On my Ryzen 7 PRO 4750U suspend works out-of-the-box;
  on my other system with a discrete Nvidia suspend doesn't work, both with nouveau and proprietary Nvidia drivers
- virt-manager GPU acceleration doesn't work with proprietary nvidia drivers; with nouveau it's choppy and doesn't feel right.
  On AMD Ryzen + Integrated Radeon, it's buttery-smooth
- Steam generally works, both on Nvidia proprietary drivers and on AMD Ryzen integrated Radeon. Unexpected, and really awesome!
- Screen sometimes doesn't wake up on nouveau; probably because screen dimming doesn't work (GeForce RTX 4060 Max-Q)
  - No way to control screen dimming on nouveau in kernel 6.14.
- Firefox still doesn't support accelerated videos in 2025, both on Radeon and on Nvidia
  - Partly because [VA-API doesn't work](https://bugs.launchpad.net/ubuntu/+source/mesa/+bug/2125273) - but when you force `media.hardware-video-decoding.force-enabled` to true,
    FF reports h264 hardware decoding as supported on Radeon! Is it because `ffmpeg -hwaccels` supports multiple methods and for example goes through vulkan?
  - Even worse, on Nvidia proprietary driver, Firefox switches to software rendering, making [webgl aquarium demo](https://webglsamples.org/aquarium/aquarium.html) painstakingly slow.
- Basically avoid Nvidia on Linux Desktop
- Okay I get it now, not that many people want to [read The Linux Suspend Bible](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate) or
  a [long list of Linux quirks for their laptop](https://wiki.archlinux.org/title/Framework_Laptop_13). You want to close the lid of your laptop
  and expect it to wake up properly.

I get it. With Apple, I know that if I pay the Apple Tax, I'm getting a top-notch machine.
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

So, Linux is not the problem here. The problem is that the x86 machines are all hit-and-miss - either they lack performance, or they are loud,
or there's something else wrong with them internally, like suspend working three times tops, if at all.
But then again, I love the fact I can get a 2 TB SSD for 150 eur and expand the memory
as well, and [take the machine apart if I want to](https://frame.work).

I just [can't use MacBook unfortunately](../back-to-linux/):

- Having to have Homebrew for basic utilities is ridiculous
- Linux-in-VM requires me to switch between two completely different keyboard layouts, which I can't do
- MacOS window management is atrocious and requires tons of third-party apps to make it usable with mouse and keyboard; ando no I'm not a touchpad person.

I can fix Linux hardware quirks or learn to live with them; MacOS's quirks are fundamentally incompatible with me.
I'll get one of Linux-supported laptops, put Linux on top, solve the quirks (or decide not to be bothered by them) and I'll be a happy camper.

