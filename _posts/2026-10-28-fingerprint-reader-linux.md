---
layout: post
title: "USB fingerprint readers on Linux: harder than it should be"
date: 2026-10-28 18:34:02 +0200
---

I'd like to log in to my Ubuntu laptop by touching a finger instead of typing
a password. The laptop has no built-in fingerprint reader, so the plan was
simple: walk into a store, buy a USB fingerprint reader, plug it in, done. It
turned out to be anything but simple.

The frustrating part is that the software side works out of the box. Ubuntu
26.04 with GNOME ships `fprintd` and `libfprint`. If your laptop has a
supported built-in reader (a Framework 13, a ThinkPad T14s...), you go to
Settings → System → Users → Fingerprint Login, enroll a finger, and the login
screen and the lock screen start accepting it. No PPAs, no compiling. The
problem is getting a *USB* reader which libfprint supports.

# Two ways a fingerprint can log you in

There are two completely different technologies hiding under the "fingerprint
reader" label, and it's important to tell them apart before you buy anything:

1. **The OS does the matching (libfprint/fprintd).** The reader is a dumb
   sensor: it sends the fingerprint data to the computer, and `fprintd` compares
   it against your enrolled fingers. This is what GNOME integrates with: the
   fingerprint icon on the lock screen, enrollment in Settings, all of it.
2. **The device does the matching (FIDO2 with Match-in-Sensor).** The
   fingerprint never leaves the key. The key stores your fingers itself, and
   when you touch it, it only tells the computer "the user has been verified"
   and signs a cryptographic challenge. The OS doesn't know or care that a
   finger was involved. On Linux this goes through `pam_u2f`, not `fprintd`, and
   GNOME's fingerprint UI knows nothing about it.

The stuff sold in chain stores today is almost exclusively the second kind,
built for Windows Hello and FIDO2 certification.

# Path 1: a libfprint-supported USB reader

