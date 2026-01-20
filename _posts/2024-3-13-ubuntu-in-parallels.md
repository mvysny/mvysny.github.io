---
layout: post
title: New Machine - Ubuntu in Parallels/UTM Apple Silicon/virt-manager
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes. I won't setup any encryption since I expect MacBook disk itself to be already encrypted.

# Getting ISO

## virt-manager

Install virt-manager on host os:
```bash
$ sudo apt install virt-manager
```
This will add your user to libvirt automatically; log out and back in to be able to access the VMs.
Then, simply [download the Ubuntu Desktop ISO](https://ubuntu.com/download/desktop) for x86-64, the newest Ubuntu.

Go to virt-manager settings:

* General > Enable system tray icon
* New VM > x86 Firmware: UEFI
* Console > Resize guest with window: On


## Post-installation

### ext4

Enable trim. You need to enable discard for all of your ext4 partitions: simply add the `discard` option to
`/etc/fstab`. Note that swap on a swap partition will perform discard automatically. Make sure the VM disk supports trim:
`lsblk --discard` should print non-zero value in DISC-GRAN for `sda`.

Regarding additional fs flags:
* `user_xattr` is enabled by default on ext4; check with `sudo tune2fs -l /dev/mapper/ubuntu--vg-root`
  and also [user_xattr ubuntu forums thread](https://ubuntuforums.org/showthread.php?t=2400092)
* `extents` - ext4: unknown. There's no longer a mount option `extent` or `extents`,
  probably they are on by default, but it doesn't hurt to turn them on via `tune2fs -O extents`.

# Software & Updates

Go to the "Updates" tab and set:
* When there are other updates: Display Immediately
* Notify me of new Ubuntu version: For LTS only

LTS: the reason is that Parallels only supports Ubuntu 22.04; it shows scary segfaults on Ubuntu 23.10+.
Before upgrading to Ubuntu 24.04, I need to test that it's rock-solid; also this may require Parallels 20+.


# Shared Folders

## virt-manager

Read [virt-manager](../virt-manager/).

