---
layout: post
title: "No suitable destination host found: a Canon PIXMA with 2010-era TLS"
date: 2026-08-22 14:24:44 +0300
---

A Canon PIXMA TS5351 on the network, auto-discovered by `cups-browsed`, queue
shows up by itself, printer accepts jobs - and nothing ever comes out. No paper,
no error dialog, no feedback of any kind. If you got here from a search engine,
you're probably looking at one of these:

```
No suitable destination host found by cups-browsed, retrying later
```

```
device for Canon_TS5300_series: implicitclass://Canon_TS5300_series/
device for Canon_TS5300_series: ///dev/null
```

...or Gnome cheerfully reporting the printer address as `(null):631`.

The root cause turned out to be a genuinely interesting one: the printer's
embedded TLS server is missing an extension from **2010**, and OpenSSL 3.x quite
correctly refuses to talk to it. The fix, on the other hand, is embarrassingly
boring. Here's the trail, including the dead ends, because the dead ends are
where I lost the two hours.

# Step 1: confirm it's a connection problem, not a printing problem

```bash
lpstat -p -d
lpstat -o
```

Printer enabled, accepting jobs, jobs submitted, jobs sitting there forever.
That signature - *submitted but silent* - means discovery or connection, not
rendering. Nothing is wrong with your PPD or your driver.

# Step 2: find the printer's real IP, independent of CUPS

Before debugging anything, get an address you *know* is true, without asking
Avahi or CUPS what they believe.

From the printer itself is the most reliable: **Setup → Device settings → LAN
settings → Confirm LAN settings**, or print the network settings page from its
menu. Failing that, your router's DHCP client list will show it under some
Canon-branded hostname.

From Linux:

```bash
avahi-browse -r _ipp._tcp
```

```
hostname = [246989000000.local]
address = [192.168.1.50]
```

Note the narrow query. **Don't use `avahi-browse -art`.** This printer
advertises ten-plus service types, and browsing all of them at once overloads
the resolver - `-art` hangs or returns half an answer. Ask for one service type
and you get a reliable read. That was the only useful thing to come out of my
mDNS detour.

Or just scan for anything listening on the IPP port:

```bash
nmap -p 631 --open 192.168.1.0/24
```

# Step 3: `implicitclass://` is not the bug

I assumed it was. It isn't. `implicitclass://` is `cups-browsed`'s own
failover abstraction, and it appears whenever `cups-browsed` sees more than one
route to what it thinks is the same printer. This Canon advertises itself,
simultaneously, as:

* `PDL Printer`
* `UNIX Printer`
* `Internet Printer` (plain IPP)
* `Secure Internet Printer` (IPPS - IPP over TLS)
* `_uscan` / `_uscans` for scanning
* and a separate set of all of the above per active network interface, so add a
  USB Ethernet dongle next to Wi-Fi and the list doubles

`cups-browsed` bundles that pile into one queue and picks a backend at print
time. Seeing `implicitclass` is normal. The failure is in *what it does with
it*.

The same goes for the whole Avahi rabbit hole - `(null):631`, IPv6 link-local
addresses without scope IDs, systemd-resolved and Avahi both answering mDNS,
NSS config, rate limiting, stray daemons. **None of that was the bug.** If
`avahi-browse -r _ipp._tcp` gives you a sane `hostname =` / `address =` pair,
name resolution works. Move on.

# Step 4: the clue was in the log all along

```bash
sudo tail -50 /var/log/cups/error_log
```

```
Unable to connect to 246989000000.local:631: A TLS fatal alert has been received.
```

There it is. Offered both plain IPP and IPPS, `cups-browsed` prefers the secure
one - and that TLS handshake fails, every single time. Read the error log
*first*. I didn't.

# Step 5: pinning it down with openssl s_client

This is the part I enjoyed. March through the protocol versions:

```bash
openssl s_client -connect 192.168.1.50:631 -showcerts          # TLS 1.3 → handshake failure
openssl s_client -connect 192.168.1.50:631 -tls1_2 -showcerts  # → handshake failure
openssl s_client -connect 192.168.1.50:631 -tls1_1 -showcerts  # → no protocols available
openssl s_client -connect 192.168.1.50:631 -tls1 -showcerts    # → no protocols available
```

Careful with the last two: "no protocols available" with **0 bytes exchanged**
is your own OpenSSL refusing to dial, not the printer refusing to answer. Force
it to actually try:

