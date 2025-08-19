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

```bash
$ sudo efibootmgr
BootCurrent: 0000
Timeout: 0 seconds
BootOrder: 0002,0000,0001,001B,0017,0018,0019,001A,001C
Boot0000* Ubuntu	HD(1,GPT,3a3f69e8-a1c4-4e50-8694-26ae99eb8d3a,0x800,0x219800)/File(\EFI\ubuntu\shimx64.efi)
Boot0001* Windows Boot Manager	HD(1,GPT,e0d0d422-a448-4845-8967-9e058115e910,0x800,0x82000)/File(\EFI\Microsoft\Boot\bootmgfw.efi)
$ sudo blkid /dev/nvme0n1p1
/dev/nvme0n1p1: LABEL_FATBOOT="SYSTEM" LABEL="SYSTEM" UUID="B416-7B93" BLOCK_SIZE="512" TYPE="vfat" PARTLABEL="EFI system partition" PARTUUID="e0d0d422-a448-4845-8967-9e058115e910"
```
You can see that, on my system, EFI has the PARTUUID of `e0d0d422-a448-4845-8967-9e058115e910` however the first EFI Boot Entry named "Ubuntu"
lists `3a3f69e8-a1c4-4e50-8694-26ae99eb8d3a`. Booting from this boot entry will fail. We need to fix the PARTUUID.

Unfortunately, it's not possible to edit a boot entry, you need to create a new one from scratch and delete the old one:
```bash
$ sudo efibootmgr -c -d /dev/nvme0n1 -p 1 -L "Ubuntu2" -l "\EFI\ubuntu\shimx64.efi"
$ sudo efibootmgr
BootCurrent: 0000
Timeout: 0 seconds
BootOrder: 0002,0000,0001,001B,0017,0018,0019,001A,001C
Boot0000* Ubuntu	HD(1,GPT,3a3f69e8-a1c4-4e50-8694-26ae99eb8d3a,0x800,0x219800)/File(\EFI\ubuntu\shimx64.efi)
Boot0001* Windows Boot Manager	HD(1,GPT,e0d0d422-a448-4845-8967-9e058115e910,0x800,0x82000)/File(\EFI\Microsoft\Boot\bootmgfw.efi)
Boot0002* Ubuntu2	HD(1,GPT,e0d0d422-a448-4845-8967-9e058115e910,0x800,0x82000)/File(\EFI\ubuntu\shimx64.efi)
$ sudo efibootmgr -b 0000 -B  # delete Boot0000
```

# Repair EFI partition

If your EFI partition was wiped out and you had to re-create it, you can re-populate it with (you need to [chroot into your Ubuntu installation](../chroot-ubuntu-livecd/):

```bash
$ apt install --reinstall grub-efi-amd64-signed
$ update-grub
```
