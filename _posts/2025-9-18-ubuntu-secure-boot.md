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

1. Use `mkinitcpio` to build UKI and continue using GRUB, or
2. Use `systemd-boot` with `systemd-ukify`.

## virt-manager + Secure Boot

The best way to test this is to setup Ubuntu Desktop in a VM, say via `virt-manager`.

Since Ubuntu 22.04, both TPM2.0 and Secure Boot is supported by virt-manager; make sure to have the `ovmf` package installed, and your VM
is using `UEFI` instead of virt-manager's default `BIOS`. Also, make sure to include the TPM in your VM:
add the TPM hardware to your VM and make sure it's Model CRB Version 2.0. Also, go to "Boot Options"
and enable "Enable boot menu": this gives you time to press `F2` when the VM boots,
to go into BIOS and confirm that Secure Boot is indeed enabled.

## systemd-boot with systemd-ukify

To setup `systemd-boot`, you need to install it:
```bash
$ sudo apt install systemd-boot
```

This installs `systemd-boot-efi` and a bunch of other dependencies. This also
automatically creates entries in `/boot/efi` and adds EFI systemd boot option to
the EFI non-volatile RAM called "Linux Boot Manager" which you can now choose
to boot from, in your BIOS UEFI boot menu.

Note that the GRUB shim.efi and grub.efi are still around. That means that you can now pick how you want your system to boot,
via your UEFI BIOS boot menu:
* choosing `Ubuntu` boots your Ubuntu via GRUB
* choosing "Linux Boot Manager" boots your system via systemd-boot.

Unfortunately, systemd-boot won't boot with Secure Boot on, since `systemd-bootx64.efi` isn't
cryptographically signed correctly. We'll fix that later on.

### systemd-ukify

There is surprisingly not much information at [systemd documentation page](https://systemd.io/AUTOMATIC_BOOT_ASSESSMENT/);
some information can be found at [kernel-install man page](https://www.freedesktop.org/software/systemd/man/latest/kernel-install.html).
There's a [great tutorial at copyninja.in](https://copyninja.in/blog/enable_ukify_debian.html).

To install ukify:

```bash
$ sudo apt install systemd-ukify
```
However, nothing really happens yet. You need to activate UKI, by creating `/etc/kernel/install.conf` with these contents:
```
layout=uki
```
More info at [ArchLinux: kernel-install](https://wiki.archlinux.org/title/Unified_kernel_image#kernel-install).

Now you need to reinstall kernel module, to run `kernel-install`:
```bash
$ sudo dpkg-reconfigure linux-image-$(uname -r)
```
This creates the .efi file named `EFI/Linux/*-generic.efi` and also adds an entry to the systemd boot list, as can be verified
with
```bash
$ sudo bootctl list
```
You can now unlink all Type #1 entries, via `sudo bootctl unlink` command. Reboot - your system should now boot using the UKI .efi kernel.

### Signing .efi for Secure Boot

Lots of information in this regard at [copyninja.in](https://copyninja.in/) - TODO review.

TODO how to sign ukify-generated efi file via `/etc/kernel/uki.conf` (see example in `/usr/lib/kernel/uki.conf`).
TODO where are the keys/certificates? Probably I need to generate those and register them via MOK utility.

AI-generated stuff which sounds helpful:
Configure ukify to sign the UKI. This involves creating a signing key and certificate, which can be done with `ukify genkey` using a configuration file.
The generated keys and certificates are then used by ukify to sign the UKI during the build process.

Also, [ArchWiki kernel-install](https://wiki.archlinux.org/title/Kernel-install#Plugins)
mentions `kernel-install inspect` but it fails on Ubuntu.

Script `91-sbctl.install` is mentioned which looks interesting, but doesn't exist on Ubuntu. `sbctl` does not exist on Ubuntu either.

Also, AI mentions that ukify is not really ready to be used in Ubuntu since the necessary script hooks are missing.

### Remove the /boot partition

Copy all files from the `/boot` partition to your root partition, then unmount the `/boot` partition:
```bash
$ sudo cp -ax /boot /boot2
$ sudo umount -l /boot
$ sudo rm -rf /boot
$ sudo mv /boot2 /boot
```
Uncomment the `/boot` partition from `/etc/fstab` and reboot. Your system now boots without an unencrypted `/boot` partition!
You can nuke the /boot filesystem via `mkfs.ext4` or remove the original `/boot` partition, to make sure that it isn't used anymore.
Even better - you can leave the partition as-is, as a honeypot for the attacker.

### Nuke GRUB?

Now that `/boot` partition is gone, GRUB can't boot your system anymore, and therefore you can nuke it.
Unfortunately that's not easy since trying to remove grub removes `shim-signed` and `mokutil` and `amd64-microcode` and we might need those in the future.
A better option is to keep GRUB installed and .efi files registered to UEFI nvram: simply never
boot "Ubuntu" UEFI boot item and you're fine.
Alternatively you can [disable GRUB updates](https://www.rodsbooks.com/refind/bootcoup.html#disabling_grub),
but that's not a good idea since it may disable updates to `amd64-microcode` and you want that thing to be updated.

Best thing is to leave GRUB as-is. The `amd64-microcode` goes into initrd anyway, which is then built into UKI .efi
and therefore taken into effect also via systemd-boot.