Have a look at the [libfprint supported devices
list](https://fprint.freedesktop.org/supported-devices.html). It's long, but
nearly all of it are sensors built into laptops. The standalone USB readers on
the list are few:

- **DigitalPersona U.are.U 4000/4000B/4500** (`05ba:000a` and friends). The
  4500 is the classic choice: zero setup, it simply works. HID Global (who bought
  DigitalPersona) still sells it, but through B2B and system-integrator
  channels, not consumer retail.
- **SecuGen Hamster Pro 20** and the **NextBiometrics NB-1010-U/NB-2020-U**:
  again, readers for integrators, not something you'll find in an electronics
  store.

What did I find in Finnish stores (Verkkokauppa.com, Gigantti, Power,
Multitronic)?

- **Kensington VeriMark IT**: a FIDO2 Match-in-Sensor key. `fprintd` can't use
  it, see path 2.
- **Precise 100 SC**: a 2000s-era fingerprint + smart card reader for government
  ID systems. Forget it.
- **The original Kensington VeriMark (K67977WW, USB ID `06cb:0088`)**: this one
  is interesting. It isn't supported by libfprint itself, but there's a
  [community clean-room driver](https://github.com/visorcraft/Kensington_VeriMark_06cb-0088)
  for it. You build a patched libfprint with the driver, and a script points
  your system's `fprintd` at it via a systemd drop-in. Then it works with
  `fprintd` like any other reader. Only one store listed it, and it was out of
  stock.

So: no fingerprint reader in stock in a major Finnish store works with Linux
out of the box. Your options are ordering a U.are.U 4500 from an EU eBay/Amazon
seller, or hunting for the old VeriMark and running a self-built libfprint.

Before you buy anything, find out its USB ID (`lsusb` on a friend's machine,
or search the model number plus "lsusb" online) and look it up in the supported
devices list. The product name means nothing; Kensington alone sells several
"VeriMark"s with completely different internals.

## Why do built-in readers just work?

Because someone with money cares. Framework picked a Goodix sensor specifically
because a libfprint driver existed for it, and worked with Goodix and the
distro maintainers to get the right version packaged. Lenovo got Synaptics to
provide a proprietary driver for libfprint's TOD ("Touch OEM Drivers") plugin
interface, so Ubuntu can ship it for ThinkPads. Both sell to Linux users and
certify their machines with Fedora/Ubuntu, so it's worth their while.

USB dongle makers sell to Windows users. Nobody pays the small volunteer
libfprint team to reverse-engineer a protocol for a dongle that sells a few
thousand units a year. And the newer dongles moved to Match-in-Sensor FIDO2,
which doesn't need an OS driver at all, on any OS.

# Path 2: a FIDO2 key with a fingerprint sensor

A FIDO2 security key can log you in to Linux via the
[pam-u2f](https://developers.yubico.com/pam-u2f/) PAM module. Two caveats:

- **Only the "Bio" keys give you a fingerprint login.** A regular YubiKey only
  asks for a *touch* to confirm that a human is present; anyone holding the
  key can do that. You want a key with a fingerprint sensor: the YubiKey Bio
  (around 100-150 € in Finland, and mostly out of stock), a Token2 Bio key, and
  so on. The key needs to support standard CTAP 2.1 biometric enrollment, so
  that you can enroll fingers from Linux with standard tools.
- **The setup is completely different from `fprintd`.** No GNOME Settings, no
  fingerprint icon. You set a PIN on the key and enroll your fingers into the
  key itself, with a CLI tool: the vendor-neutral `fido2-token` from libfido2,
  or a vendor tool such as YubiKey's `ykman` or Token2's
  [fido2-manage](https://www.token2.com/site/page/using-token2-fido2-keys-under-linux).
  Then you register the key for your user with `pamu2fcfg`, and add
  `pam_u2f` to the PAM config of `sudo` and GDM by hand.

The upside: with the right PAM options, the key alone logs you in, the
password still works when the key isn't plugged in, and the key's PIN can act
as a fallback when the finger isn't recognized. I'll go through the concrete
steps in a follow-up post, see below.

# The keyring problem

Either way, there's a catch. GNOME Keyring encrypts your stored secrets (Wi-Fi
passwords, browser passwords) with your login password. If you log in with a
fingerprint or a FIDO2 key, there's no password to unlock the keyring with, so
GNOME asks for the password anyway, right after you logged in. It's an
acknowledged GNOME limitation, not a bug. It doesn't touch disk encryption
either: with LUKS you still type a password at boot.

# Does GNOME 51 help?

GNOME 51 came out in September 2026 and the headlines say "passkey login".
Ubuntu 26.10 ships it; Ubuntu 26.04 LTS stays on GNOME 50. Let's look at what
it actually brings:

- **The login screen can now choose between several authentication
  mechanisms**: password, smart card, passkey (FIDO2), and web login via a QR
  code. This is built on SSSD, and it's aimed at *centrally managed* users,
  that is, accounts living in FreeIPA or Active Directory, with the FIDO2 key
  registered against your domain identity. For a plain local account on a
  personal laptop it doesn't apply: SSSD blocks passkey for local users by
  default, and [people are already running into
  it](https://github.com/SSSD/sssd/issues/9367). As OMG! Ubuntu
  [put it](https://www.omgubuntu.co.uk/2026/09/gnome-51-released), these
  features are "primarily of use to those with corporate or remote setups,
  rather than home users". That's me out.
- **A new, improved fingerprint enrollment UI** in Settings. Nice, if you have a
  libfprint reader in the first place.
- And the one that's not in the headlines, from [GDM's release
  notes](https://gitlab.gnome.org/GNOME/gdm/-/blob/main/NEWS): "in GNOME 51,
  we've changed the behavior of the fingerprint sensor to only function during
  re-authentication. The user can no longer log into their system with a
  fingerprint sensor alone." The reasons: security, and the keyring problem
  above.

So GNOME 51 doesn't help, and on paper it takes something away: even with
a supported reader, you type your password once after boot, and the
fingerprint only unlocks the lock screen. To be honest, I think that's the
right call. You type the password once, the keyring unlocks properly, and the
finger handles the dozens of lock screen unlocks during the day, which is
where it saves the most time anyway.

I haven't checked how GNOME 51's login screen treats `pam_u2f` in
`gdm-password`. That's a plain PAM module in the password stack, not the
fingerprint service, so I'd expect it to keep working. I'll find out.

# To be continued

I gave up on hunting a U.are.U 4500 and ordered a Token2 PIN+ Bio3, a FIDO2
key with a fingerprint sensor. It's path 2: no `fprintd`, no fingerprint icon, PAM edits
by hand. In exchange, it's a standards-based device that should work with any
Linux distro and doesn't need a self-built libfprint, and it doubles as a
passkey for websites.

Will it enroll fingers from Linux without a Windows box? Will `pam_u2f` and
the GNOME lock screen play along? Will I lock myself out of `sudo`? I'll
document the whole setup once the key arrives. Stay tuned.
