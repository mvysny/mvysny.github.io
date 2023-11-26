---
layout: post
title: Ubuntu Linux on MacBook host in VM
---

The [UTM](https://mac.getutm.app/) VM is just brilliant. I'm testing it on an old x86 MacBook Air.
When using [QEMU hypervisor](https://docs.getutm.app/settings-qemu/qemu/),
the CPU speed is almost native. Installing Ubuntu from ISO is very easy.

Unfortunately, the video doesn't work really well. There are no visual
artifacts if you don't use the accelerated graphics, but things run very slowly
and the screen repaints are painfully visible.
Enabling gl/virgl causes the VM emulator to
[crash with an error: GL_ARB_clear_texture](https://github.com/utmapp/UTM/issues/5749).
It looks to be a bug in the mesa graphics library - [installing newer graphics libraries in Ubuntu](https://github.com/utmapp/UTM/issues/5749#issuecomment-1762636720)
works well and makes the UI run much faster.
The speed is definitely not native, but I'm testing on MacBook Air 2015 which is
quite old machine; I wonder what kind of experience I would get with the newest M2/M3 machines.
Unfortunately, Java doesn't seem to work well in this setup and IDEA graphics falls apart
completely, making it completely unusable.

This however could be improved in the future - the video speed should be improved by
running on M2/M3 MacBooks, the MESA libraries should be fixed in upcoming Ubuntu 24.04,
and IDEA should hopefully work well when Java switches rendering to Wayland native.

Interestingly, IDEA works perfectly when running in video-accelerated VM on an Ubuntu host.

The mouse scrolling wheel works in a really annoying way for some reason, but that's
just a nitpick and hopefully can be solved.
