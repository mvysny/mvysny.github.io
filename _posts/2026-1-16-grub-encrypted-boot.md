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
and thus not eligible for Secure Boot; Ubuntu 25.10 packages older GRUB 
which is signed but doesn't support Argon2.

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

TODO

