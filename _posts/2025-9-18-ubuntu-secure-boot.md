---
layout: post
title: Ubuntu Secure Boot
---

Installing Ubuntu with encryption enabled only encrypts the root folder. That is enough
if you're only worried about someone stealing your laptop and seeing your files.
However, there is another attack vector: someone gains access to your laptop, modifies
the kernel (he can since it's on unencrypted `/boot`) and hands it back, without you knowing.
If you want to defend against that, read on.

The default UEFI installation of Ubuntu works as follows:

1. It uses GRUB which installs `/boot/efi/*/shimx64.efi`/`shimaa64.efi` file, which is cryptographically signed by Microsoft.
   If you have Secure Boot enabled in your BIOS, it will check the signature and will reject to boot if this file is changed.
2. Shim boots `grub.efi`, which is the GRUB itself. The signature of this file is checked not by Secure Boot, but by `shim*.efi` instead, which is enough.
3. GRUB then loads kernel and initrd image from `/boot` and runs it.
4. Kernel+initrd locates encrypted root, allows you to input the password and continue with the boot process.

The problem is step 3 - the `/boot` partition is unencrypted and can be tampered by the attacker.

# GRUB + Encrypted `/boot`

One idea is to encrypt `/boot` itself, with [LUKS/LVM](../luks-lvm-boot/), and have GRUB ask for password
and decrypt `/boot`. Unfortunately this won't work since
[GRUB's support for encrypted /boot is limited](https://wiki.archlinux.org/title/GRUB#Encrypted_/boot).
In short, GRUB only supports LUKS1 and has limited support for LUKS2: it only supports PBKDF2
and not Argon2.

All distros use LUKS2 and Argon2, and you should too. However, that renders this option not applicable.

# Unified Kernel Image (UKI)

There's another way. We can package kernel and initrd into one efi file, sign it,
and have GRUB or systemd-boot run that. That's UKI. You have two options:

1. Use `dracut` with GRUB, or
2. Use `systemd-boot` with `systemd-ukify`.

The best way to test this is to setup Ubuntu Desktop in a VM, say via `virt-manager`. Since Ubuntu 22.04, both TPM2.0 and
Secure Boot is supported; make sure to have the `ovmf` package installed.

## Using `dracut` with GRUB

Since Ubuntu 24.10+, systemd `kernel-install` supports UKI generation directly. You start
by installing dracut, which uninstalls `initramfs-tools` (this is expected):
```bash
$ sudo apt install dracut
```

TODO what happens next

## systemd-boot with systemd-ukify

Caveat: `systemd-bootx64.efi` is not signed for Secure Boot.

To setup `systemd-boot`, you need to install it:
```bash
$ sudo apt install systemd-boot
$ sudo bootctl install
```

TODO what happens.

TODO how to set up `systemd-ukify`