```bash
openssl s_client -connect 192.168.1.50:631 -tls1 -showcerts -cipher "ALL:@SECLEVEL=0"
```

Now we get a real handshake attempt, and a much better error:

```
error:0A000152:SSL routines:final_renegotiate:unsafe legacy renegotiation disabled
```

That is a specific, documented OpenSSL 3.x behaviour: it will not complete a
handshake with a server lacking **secure renegotiation (RFC 5746, 2010)** unless
you explicitly say it's fine. So say it's fine:

```bash
openssl s_client -connect 192.168.1.50:631 -tls1 -cipher "ALL:@SECLEVEL=0" -legacy_renegotiation -showcerts
```

```
subject=CN=192.168.1.50
issuer=CN=CanonIJProductXXXXXXXXXXXXXXXX
Protocol: TLSv1
Cipher: AES256-SHA
Secure Renegotiation IS NOT supported
```

And the genuinely surprising bit - with the same override, TLS 1.2 negotiates a
thoroughly modern suite:

```bash
openssl s_client -connect 192.168.1.50:631 -tls1_2 -cipher "ALL:@SECLEVEL=0" -legacy_renegotiation -showcerts
# → Protocol: TLSv1.2, Cipher: ECDHE-RSA-AES256-GCM-SHA384
```

So this is not a hopelessly ancient TLS stack. It does TLS 1.2 with ECDHE and
AES-GCM. Its *only* defect is a missing extension from fifteen years ago -
which is exactly what you'd expect from an embedded TLS implementation shipped
once and never touched again across a decade of firmware revisions.

# Step 6: trying to fix it "properly", and failing

Two ways to relax the restriction. The first is the Fedora/RHEL sledgehammer,
`update-crypto-policies` - which Ubuntu 26.04 does ship, contrary to what I
assumed at the time. It's in `universe` and not installed by default:

```bash
sudo apt install crypto-policies
sudo update-crypto-policies --set LEGACY
```

That re-enables RC4, SSLv3, TLS 1.0/1.1 and weak DH for every application that
honours the policy - browser, SSH, VPN, all of it. Not something to leave
switched on for one printer. **Caveat: I never verified this one actually took
effect on Ubuntu.** The whole mechanism depends on each library being built to
read its policy back-end, and on Fedora that wiring is a distro-wide invariant;
on Ubuntu I didn't check that it held. So don't read what follows as evidence
that `LEGACY` didn't work - only that I couldn't show it did.

The second is OpenSSL's own config, `/etc/ssl/openssl.cnf`, under the
`[system_default_sect]` Ubuntu ships. Allowing legacy renegotiation and nothing
else:

```
[system_default_sect]
Options = UnsafeLegacyServerConnect
```

Add `CipherString = DEFAULT:@SECLEVEL=0` and `MinProtocol = TLSv1` alongside it
and you have the same blast radius as `LEGACY`, minus the guesswork about
whether it applied. Either way it takes effect on the next process start - no
regeneration step, no daemon to reload.

Reality check: **`cups-browsed`'s IPPS attempt still failed.** One machine kept
showing `(null):631`, the other went back to `implicitclass://` and swallowed
jobs in silence.

There's a good reason for that, and `ldd` spells it out. CUPS does its TLS with
**GnuTLS**, not OpenSSL:

```bash
$ readelf -d /usr/lib/x86_64-linux-gnu/libcups.so.2 | grep NEEDED | grep -E 'gnutls|ssl'
 0x0000000000000001 (NEEDED)  Shared library: [libgnutls.so.30]
```

`libssl.so.3` and `libcrypto.so.3` *do* show up in `ldd $(which cups-browsed)`,
which is misleading - they arrive transitively through `libldap`, itself dragged
in by `libcurl-gnutls`. OpenSSL is loaded into the process and plays no part in
the IPP connection whatsoever. Every minute spent in
`/etc/ssl/openssl.cnf` was tuning a library that wasn't in the code path.

Which forces an honest caveat on the diagnosis: `openssl s_client` proved the
printer is missing RFC 5746, and that's real. But GnuTLS's default policy is
*not* the same as OpenSSL 3.x's - it permits an initial handshake with a peer
lacking secure renegotiation and only refuses to renegotiate later. So the
`TLS fatal alert has been received` that CUPS reports may well have a
*different* proximate cause - protocol floor, cipher list, certificate - than
the error I reproduced with OpenSSL. Same printer, same era of firmware, two
different TLS stacks each unhappy for their own reasons.

