---
layout: post
title: Ubuntu Secure Boot, take 2
---

The first [Ubuntu Secure Boot](../ubuntu-secure-boot/) article didn't
really suggested a viable solution for fully secure boot, but there is a surprisingly
easy way to do this: by using `systemd-cryptenroll`.
Basically there is a way to sign kernel and initrd via TPM2 and then
make a key out of that which unlocks LUKS.

This setup uses two unlock keys in LUKS:

- A traditional password entered via keyboard. You'll use this
  as a fallback if you manage to lock yourself out.
- A TPM2 key derived from a signature of kernel and initrd, protected by a PIN.
  - The PIN can be simple since it resists dictionary attacks: TPM2 locks if
    invalid PIN is entered three times.
  - If "evil maid" spoofs kernel/initrd, the signature will change which will
    make the key invalid.

When all is good and the kernel/initrd signatures are valid,
Plymouth will ask for a LUKS TPM2 PIN code. Once it does, you can be sure that
the kernel/initrd hasn't been tampered with.

If the signature changes, the key is invalid and Plymouth will fall back to the password
key. Once that happens:

- Either you updated kernel/initrd (via `update-initramfs`) and you forgot about this, OR
- You are a victim of the evil maid attack. Do NOT type in any passwords and do not trust your OS;
  wipe the disks clean.

# Prerequisites

This can be set up on an already installed Linux. You'll need:

- Secure Boot enabled in BIOS
- EFI partition since you must boot Linux in UEFI mode
- `/boot` may be unencrypted
- `/` encrypted via LUKS

We will use the `systemd-cryptenroll` tool. We will NOT use the Clevis tool
which does the same thing but in a more complicated way.

# Setting up

First, edit your `crypttab` and add the option
`tpm2-device=auto`:
```crypttab
dm_crypt-0 /dev/XYZ none luks,discard,tpm2-device=auto
```
This option is what tells Plymouth/systemd-cryptsetup to use the TPM2 metadata from the LUKS2 header and to wait for the TPM2 device to show up.

To install tpm2 support to Plymouth, you must install `sudo apt install tpm2-tools`
otherwise your system won't be able to unlock LUKS and won't boot.

You'll need to rebuild initrd, in order for this change to take effect:
`sudo update-initramfs -u -k all`. Maybe reboot, to check that LUKS+Plymouth
still works.

Next, figure out the device which hosts the LUKS. It won't most probably be a mapper device;
instead it will be `/dev/XYZ`.

```bash
$ systemd-cryptenroll /dev/XYZ --tpm2-device=auto --tpm2-pcrs=7+9+11+12 --tpm2-with-pin=true
```

This will add a new TPM2 unlock key to your LUKS. It will now be used by default by Plymouth.
Reboot and test out: you should be asked for a PIN instead.

## Testing tampering

Simply rebuild initrd via `update-initramfs`: this should invalidate the TPM2 LUKS key.
Now when you reboot, you'll be prompted for a password - a clear sign of
tampering.

## PCR

The PCR 7 guards against tampering with the Secure Boot state (PK/KEK/DB keys, enabled/disabled)
and should always be enabled. The PCR 9, 11 and 12 guard against
changes in kernel, initrd and/or kernel args and should be present at all times too.

If you want to be super-secure, use 0+2+4+7+9+11+12: 0 guards against BIOS change itself etc.

Ideally you want to use PCR 8 as well which guards against changes in
"Boot loader policy / GRUB commands / measured boot loader extensions", but for some reason
adding this will always invalidate the TPM2 key, forcing Plymouth to always fall back and
prompt for password.

To see which PCRs are active:
```bash
systemd-analyze pcrs
```

## After you update BIOS or kernel or rebuild initrd

Run the following command first, to remove any existing TPM2 LUKS:
```bash
$ systemd-cryptenroll /dev/XYZ --wipe-slot=tpm2
```
Then, simply run the setting-up command again.

# After you lock yourself out

If you type in PIN incorrectly and TPM enters "dictionary attack lockout mode",
you can't simply fall back and type in the password.

One way is to boot off an USB stick and remove the TPM2 LUKS key.
Use `lsblk` to discover the device hosting LUKS; then run
```bash
$ systemd-cryptenroll /dev/XYZ --wipe-slot=tpm2
```
This removes the TPM2 key from LUKS, leaving only the password key. Reboot -
you should now be asked for the password.

Another way is to boot off an USB stick and run
`sudo tpm2_dictionarylockout --clear-lockout`.

Another way is to add the `rd.luks.options=timeout=0` kernel parameter to GRUB
boot entry. This should cause Plymouth to skip waiting for TPM and fall back to password.

# More Info

- [Unlocking LUKS2 volumes with TPM2, FIDO2, PKCS#11 Security Hardware on systemd 248](https://0pointer.net/blog/unlocking-luks2-volumes-with-tpm2-fido2-pkcs11-security-hardware-on-systemd-248.html) -
  Lennart Poettering's (author of systemd) blog.
- [ArchLinux systemd-cryptenroll docs](https://wiki.archlinux.org/title/Systemd-cryptenroll)
