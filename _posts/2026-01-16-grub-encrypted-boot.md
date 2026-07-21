---
layout: post
title: GRUB and Encrypted Boot
---

The best security is to have GRUB protected by Secure Boot,
and the entire disk encrypted including kernel and initrd image,
which would prevent any chances of attacker tampering with the files
(the evil maid attack). Since 2.14rc1,
GRUB supports the Argon2i and Argon2id PBKDFs which are considered secure;
[See upstream commit](https://cgit.git.savannah.gnu.org/cgit/grub.git/commit/?id=6052fc2cf684dffa507a9d81f9f8b4cbe170e6b6). ([Discussion](https://wiki.archlinux.org/title/Talk:GRUB#grub_2:2.14rc1_added_support_for_LUKS2_+_argon2_encryption.)). 

Unfortunately, this is not easy to achieve:
ArchLinux installer 2026 or later has up-to-date GRUB but it isn't signed 
and thus not eligible for Secure Boot without custom keys; Ubuntu 25.10 packages older GRUB 
which is signed but doesn't support Argon2.

Also, if at any point is Argon2 deemed insecure, you'll have to wait years
for support to appear in GRUB. Therefore, I don't recommend this method.

Nevertheless, here are instructions on how to have encrypted boot on ArchLinux.

# Installation

Go through the [terminal-based ArchLinux installation procedure](https://wiki.archlinux.org/title/Installation_guide)
since archinstall doesn't support this yet. Create two partitions:
1G uefi and second one of linux type - this will hold the root fs.
The root fs will be encrypted and there will be no separate partition for `/boot` -
it will reside on the root fs:

```bash
mkfs.fat -F 32 /dev/vda1
cryptsetup luksFormat /dev/vda2
cryptsetup open /dev/vda2 root
mkfs.btrfs /dev/mapper/root
mount /dev/mapper/root /mnt
mkdir /mnt/efi
mount /dev/vda1 /mnt/efi
```

Read [dm-crypt](https://wiki.archlinux.org/title/Dm-crypt) documentation on how this works.
By default a very secure argon2id pbkdf is used.

# Configuring mkinitcpio

We need to configure the mkinitcpio tool, to generate
initrd which can handle encryption and can ask for unlock password.

1. [Edit](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#mkinitcpio) `/etc/mkinitcpio.conf` and add the `sd-encrypt` hook to `HOOKS`, right after the `block` hook.
2. [Edit](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#Using_systemd-cryptsetup-generator) `/etc/crypttab.initramfs` and add the following contents:

```
root  UUID=xyz  none  luks,discard
```
(You can find the device UUID via `blkid -s` or `lsblk -f`)

Rebuild initrd via `mkinitcpio -P`.

# Configuring GRUB

[Read GRUB Encrypted /boot](https://wiki.archlinux.org/title/GRUB#Encrypted_/boot).
In short, edit `/etc/default/grub` and uncomment the line
`GRUB_ENABLE_CRYPTODISK=y`. Then:

```bash
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

This installs GRUB into efi which can unlock encrypted disks.
GRUB will automatically go through all encrypted disks and will try to unlock them,
regardless of the contents of `grub.cfg` or `crypttab.initramfs`.
After it finds disk which holds `grub.cfg`, it reads the file, shows the menu and
allows to read initrd and boot from it.

# Possible vulnerabilities

An evil maid can overwrite GRUB with one that asks for password and uploads it somewhere.
This is mitigated by using signed GRUB and having Secure Boot enabled -
BIOS then refuses to boot unsigned GRUBs.

An evil maid can boot from USB, spoof GRUB signed with custom CA/MOK, then
register the MOK to Secure Boot - you must password-protect your bios and
disable passwordless boot device selector in BIOS.