The place to look, if you want to keep going, is the GnuTLS priority string -
`%UNSAFE_RENEGOTIATION` and friends, set system-wide via `default-priority-string`
in `/etc/gnutls/config`, and `gnutls-cli` rather than `openssl s_client` as your
probe. I haven't tested that route, so take it as a signpost, not a fix. CUPS
itself gives you no lever here: `client.conf`'s `SSLOptions` covers `AllowRC4`,
`AllowSSL3` and `MinTLS1.x` - cipher and version toggles - and nothing about
renegotiation.

At that point the return on further digging went negative.

# Step 7: the fix that actually works

Stop letting `cups-browsed` choose. Add the printer by hand, over **plain
IPP**, at a known IP:

```bash
# drop the broken auto-discovered queue
sudo lpadmin -x Canon_TS5300_series

# static, plain-IPP queue
sudo lpadmin -p TS5351 -E -v ipp://192.168.1.50:631/ipp/print -m everywhere

# test
lp -d TS5351 /etc/hostname
```

Instant, reliable, on both machines - because it never attempts a TLS handshake
at all. The printer's broken IPPS advertisement is simply never consulted.

`cups-browsed` will keep re-discovering the printer and parking its broken
`implicitclass` queue right next to your working one, so you end up with two
entries that look identical. You don't need to disable the service for that -
just open **Settings → Printers** in Gnome, find your new `TS5351` queue, and
set it as the default from its ⋮ menu. Jobs then go to the static plain-IPP
queue unless something explicitly asks for the other one, and `cups-browsed`
stays available for any other network printers you actually want
auto-discovered.

Two more things. Set a **DHCP reservation** for the printer's MAC in your
router, or `192.168.1.50` will change one day and silently break the static
queue. And undo whichever crypto relaxation you tried - `sudo
update-crypto-policies --set DEFAULT`, or your `/etc/ssl/openssl.cnf` edits -
because there's no reason to run a whole machine at `SECLEVEL=0` for a printer
that isn't even using OpenSSL.

# What I'd do differently

1. **Read `/var/log/cups/error_log` first.** `A TLS fatal alert has been
   received` was sitting there from the very beginning. I went looking for an
   Avahi bug instead, because "printer not found" *feels* like discovery.
2. **`implicitclass://` is not an error.** It's normal multi-backend behaviour.
   Don't build a theory on it.
3. **`openssl s_client` is the right instrument** for deciding whether "can't
   reach the printer" is really a TLS interop problem - it takes CUPS and Avahi
   out of the picture entirely. Just remember that `SECLEVEL` and
   `-legacy_renegotiation` mean your own client can be the one saying no.
4. **Check which TLS library your program actually uses before tuning one.**
   `ldd` on the binary, `readelf -d` on the library. CUPS uses GnuTLS, so an
   afternoon of OpenSSL crypto config edits was never going to move it - and
   `openssl s_client`, useful as it was, is not the same client as the one
   failing.
5. **`unsafe legacy renegotiation disabled` against an embedded device is a
   pattern**, not a one-off. Printers, switches, IoT gadgets: pre-2010 TLS
   server code that no firmware update ever revisited.
6. **The pragmatic fix beat the correct fix by an order of magnitude.** A
   static plain-IPP queue took two minutes. Weakening TLS machine-wide to
   accommodate one printer's fifteen-year-old bug was a bad trade on both
   security and time - and it didn't even work.

# The whole fix, start to finish

```bash
# 1. find the printer's IP (printer touchscreen, or:)
avahi-browse -r _ipp._tcp

# 2. remove the broken auto-discovered queue
sudo lpadmin -x Canon_TS5300_series

# 3. add a static plain-IPP queue
sudo lpadmin -p TS5351 -E -v ipp://192.168.1.50:631/ipp/print -m everywhere

# 4. test
lp -d TS5351 /etc/hostname

# 5. in Gnome Settings -> Printers, set TS5351 as the default queue
#    (cups-browsed's duplicate can stay; it just won't be picked)

# 6. set a DHCP reservation for the printer's MAC in your router
```

If you're staring at `(null):631` and an endless stream of `No suitable
destination host found` - hopefully this saves you the two hours it cost me.
