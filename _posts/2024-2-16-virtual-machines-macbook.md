---
layout: post
title: Virtual Machines on MacBook
---

I've tested two VMs: [UTM](https://getutm.app/) and Parallels.

## UTM

You can get UTM also from App Store (which I did), then you'll get automatic updates and you'll
support the developers.

General Settings:

* Application / Prevent system from sleeping -> on
* Input: Option Is Meta Key, that allows Meta key combinations in Ubuntu
  * If you don't check this, then "Cmd" will be the Meta key.
* Input: invert scrolling

Additional keyboard shortcuts I [found for Parallels but work for UTM too](https://forum.parallels.com/threads/keyboard-shortcut-for-home-end.208263/):

* Home = Fn+ArrowLeft
* End = Fn+ArrowRight -> Type this in Parallels Configuration of keyboard in Windows
* PgUp = Fn+ArrowUp -> Type this in Parallels Configuration of keyboard in Windows
* PgDown = Fn+ArrowDown -> Type this in Parallels Configuration of keyboard in Windows
* Backspace = Fn+Delete
* Fn+Shift+ArrowRight+Alt/Opt (Windows) = Cmd+Shift+ArrowRight (MacOS) = Select all texts from that point to the right -> this is silly of Parallels & Windows because in Windows PC, Fn+Shift+ArrowRight = Move to End without needing the Alt key!
* Fn+Shift+ArrowLeft+Alt/Opt (Windows) = Cmd+Shift+ArrowLeft (MacOS) = Select all texts from that point to the left -> this is silly of Parallels & Windows because in Windows PC, Fn+Shift+ArrowLeft = Move to Beginning without needing the Alt key!

GPU drivers to use:

* `virtio-gpu-gl-pci` only works with Ubuntu 24.04+ which has newest mesa drivers required for GPU acceleration. Note that Java-based
  apps (such as Intellij IDEA) won't work and will display black rectangle.
* `virtio-gpu-pci` works with any Ubuntu, the acceleration is disabled and the performance is horrible.

## Parallels

TODO
