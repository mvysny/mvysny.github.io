---
layout: post
title: Intellij IDEA in VM
---

When working for the customer, I've found out that the best way is to setup a dedicated
VM. That way, it's easy to install anything that the customer uses, without polluting
your main OS. The question is, how does IDEA perform in a VM?

The experiments were done in January 2024, on IDEA 2023.3.4 running on x86-64 Ubuntu 23.10 in Wayland mode as the Guest OS,
with VM GPU acceleration enabled. The situation may change in the future, so
please take this with a grain of salt. Also [Wayland support for IDEA](https://youtrack.jetbrains.com/issue/JBR-3206/Native-Wayland-support)
may change the performance completely since at the moment IDEA runs under Xwayland which may affect performance.

Rating system:
* perfect: works exactly the same as on the host OS - the typing speed is perfect, the autocompletion windows appear immediately,
  and overall feels like native.
* excellent: minor hiccups here and there, but otherwise quite usable: typing speed is perfect, but the autocompletion windows
  may appear slightly slower.
* mediocre: the IDE appear visibly laggish. Unusable for professional work.
* bad: unusable for any sensible work.

## Windows

[VirtualBox 7.0.14](https://www.virtualbox.org/wiki/Downloads) offered horrible performance.
Even with 3D acceleration enabled and guest additions installed, the performance was mediocre
and IDEA suffered from [rendering issues](https://youtrack.jetbrains.com/issue/IDEA-345192/VMWare-with-3D-acceleration-Rendering-Button-Issue).

Hyper-V was not tested since it doesn't offer any GPU acceleration.

VMWare Player 17 offered excellent performance out-of-the-box, with no guest additions needed to be installed
since it works with SPICE driver. The performance was excellent but not perfect.

## Linux Ubuntu 23.10 Host

VirtualBox: untested.

[virt-manager+KVM](../virt-manager/) works out-of-the-box and SPICE drivers offer excellent 3D performance.
But here's the catch: on AMD+Radeon the performance is sometimes excellent but sometimes the IDEA starts performing sluggish,
the CPU skyrockets after every character typed and the performance descends to mediocre.
Intel drivers offer almost-perfect experience, but I need to retest this.

## Mac

UTM only offers GPU acceleration for Ubuntu 24.04 guests (because of some mesa patches). Unfortunately,
IDEA starts but only shows a black rectangle, making it completely unusable. Might be Xwayland issue, or
some kind of incompatibility between UTM and Java rendering; IDEA Wayland or Mesa upgrades might improve things.
IDEA works when the VM is started without GPU acceleration, but the speed is bad.

Parallels: untested, but I have high hopes for this kind of setup since I've seen people *gaming*
this way. I'll test and update this blogpost.
