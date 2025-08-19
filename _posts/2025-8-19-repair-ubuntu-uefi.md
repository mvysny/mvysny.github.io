---
layout: post
title: Repair Ubuntu UEFI Boot
---

I've performed an experimental installation of Ubuntu on an external
SSD drive. The drive now boots, but my existing Ubuntu no longer boots.
How to fix that? We'll need to perform these steps:

1. Mount root filesystem
2. chroot
3. Recreate UEFI records

# Mount Root Filesystem

The easiest way is to [download Ubuntu desktop](https://ubuntu.com/download/desktop)
and 'burn it' to a USB stick. The Ubuntu Desktop installer is a live-cd which
means you can boot off your USB stick, open terminal and start fixing.

When the USB stick boots up, close the installer and start `gparted`.
This will give you the overview of all block devices you have, and you'll be
able to mount them easily. First, let's focus on mounting the root filesystem;
we'll mount `/boot` and `EFI` later on, based on your `/etc/fstab`.

Also, see [LUKS, LVM and Linux Boot](../luks-lvm-boot/) for command-line
tools which print your block devices.

## LUKS/LVM

If you use LUKS for encryption, open the device via
```bash
$ sudo cryptsetup open /dev/xyz6 xyz6_crypt
```
TODO LVM

## Mounting Root Filesystem

Run
```bash
$ sudo mount /dev/mapper/xyz6_crypt /mnt
```

Note: If you're using btrfs, chances are you'll see folders
`/mnt/@` and `/mnt/@home`. Those are subvolumes and you need to mount them
in a different way:
```bash
$ sudo umount /mnt
$ sudo mount -o subvol=@ /dev/mapper/xyz6_crypt /mnt
$ sudo mount -o subvol=@home /dev/mapper/xyz6_crypt /mnt/home
```

## LUKS revisited

If you're using LUKS: Check out `/mnt/etc/crypttab`: if it says something else than `xyz6_crypt`,
you'll need to start over:
- unmount `/mnt/boot/efi`, `/mnt/boot`, `/mnt/home` and finally `/mnt`
- close LUKS: `sudo cryptsetup close xyz6_crypt`
- open LUKS with the proper name from your `crypttab` via `sudo cryptsetup open /dev/xyz6 my_crypt_thingy_from_crypttab`

## Mounting Everything Else

cat `/mnt/etc/fstab` and mount all other filesystems (except for swap).
Chances are there is at least `/boot/efi` (and `/boot` if your root is encrypted).
If your `fstab` says `UUID=xyz`, just `mount /dev/disk/by-uuid/xyz`. Don't forget
the options, especially `subvol` in case of btrfs.

# chroot

Mount some more stuff and chroot:
```bash
$ sudo mount -t proc proc /mnt/proc
$ sudo mount -t sysfs sys /mnt/sys
$ sudo mount -o bind /dev /mnt/dev
$ sudo mount -t devpts pts /mnt/dev/pts
$ sudo chroot /mnt
```
You're now chrooted in your existing system. You can perform any maintenance as required,
by using command-line.

# Repair UEFI

If your UEFI partition was wiped out and you had to re-create it, you can re-populate it with:

```bash
$ apt install --reinstall grub-efi-amd64-signed
$ update-grub
```
