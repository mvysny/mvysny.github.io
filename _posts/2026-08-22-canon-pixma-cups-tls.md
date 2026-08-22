---
layout: post
title: "No suitable destination host found: a Canon PIXMA that can't handle TLS 1.3"
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
embedded TLS server hangs up the moment a client offers **TLS 1.3** - and every
current Linux TLS stack offers TLS 1.3 by default. The pragmatic fix, on the
other hand, is embarrassingly boring. Here's the trail, including the dead ends,
because the dead ends are where I lost the two hours - and one of those dead
ends was a confident, wrong diagnosis that I carried for most of them.

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
AES-GCM. Its only defect, from where OpenSSL is standing, is a missing extension
from fifteen years ago - which is exactly what you'd expect from an embedded TLS
implementation shipped once and never touched again across a decade of firmware
revisions.

That was my diagnosis and I was pleased with it. It is also wrong - not about
the missing extension, which is real, but about it being the thing that breaks
CUPS. The give-away is one word in the log line from Step 4: *received*. That
alert came from the printer. Every override I had been reaching for changes what
**my** client is willing to accept.

# Step 6: the right instrument - gnutls-cli

Here is the thing I should have checked before Step 5, never mind before
editing a single config file: **CUPS does its TLS with GnuTLS, not OpenSSL.**

```bash
$ readelf -d /usr/lib/x86_64-linux-gnu/libcups.so.2 | grep NEEDED | grep -E 'gnutls|ssl'
 0x0000000000000001 (NEEDED)  Shared library: [libgnutls.so.30]
```

Which makes the whole of Step 5 a sidestep. Not a *useless* one - `openssl
s_client` did prove that "cannot reach the printer" was really a TLS interop
problem, with CUPS and Avahi taken out of the picture, and that is worth
knowing. But every specific finding it produced was OpenSSL's opinion of this
printer, and OpenSSL is not the program that was failing. `unsafe legacy
renegotiation disabled` is an error message that literally cannot appear in
CUPS, because the code that emits it is never executed. I built an entire theory
on a diagnostic from the wrong stack.

The trap is that OpenSSL genuinely *is* loaded into the process. `libssl.so.3`
and `libcrypto.so.3` both show up in `ldd $(which cups-browsed)` - but they
arrive transitively through `libldap`, itself dragged in by `libcurl-gnutls`,
and they play no part in the IPP connection whatsoever. So every minute spent in
`/etc/ssl/openssl.cnf` - or in `update-crypto-policies`, for that matter - was
spent tuning a library that is mapped into the address space and never called.

So throw away `openssl s_client` and re-run the same march with `gnutls-cli`,
which *is* the library CUPS uses:

```bash
sudo apt install gnutls-bin

gnutls-cli --insecure --priority 'NORMAL'                            -p 631 192.168.1.50
gnutls-cli --insecure --priority 'NORMAL:-VERS-TLS1.3'               -p 631 192.168.1.50
gnutls-cli --insecure --priority 'NORMAL:%UNSAFE_RENEGOTIATION'      -p 631 192.168.1.50
gnutls-cli --insecure --priority 'NORMAL:-VERS-TLS-ALL:+VERS-TLS1.2' -p 631 192.168.1.50
```

`--insecure` on all four is deliberate: the certificate is self-signed, so
without it every probe aborts at verification and tells you nothing about the
handshake itself.

| priority string | outcome |
| --- | --- |
| `NORMAL` | `*** Fatal error: A TLS fatal alert has been received.` `*** Received alert [40]: Handshake failed` |
| `NORMAL:-VERS-TLS1.3` | **handshake completed** |
| `NORMAL:%UNSAFE_RENEGOTIATION` | fails, identically to `NORMAL` |
| `NORMAL:-VERS-TLS-ALL:+VERS-TLS1.2` | **handshake completed** |

Three conclusions, and the first one demolishes Step 5's.

**The printer cannot tolerate a TLS 1.3 ClientHello.** Alert 40 is
`handshake_failure`, and it is *received* - the printer sent it. Offer TLS 1.3
and it hangs up; take 1.3 out of the offer and it is perfectly happy. Note that
the first probe reproduces the CUPS log line from Step 4 character for character,
which is what "I am now debugging the actual failure" looks like.

