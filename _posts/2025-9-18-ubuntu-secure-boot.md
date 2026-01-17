---
layout: post
title: Ubuntu Secure Boot
---

Installing Ubuntu with encryption enabled only encrypts the root folder. That is enough
if you're only worried about someone stealing your laptop and seeing your files.
However, there is another attack vector: someone gains access to your laptop, modifies
the initrd image (that's possible since it's on unencrypted `/boot`) and hands it back, without you knowing -
so-called "evil maid" attack.
If you want to defend against that, read on.

The default UEFI installation of Ubuntu is described in [Ubuntu UEFI Secure Boot](https://documentation.ubuntu.com/security/security-features/platform-protections/secure-boot/) and works as follows:

1. It uses GRUB which installs `/boot/efi/*/shimx64.efi`/`shimaa64.efi` file, which is cryptographically signed by Microsoft.
   If you have Secure Boot enabled in your BIOS, it will check the signature and will reject to boot if this file is changed.
2. Shim boots `grub.efi`, which is the GRUB itself. The signature of this file is checked not by Secure Boot, but by `shim*.efi` instead, which is enough.
3. GRUB then loads kernel and initrd image from `/boot` and runs it. It checks the kernel signature but not the initrd image signature.
4. Kernel+initrd locates encrypted root, allows you to input the password and continue with the boot process.

The problem is step 3 - the `/boot` partition is unencrypted and initrd image can be tampered by the attacker.

This article has been obsoleted by [Ubuntu Secure Boot: take 2](../ubuntu-secure-boot2/),
but I'm keeping it here for historical purposes.

# GRUB + Encrypted `/boot`

One idea is to encrypt `/boot` itself, with [LUKS/LVM](../luks-lvm-boot/), and have GRUB ask for password
and decrypt `/boot`. Unfortunately this won't work since
[GRUB's support for encrypted /boot is limited](https://wiki.archlinux.org/title/GRUB#Encrypted_/boot).
In short, GRUB only supports LUKS1 and has limited support for LUKS2: it only supports PBKDF2
and not Argon2.

> EDIT: GRUB 2.14rc1 supports the Argon2i and Argon2id PBKDFs. 
> [See upstream commit](https://cgit.git.savannah.gnu.org/cgit/grub.git/commit/?id=6052fc2cf684dffa507a9d81f9f8b4cbe170e6b6). ([Discussion](https://wiki.archlinux.org/title/Talk:GRUB#grub_2:2.14rc1_added_support_for_LUKS2_+_argon2_encryption.)). 
> ArchLinux installer 2026 or later contains this GRUB but it isn't signed 
> and thus not eligible for Secure Boot; Ubuntu 25.10 packages older GRUB 
> which is signed but doesn't support Argon2.
>
> See [GRUB + Encrypted boot](../grub-encrypted-boot/) for more details.

# Unified Kernel Image (UKI)

There's another way. We can package kernel and initrd into one efi file, sign it,
and have GRUB or systemd-boot run that. That's UKI. You have two options:

1. Use `mkinitcpio` to build UKI and continue using GRUB, or
2. Use `systemd-boot` with `systemd-ukify`.

I have no experience with `mkinitcpio`, and therefore I'll jump straight to the second option.

> Note: Ubuntu 25.10 uses dracut which in theory can produce UKI files, but they failed to boot for me.
> So, I guess the easiest way is to use dracut to build initrd and then systemd-ukify to create UKI file.

## virt-manager + Secure Boot

The best way to test this is to setup Ubuntu Desktop in a VM, say via `virt-manager`.

Since Ubuntu 22.04, both TPM2.0 and Secure Boot is supported by virt-manager; make sure to have the `ovmf` package installed, and your VM
is using `UEFI` instead of virt-manager's default `BIOS`. Also, make sure to include the TPM in your VM:
add the TPM hardware to your VM and make sure it's Model CRB Version 2.0. Also, go to "Boot Options"
and enable "Enable boot menu": this gives you time to press `F2` when the VM boots,
to go into BIOS and confirm that Secure Boot is indeed enabled.

## systemd-boot with systemd-ukify

systemd-boot only works in UEFI mode (as opposed to GRUB which also supports booting from MBR).
It registers the `systemd-bootx64.efi` to UEFI BIOS, which is then configured via `/boot/efi/loader/loader.conf`
to boot either a kernal and its initrd, or an UKI .efi file. That means that the UKI .efi file isn't
booted directly by the UEFI BIOS, even though it's an .efi file: instead, `systemd-bootx64.efi` is loaded first, which then loads the kernel.

> Note: you can use `efibootmgr` to boot the UKI directly (skips bootloader signing), but `systemd-boot` is more robust for multi-kernel setups.

systemd-boot (or rather Secure Boot) verifies the signature of the UKI .efi file.

The kernel and initrd files are stored to `/boot/efi/7733758bfabe46c587a1d2f8ac01aef0/` (identifier will differ for you) -
the kernel is stored in the EFI partition as opposed to the traditional kernel+initrd placement straight in `/boot`.

Lots of information about systemd-boot and debian can be found at [copyninja.in](https://copyninja.in/).

### systemd-boot

To setup `systemd-boot`, you need to install it:
```bash
$ sudo apt install systemd-boot
```

This installs `systemd-boot-efi` and a bunch of other dependencies. This also
automatically creates entries in `/boot/efi` and adds EFI systemd boot option to
the EFI non-volatile RAM called "Linux Boot Manager" which you can now choose
to boot from, in your BIOS UEFI boot menu. The "Linux Boot Manager" is now set as the default UEFI boot option.

You can verify the systemd-boot configuration by running `sudo bootctl list`.

Note that the GRUB `shim.efi` and `grub.efi` are still around. That means that you can now pick how you want your system to boot,
via your UEFI BIOS boot menu:

* choosing `Ubuntu` boots your Ubuntu via GRUB
* choosing "Linux Boot Manager" boots your system via systemd-boot.

Unfortunately, systemd-boot won't boot with Secure Boot on, since `systemd-bootx64.efi` isn't
cryptographically signed correctly. We'll fix that later on; for now disable Secure Boot.

When systemd-boot is installed, it adds hooks to kernel build system so that systemd-boot configuration
is updated when a new kernel is installed. That hook will print
yellow warnings about seed file being world accessible and that being a security hole.
Fix that by mounting EFI partition with umask 0077, by editing `/etc/fstab` and adding
`umask=0077` option to the EFI mount:
```
/dev/disk/by-uuid/xyz /boot/efi vfat defaults,umask=0077 0 1
```

You can now reboot and try to boot via systemd-boot. You can run `sudo bootctl status` to
show lots of detailed information about the current boot status.

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
systemd's `kernel-install` reads the `install.conf` file; if the layout is set to uki then `uki_generator` is used to
create UKI files. By default this is `ukify` which means `systemd-ukify`.

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
You can verify that with `sudo bootctl status` and `sudo bootctl list`.

### Signing .efi for Secure Boot

TODO how to sign ukify-generated efi file via `/etc/kernel/uki.conf` (see example in `/usr/lib/kernel/uki.conf`).
TODO where are the keys/certificates? Probably I need to generate those and register them via MOK utility.

AI-generated stuff which sounds helpful:
Configure ukify to sign the UKI. This involves creating a signing key and certificate, which can be done with `ukify genkey` using a configuration file.
The generated keys and certificates are then used by ukify to sign the UKI during the build process.

Also, [ArchWiki kernel-install](https://wiki.archlinux.org/title/Kernel-install#Plugins)
mentions `kernel-install inspect` but it fails on Ubuntu.

I found somewhere to use the `mokutil` utility, which sounds simpler than using BIOS to enroll keys into firmware as
described at [Secure Boot with UKI](https://copyninja.in/blog/enable_secureboot_ukify.html). Test this out too.

To test that the .efi are now correctly signed and the keys are correctly registered in UEFI BIOS nvmem, enable
Secure Boot and reboot.

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
However, the attacker may reconfigure your laptop to boot via GRUB -
this can be done not just via BIOS (which should be protected via password),
but also by booting his Linux via USB and running `efibootmgr`.

### Nuke GRUB?

Now that `/boot` partition is gone, GRUB can't boot your system anymore, and therefore you can nuke it.
Unfortunately that's not easy since trying to remove grub removes `shim-signed` and `mokutil` and `amd64-microcode` and we might need those in the future.
A better option is to keep GRUB installed and .efi files registered to UEFI nvram: simply never
boot "Ubuntu" UEFI boot item and you're fine.
Alternatively you can [disable GRUB updates](https://www.rodsbooks.com/refind/bootcoup.html#disabling_grub),
but that's not a good idea since it may disable updates to `amd64-microcode` and you want that thing to be updated.

Best thing is to leave GRUB as-is. The `amd64-microcode` goes into initrd anyway, which is then built into UKI .efi
and therefore taken into effect also via systemd-boot.

### Protect BIOS

Password-protect the BIOS. This prevents the attacker from changing the default boot option from the BIOS boot menu (`F2`).

An attacker can insert rogue Linux on USB stick, press `F12`, boot from USB stick and tamper the UEFI boot menu via `efibootmgr`.
Disable or password-protect the `F12` boot menu.

