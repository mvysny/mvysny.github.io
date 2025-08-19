---
layout: post
title: Repair Ubuntu UEFI Boot
---

I've performed an experimental installation of Ubuntu on an external
SSD drive. The drive now boots, but my existing Ubuntu no longer boots.
How to fix that? Turns out that Ubuntu installer modified the EFI Boot Entries
(stored in laptop's non-volatile RAM, which means that it survives reboot and it's not stored on the hard-disk).
This article shows how to use `efibootmgr` and also how to fix your EFI partition if you wipe it out.

# Boot From LiveCD

The easiest way is to [download Ubuntu desktop](https://ubuntu.com/download/desktop)
and 'burn it' to a USB stick. The Ubuntu Desktop installer is a live-cd which
means you can boot off your USB stick, open terminal and start fixing.

# Repair UEFI entries and fix the EFI partition UUID

Run the `sudo efibootmgr` to list the EFI entries, and also run `sudo blkid /dev/sdX*` to findl the PARTUUID of your EFI vfat
partition (you can use `gparted` to find your EFI vfat partition). The EFI entries look like this:

TODO

# Repair EFI partition

If your EFI partition was wiped out and you had to re-create it, you can re-populate it with (you need to [chroot into your Ubuntu installation](../chroot-ubuntu-livecd/):

```bash
$ apt install --reinstall grub-efi-amd64-signed
$ update-grub
```