**Secure renegotiation was a red herring.** GnuTLS defaults to
`%PARTIAL_RENEGOTIATION`: an initial handshake with a peer lacking RFC 5746 is
already permitted, and only a later renegotiation is refused. IPP does one
handshake and never renegotiates. So `%UNSAFE_RENEGOTIATION` changes nothing,
and the missing 2010 extension - real, and genuinely what OpenSSL objected to -
was never what CUPS was objecting to.

**The certificate is fine.**

```
- Certificate[0] info:
 - subject `CN=192.168.1.50', issuer `CN=CanonIJProductXXXXXXXXXXXXXXXX',
   RSA key 2048 bits, signed using RSA-SHA256,
   activated `2018-01-01 00:00:00 UTC', expires `2037-12-31 23:59:59 UTC'
- Description: (TLS1.2-X.509)-(ECDHE-SECP256R1)-(RSA-SHA256)-(AES-256-GCM)
- Handshake was completed
```

RSA 2048, SHA-256, ECDHE, AES-256-GCM. Nothing here needs `SECLEVEL=0`, weak
DH, RC4 or SSLv3. The single thing that has to change is the protocol
*ceiling* - a cap, not a weakening. Every "legacy mode" I had been reaching for
was solving a problem I did not have.

## Telling CUPS about it, attempt one: client.conf

CUPS has a documented lever for exactly this, and the version tokens are sitting
in the library:

```bash
$ strings /usr/lib/x86_64-linux-gnu/libcups.so.2 | grep -E '^(Min|Max)TLS'
MaxTLS1.0
MaxTLS1.1
MaxTLS1.2
MaxTLS1.3
MinTLS1.0
MinTLS1.1
MinTLS1.2
MinTLS1.3
```

So, in `/etc/cups/client.conf` (which did not exist and had to be created):

```
SSLOptions MinTLS1.2 MaxTLS1.2
```

It made no difference. `ipptool` is the right probe here - it goes through
libcups and reads the same `client.conf`, so unlike `gnutls-cli` it tests my
*configuration* and not just the printer:

```bash
$ ipptool -tv ipps://192.168.1.50:631/ipp/print get-printer-attributes.test
ipptool: Unable to connect to "192.168.1.50" on port 631 - A TLS fatal alert has been received.
```

Two things to know before you spend time here. libcups tries
`$HOME/.cups/client.conf` **first** and, if that opens, never falls back to
`/etc/cups/client.conf` - a stale file in your home directory silently wins.
And Ubuntu's libcups is built without debug printfs, so the usual trick of
setting `CUPS_DEBUG_LOG` to dump the priority string CUPS builds is unavailable:

```bash
$ strings /usr/lib/x86_64-linux-gnu/libcups.so.2 | grep CUPS_DEBUG_LOG
$      # nothing
```

## Attempt two: the GnuTLS override, which works

The obvious next idea is `default-priority-string` in `/etc/gnutls/config`. It
does nothing for CUPS, and the binary says why: libcups never asks GnuTLS for
the system default. It builds its own string starting from `NORMAL` and
installs it directly.

```bash
$ nm -D --undefined-only /usr/lib/x86_64-linux-gnu/libcups.so.2 | grep -i priority
     U gnutls_priority_set_direct@GNUTLS_3_4
$ strings /usr/lib/x86_64-linux-gnu/libcups.so.2 | grep -E 'NORMAL$|VERS-TLS-ALL'
NORMAL
:+VERS-TLS-ALL
:-VERS-TLS-ALL
:+VERS-TLS-ALL:+VERS-SSL3.0
```

That also settles the renegotiation question for good: `%UNSAFE_RENEGOTIATION`
is a priority-string modifier, and there is no way to inject one into CUPS short
of `LD_PRELOAD`.

But `/etc/gnutls/config` has a second section that is applied *inside* GnuTLS at
priority-parse time, below the priority string, where no application can
override it. Ubuntu already ships one - which is itself the proof that the
mechanism works:

```
[overrides]
disabled-version = tls1.0
disabled-version = tls1.1
disabled-version = dtls0.9
disabled-version = dtls1.0
```

Add one line:

```
disabled-version = tls1.3
```

restart the daemons:

```bash
sudo systemctl restart cups cups-browsed
```

...and it all works. `gnutls-cli` with an unmodified `NORMAL` priority now
connects - which is the demonstration that the override bites below the priority
string, and therefore reaches every GnuTLS caller regardless of what string it
sets. `ipptool` over `ipps://` returns the attribute list:

