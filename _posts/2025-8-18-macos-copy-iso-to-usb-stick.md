---
layout: post
title: MacOS Copy ISO to USB Stick
---

It's actually very easy to burn Ubuntu Desktop ISO to a USB stick when
all you have is a MacBook: all the tools are already available, all you need
is to open the terminal and start cranking. First, plug the USB stick to
your MacBook. Then, start Terminal and type in
```bash
% diskutil list external
/dev/disk4 (external, physical): etc etc
```
`/dev/disk4` is your USB stick. Now, unmount it and copy the ISO onto it:
```bash
% diskutil unmountDisk /dev/disk4
% sudo dd if=ubuntu-25.04-desktop-amd64.iso of=/dev/disk4 bs=1m status=progress
```
Eject the drive after the copy is successful:
```bash
% diskutil eject /dev/disk4
```
Done - the ISO is burned onto your USB stick and can be booted from.
