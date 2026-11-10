---
layout: post
title: "Fingerprint login on Linux with a Token2 FIDO2 key"
date: 2026-11-10 11:02:20 +0200
---

In the [previous post](../fingerprint-reader-linux/) I went hunting for a USB
fingerprint reader that works with Linux, came back empty-handed, and ordered a
Token2 PIN+ Bio3 instead: a FIDO2 security key with a fingerprint sensor. It
arrived, and I'm happy to report that it works very well. I now unlock the
lock screen, log in, and run `sudo` on Ubuntu 26.10 (GNOME 51) by touching the
key, and the password still works as a fallback.

There's no GNOME Settings page for this and no fingerprint icon; it's all CLI
and PAM edits. But it's only a handful of commands, everything comes from the
Ubuntu repo, and none of it is Token2-specific: any FIDO2 key with a fingerprint
sensor and standard CTAP 2.1 biometric enrollment should work the same way.

# How it works

A quick recap. The key does the fingerprint matching itself: your fingerprints
are stored on the key and never leave it. When you touch the sensor, the key
only tells the computer "the user has been verified" and signs a cryptographic
challenge. Linux never sees a fingerprint, so `fprintd` and `libfprint` are out
of the picture. Instead, the [pam-u2f](https://developers.yubico.com/pam-u2f/)
PAM module asks the key to verify you.

The setup has three parts:

1. Set a PIN on the key and enroll your fingers into it, with `fido2-token`.
2. Register the key with your user account, with `pamu2fcfg`.
3. Tell `sudo` and GDM to accept the key, by editing their PAM config.

# Step 1: Install the tools

```bash
sudo apt install libpam-u2f fido2-tools
```

`libpam-u2f` brings the PAM module and `pamu2fcfg`; `fido2-tools` brings
`fido2-token`, a vendor-neutral tool for managing FIDO2 keys. Careful: the
package is `fido2-tools`, not `libfido2-tools`.

# Step 2: Find the key

Plug the key in and run:

```bash
fido2-token -L
```

It lists the FIDO2 devices it found; each line starts with a device path such
as `/dev/hidraw3`. I'll write it as `$DEV` below, so in fish:

```fish
set DEV /dev/hidraw3
```

or `DEV=/dev/hidraw3` in bash. The number can change when you re-plug the key,
so run `fido2-token -L` again if a command can't find the device.

# Step 3: Set the PIN

```bash
fido2-token -S $DEV
```

The key needs a PIN before it lets you enroll fingers. It needs at least 6
digits, and the "PIN+" in the Token2 name means it enforces PIN complexity:
trivial PINs like `111111` or `123456` are rejected. Store the PIN in your
password manager. A forgotten PIN means a factory reset of the key.

You won't type the PIN often. Day to day, the fingerprint does the work. The
PIN is needed for managing the key (enrolling and deleting fingers), and as a
fallback when the fingerprint doesn't work, see below.

# Step 4: Enroll your fingers

```bash
fido2-token -S -e $DEV
```

It asks for the PIN, then you touch the sensor repeatedly, shifting the finger
slightly each time, until the enrollment completes. Run it again to enroll
another finger. I'd enroll at least two fingers, ideally one from each hand.

Note that it's `-e` (as in enrollment), not `-b`: `-b` manages the
"largeBlob" storage on the key, and `fido2-token -S -b` just prints the usage.

List the enrolled fingers:

```bash
fido2-token -L -e $DEV
```

Each enrollment has an ID (a base64 string) and an optional name. To give an
enrollment a friendly name, or to delete it:

```bash
fido2-token -S -e -i <template_id> -n "right-index" $DEV
fido2-token -D -e -i <template_id> $DEV
```

If you'd rather click: Chromium has a GUI for the same thing, under Settings →
Privacy and security → Security → Manage security keys. Token2 also offers
desktop tools ([fido2-manage and a companion
app](https://www.token2.com/site/page/using-token2-fido2-keys-under-linux)),
but I didn't need them.

# Step 5: Register the key with your account

```bash
mkdir -p ~/.config/Yubico
pamu2fcfg -V > ~/.config/Yubico/u2f_keys
```

Touch the sensor when it blinks (it may ask for the PIN first). The `-V` flag
says that this credential requires *user verification*: the key must verify
your fingerprint (or PIN), not just register a touch. The file now holds one
line starting with your username, followed by the key's credential. Don't mind
the `Yubico` in the path; that's just the default location `pam_u2f` looks in,
for keys from any vendor.

If you have a second key (a good idea, see below), append it:

```bash
pamu2fcfg -n -V >> ~/.config/Yubico/u2f_keys
```

`-n` leaves out the username, so the second credential is appended to the
same line.

One gotcha: the credential is bound to `pam://<your hostname>`, both in
`pamu2fcfg` and in `pam_u2f`. If you rename the machine, the key stops working
for login, and you need to re-run `pamu2fcfg` (or pin the name with the
`origin=` option on both sides).

# Step 6: Enable it for sudo

This is where you can lock yourself out, so let's be careful. First back up the
PAM file, and open a root shell in a separate terminal:

```bash
sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
sudo -s
```

Keep that root shell open until everything works. If you break `sudo`, you can
still restore the backup from there: `cp /etc/pam.d/sudo.bak /etc/pam.d/sudo`.

Now, from the root shell, add these two lines at the very top of
`/etc/pam.d/sudo`, above the `@include common-auth` line:

```
auth sufficient pam_u2f.so cue pinverification=0 userverification=1
auth sufficient pam_u2f.so cue pinverification=1 userverification=0
```

This is taken straight from the "biometrics with a fallback to PIN" example
in `man pam_u2f`. PAM tries the lines in order:

1. The first line asks the key to verify your fingerprint. If it matches,
   you're in: `sufficient` means no further checks are needed.
2. The second line only runs if the first one fails, for example after several
   misreads lock up the sensor. It asks for the key's PIN at the prompt. The
   key checks the PIN, so keep it plugged in.
3. If both fail, or the key isn't plugged in at all, PAM falls through to the
   normal password prompt from `common-auth`.

`cue` prints a reminder to touch the key, otherwise `sudo` just silently waits
for you.

I haven't actually tested the PIN fallback (line 2) yet, and I don't expect
to need it much: when the finger doesn't work, I just type the password. If
you don't want the PIN at the prompt at all, leave the second line out. If you
keep it, remember that a wrong PIN typed at the prompt counts toward the key's
PIN retry limit, the same as anywhere else, so don't guess.

Why not put the lines into `/etc/pam.d/common-auth`, which every service
includes? Because then they'd apply to everything, including `su`, `sshd` and
whatever else uses PAM. Adding them to the two services I care about keeps
the change small and easy to reason about.

Now test it from a different terminal:

```bash
sudo -k      # forget the cached sudo credentials
sudo true
```

Touch the sensor, and `sudo` should let you through. Then unplug the key and
try again: you should get the usual password prompt.

# Step 7: Enable it for the lock screen and login screen

Same drill. Make sure the root shell is still open, then back up GDM's PAM
file:

```bash
sudo cp /etc/pam.d/gdm-password /etc/pam.d/gdm-password.bak
sudo nano /etc/pam.d/gdm-password
```

and add the same two lines at the very top, above the existing `auth` lines.

Test the lock screen first, without logging out: press Super+L and touch the
sensor. If it doesn't work, the password still unlocks the screen, and you can
restore the backup from the root shell. Only once the lock screen works, try a
full logout and login.

When everything works, close the root shell.

In the previous post I wondered whether GNOME 51 would still allow this. GNOME
51 made the *fingerprint* login (the `fprintd`-based one, which has its own
`gdm-fingerprint` PAM service) work only for re-authentication, so you have to
type the password once after boot. `pam_u2f` is a plain module in the
`gdm-password` stack, and GDM has no idea a fingerprint was involved; as far as
it's concerned, the password service said yes. Logging in with the key alone
works fine on GNOME 51.

# Living with it

I've only been using the key for a short while, so this section is a work in
progress. I'll update it as I learn more.

- **GNOME Keyring.** As explained in the previous post: if you log in with the
  key, there's no password to unlock the keyring with, so GNOME asks for the
  password once, right after login. I'd rather log in with the password after
  a boot, and use the key for the lock screen and `sudo` afterwards. That has
  a catch, see "doesn't like being interrupted" below.
- **The LEDs.** A steady green LED means the key is idle and ready. A
  blinking green LED means it's waiting for your finger: during login, `sudo`,
  or enrollment.
- **The key doesn't like being interrupted.** With the key plugged in, the
  login screen waits for a touch. To type the password instead, I press Esc.
  The login works, but the key keeps blinking green for a while, then turns
  solid red and stops responding: the next `sudo` just hangs and does nothing.
  The same happens when I abort `fido2-token -S -e` with Ctrl+C in the middle of
  an enrollment. So it's not GDM's fault; the key just doesn't handle an
  abandoned request well. It does recover on its own after a while: listing
  fingerprints works again, `sudo` asks for a finger, and the LED goes from
  solid red back to blinking green. But I don't want to wait, so my rule is
  simple: **whenever the LED is red, unplug the key and plug it back in.**
- **Disk encryption.** The LUKS password at boot is unchanged.
- **The password always works.** With the key unplugged, everything falls back
  to the password. Don't throw it away.
- **Sensor lockout.** After several failed fingerprint reads, the sensor locks
  up. Any operation authenticated with the PIN should unlock it again, e.g.
  `fido2-token -L -e $DEV`. I haven't run into this yet.
- **Forgotten PIN.** `fido2-token -R $DEV` factory-resets the key. It wipes the
  PIN, the fingerprints and all credentials on the key, including the one for
  your Linux login and any website passkeys, and it doesn't ask for
  confirmation. Some keys only accept a reset within a few seconds after
  plugging in. Then redo steps 3 to 5.
- **Backup key.** If you lose the key, the password still gets you in. But a
  second registered key means you don't have to fall back to typing the
  password everywhere while you wait for a replacement.
- **System updates.** Ubuntu updates may occasionally overwrite files in
  `/etc/pam.d/`. If the key stops working after an update, check the top of
  `sudo` and `gdm-password` for the two lines.

# Conclusion

Instead of a USB fingerprint reader I got something better: a standards-based
device that needs no driver, no self-built `libfprint` and no
vendor software, works on any Linux distro with `pam_u2f`, and doubles as a
passkey for websites. The setup is CLI-only, but it's seven steps that you do
once. Touching the key to unlock the screen dozens of times a day is exactly
the convenience I was after.