```bash
$ ipptool -tv ipps://192.168.1.50:631/ipp/print get-printer-attributes.test
    Get printer attributes using get-printer-attributes    [PASS]
        RECEIVED: 324135 bytes in response
        status-code = successful-ok (successful-ok)
```

And the auto-discovered `cups-browsed` queue - the one that had been swallowing
jobs all afternoon - prints.

Reaching every GnuTLS caller matters more than it sounds, because **three**
separate processes open TLS to this printer: `cups-browsed` during discovery,
`cupsd` itself, and `/usr/lib/cups/backend/ipp`, which `cupsd` forks at print
time. They all link libcups, so they all share the failure - and fixing only
one of them would have moved the wall rather than removed it.

**I have since reverted it.** `disabled-version = tls1.3` in
`/etc/gnutls/config` applies to every GnuTLS consumer on the machine - `wget`,
`curl-gnutls`, glib-networking and with it a good chunk of Gnome. Holding all of
them at TLS 1.2 with ECDHE and AES-GCM is not *dangerous*, but it is a
system-wide change made to accommodate one appliance, and that's the wrong shape
of fix. A properly scoped version is what I'm looking for now - GnuTLS's
`GNUTLS_SYSTEM_PRIORITY_FILE` environment variable, which points at an
alternative config file and could in principle be set for the CUPS units alone,
is the thread I'd pull next.

So: right track at last, wrong blast radius. Which leaves the boring fix still
standing.

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
queue. And if you tried the `/etc/gnutls/config` override from Step 6, revert
it - there's no reason to hold an entire machine at TLS 1.2 for the benefit of
one appliance.

# What I'd do differently

1. **Read `/var/log/cups/error_log` first.** `A TLS fatal alert has been
   received` was sitting there from the very beginning. I went looking for an
   Avahi bug instead, because "printer not found" *feels* like discovery.
2. **`implicitclass://` is not an error.** It's normal multi-backend behaviour.
   Don't build a theory on it.
3. **Note who sent the alert.** "A TLS fatal alert has been **received**"
   means the *server* rejected you. I read that line a dozen times and spent an
   hour relaxing my own client's policy anyway, which by construction could not
   have been the problem.
4. **Probe with the library your program actually links.** `openssl s_client`
   was the right tool for establishing that this was a TLS interop problem at
   all - it takes CUPS and Avahi out of the picture. But the *specific* answer
   it gave was OpenSSL's answer, not CUPS's. `ldd` the binary, `readelf -d` the
   library, then pick your probe: `gnutls-cli` here, not `openssl s_client`.
5. **Two TLS stacks routinely disagree about the same server.** OpenSSL 3.x
   refused this printer over RFC 5746; GnuTLS never cared, because its default
   `%PARTIAL_RENEGOTIATION` permits the initial handshake and IPP never
   renegotiates. Same printer, same firmware, two entirely different objections
   - and only one of them was breaking my printing.
6. **`ipptool` is the end-to-end probe for CUPS.** `gnutls-cli` tells you what
   the *printer* will accept; `ipptool` goes through libcups and the same
   `client.conf`, so it tells you whether your configuration actually reached
   CUPS. Those are different questions and I needed both - the config that
   looked right and did nothing would otherwise have gone unnoticed.
7. **TLS 1.3 intolerance in embedded devices is a pattern**, not a one-off.
   Printers, switches, IoT gadgets: a stack that predates 1.3 and chokes on the
   ClientHello rather than negotiating down. Worth trying `-VERS-TLS1.3` early.
8. **The pragmatic fix beat the correct fix by an order of magnitude.** A static
   plain-IPP queue took two minutes and has no blast radius. The correct fix took
   two hours to find, does work, and is currently reverted because the only
   version of it I have is system-wide.

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
