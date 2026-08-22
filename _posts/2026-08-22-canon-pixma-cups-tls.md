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
current Linux TLS stack offers TLS 1.3 by default. The fix is one line in
`client.conf` - containing one keyword nobody would think to type, because
underneath the printer bug sits a second bug: since CUPS 2.4.12, on Debian and
Ubuntu, `SSLOptions` is silently thrown away. Here's the trail, including the dead ends,
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

# Step 2: find the printer's real address, independent of CUPS

Before debugging anything, get an address you *know* is true, without asking
Avahi or CUPS what they believe. You want two things: the IP, to probe with, and
the printer's mDNS hostname, which is what the final queue will actually use.

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

## Aside: what exactly is `246989000000.local`?

Worth a paragraph, because the fix in Step 7 leans on it.

It looks like a MAC address with the colons stripped - twelve digits, right
length - and that *is* a real convention: Brother advertises
`BRWxxxxxxxxxxxx`, which is literally the MAC. Here it isn't. On this printer
the MAC is `74:38:B7:xx:xx:xx` and the serial number is `KMHH00159`; neither
matches, in format or in content.

It's a field of its own. The printer's **OK menu → System Information** has a
`Printer Name` entry, sitting right next to the serial number, and it reads
exactly `246989000000`. The mDNS hostname is that value with `.local` appended -
nothing more. Canon assigns it at the factory as an independent production
identifier; it is not derived from the MAC or the serial at runtime, which is
why you cannot reconstruct it from anything printed on the case.

Three properties that make it useful:

* **Stable.** It's persistent system information, stored like the serial number.
  It survives reboots, firmware updates, DHCP leases, a factory network reset,
  and moving the printer to a different network.
* **Unique per unit.** The value identifies this one printer. The *scheme* - an
  opaque numeric `Printer Name` published over mDNS - is Canon's own convention,
  not an industry standard; other vendors do their own thing.
* **Opaque.** You have to read it, either from `avahi-browse -r _ipp._tcp`
  above or from **OK menu → System Information → Printer Name** on the device.
  Guessing is hopeless.

Stable and printer-specific is exactly what a static print queue wants.

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

# Step 4: read the error log

One check first, and be pedantic about it: **make sure you are reading the log
of the CUPS that actually owns printing.** A stock Ubuntu 26.04 desktop runs
*two* complete CUPS installations - the Ubuntu deb and the OpenPrinting snap -
each with its own daemon, its own config tree, its own logs and its own
command-line tools, and nothing on the box tells you which of the two your
`lpstat` or your `ipptool` is answering about. On this machine the deb is the
one that prints: it owns port 631 and `/run/cups/cups.sock`, while the snap
steps aside into a proxy mode beside it. Every path in the rest of this post is
the deb's. It is worth being paranoid here, because *every* config file and log
below exists twice and only one copy of each is load-bearing - I edited the
wrong copy for a good stretch of that afternoon, and nothing anywhere warned
me. [Two CUPSes: what a stock Ubuntu 26.04 desktop actually
runs](../ubuntu-two-cupses/) is that story, with a five-second check for
telling them apart.

With that settled: the clue was sitting there the whole time. `cupsd` and the
backends it forks write to the error log; the deb's `cups-browsed` logs to the
journal:

```bash
sudo tail -50 /var/log/cups/error_log
sudo journalctl -u cups-browsed -n 50
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
`/etc/ssl/openssl.cnf` was spent tuning a library that is mapped into the
address space and never called.

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

## Telling CUPS about it, attempt one: client.conf (the actual fix)

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

So, in `/etc/cups/client.conf`:

```
SSLOptions NoSystem MinTLS1.2 MaxTLS1.2
```

Two things about the file before the line itself. **No deb ships it** - nothing
owns `/etc/cups/client.conf`, so it is a file you create, and a
revert-my-experiments pass will delete it again without trace:

```bash
$ dpkg -S /etc/cups/client.conf
dpkg-query: no path found matching pattern /etc/cups/client.conf
```

And libcups tries `$HOME/.cups/client.conf` **first**, never falling back to the
system copy if that one opens - so a stale file in your home directory silently
wins, and `ls -la ~/.cups/client.conf` is worth a look before you conclude
anything about the system one.

Now the line. **`NoSystem` is load-bearing**, and omitting it is what cost me
the afternoon: written the way every write-up and the documentation show it,
`SSLOptions MinTLS1.2 MaxTLS1.2` does nothing whatsoever. Since CUPS 2.4.12
libcups builds its GnuTLS priority string as `@SYSTEM,NORMAL:...`, GnuTLS cannot
resolve that on a system with no `[priorities] SYSTEM` entry - Debian and Ubuntu
have none - and CUPS discards the resulting error, leaving the session on
GnuTLS's default priorities with TLS 1.3 in them. Every `SSLOptions` value goes
in the bin, silently. `NoSystem` drops the `@SYSTEM,` prefix and the rest of the
line starts working. That is
[OpenPrinting/cups#1677](https://github.com/OpenPrinting/cups/issues/1677), it
deserves a post of its own, and until then treat it as the keyword you cannot
leave out.

`ipptool` is the right probe for this, because it goes through libcups and reads
that same `client.conf` - so unlike `gnutls-cli`, it tests my *configuration*
and not just the printer:

```bash
$ ipptool -tv ipps://246989000000.local:631/ipp/print get-printer-attributes.test
    Get printer attributes using get-printer-attributes    [PASS]
        status-code = successful-ok (successful-ok)
```

**That is a pass, over `ipps://`, with nothing but a line in a config file.** No
system-wide crypto policy, no environment variables, no `LD_PRELOAD`.

## Write the same line into the snap's tree as well

One more copy of that file, and it is worth doing even though nothing complains
if you skip it. A stock Ubuntu 26.04 desktop also carries the OpenPrinting CUPS
**snap** - it is what snapped applications such as Chromium print through - and
it has its own libcups with its own compiled-in `ServerRoot`, so it never opens
`/etc/cups/client.conf`. Cap both:

```bash
LINE='SSLOptions NoSystem MinTLS1.2 MaxTLS1.2'

# the deb: the daemon, its backends, and the classic client tools
echo "$LINE" | sudo tee -a /etc/cups/client.conf

# the snap: snapped applications that print
echo "$LINE" | sudo tee -a /var/snap/cups/common/etc/cups/client.conf

sudo systemctl restart cups
```

The snap ships its `client.conf` already, holding a single `ServerName` line, so
there is nothing to create there - only a line to append, and appending is safe:
its launcher rewrites the `ServerName` line on every start and copies everything
else back verbatim. Why there are two CUPSes on a stock desktop at all, and how
to tell which one owns printing on your box, is [a post of its
own](../ubuntu-two-cupses/).

And with those two lines in place, **it prints**. Gnome's print dialog, the
auto-discovered queue, paper. No static queue, no system-wide crypto policy, no
environment variables. The entire two-hour hunt was one missing keyword.

Two honest caveats about what I actually measured. I wrote the line into both
`client.conf` files at the same time, so "the deb's copy is the one that matters
for jobs" is inference from the process tree - the deb `cupsd` forks the deb
backend, which reads `/etc/cups/client.conf` - and not something I separated by
experiment. And keep `ipptool` and printing apart as questions, because
conflating them is what cost me the afternoon: `ipptool` given an `ipps://` URI
runs as me and connects to the printer directly, no daemon involved, while
printing goes through `cupsd` and the `ipp` backend it fork+execs per job. A
pass from the first is not a promise about the second.

One more thing to know before you spend time here: Ubuntu's libcups is built
without debug printfs, so the usual trick of setting `CUPS_DEBUG_LOG` to dump
the priority string CUPS builds is unavailable:

```bash
$ strings /usr/lib/x86_64-linux-gnu/libcups.so.2 | grep CUPS_DEBUG_LOG
$      # nothing
```

## Attempt two: the GnuTLS override - the detour that explained the first one

This is the road I actually took while `client.conf` still looked inert: stop
asking processes nicely and cap the protocol somewhere none of them can opt out
of. It works, and it is worth keeping in the post for one reason - *why* it works
is what eventually explained why attempt one didn't. It bites below the priority
string, which is the one place a setting cannot be overridden by an application,
and, as it turns out, cannot be silently discarded by one either.

The obvious next idea is `default-priority-string` in `/etc/gnutls/config`.
libcups *does* ask GnuTLS for the system default - `gnutls_set_default_priority()`,
unconditionally, on every connection - and then normally overwrites the answer
with a string of its own, assembled from the `SSLOptions` values. Normally. On
this distro that overwrite is precisely the call that fails, so the default is
what you end up connected with after all. I never tested that knob and by the
time I understood the mechanism I had a better lever, so I'll leave it at "not
as inert as I assumed".

The priority string does settle the renegotiation question, though:
`%UNSAFE_RENEGOTIATION` is a priority-string modifier, and there is no way to
inject one into CUPS short of `LD_PRELOAD`.

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
$ ipptool -tv ipps://246989000000.local:631/ipp/print get-printer-attributes.test
    Get printer attributes using get-printer-attributes    [PASS]
        RECEIVED: 324135 bytes in response
        status-code = successful-ok (successful-ok)
```

And the auto-discovered `cups-browsed` queue - the one that had been swallowing
jobs all afternoon - prints.

Reaching every GnuTLS caller matters more than it sounds, because **three**
separate processes open TLS to this printer: `cups-browsed` during discovery,
`cupsd` itself, and `/usr/lib/cups/backend/ipp`, which `cupsd` forks at print
time. They all link libcups, so they all share the failure - and fixing only one
of them would have moved the wall rather than removed it.

**I have since reverted it.** `disabled-version = tls1.3` in
`/etc/gnutls/config` applies to every GnuTLS consumer on the machine - `wget`,
`curl-gnutls`, glib-networking and with it a good chunk of Gnome. Holding all of
them at TLS 1.2 with ECDHE and AES-GCM is not *dangerous*, but it is a
system-wide change made to accommodate one appliance, and that's the wrong shape
of fix.

The properly scoped version turned out to be attempt one plus one keyword, which
retired two fairly elaborate plans I had for narrowing this down. Recording them
in case you ever need to aim GnuTLS policy at a single unit: the library honours
`GNUTLS_SYSTEM_PRIORITY_FILE`, which *replaces* `/etc/gnutls/config` rather than
adding to it, so a private copy has to carry Ubuntu's four `disabled-version`
lines too - and set `GNUTLS_SYSTEM_PRIORITY_FAIL_ON_INVALID=1` beside it, or a
mistyped path fails silently and you're debugging the printer again. A systemd
drop-in with `Environment=` then covers `cupsd` and `cups-browsed`, but `cupsd`
scrubs the environment of the filters and backends it forks, so the `ipp`
backend needs `SetEnv` - which lives in `cups-files.conf`, not `cupsd.conf`.

# Step 7: the alternative, if you would rather not touch TLS at all

This is what I ran on while the TLS side was still a mystery, and it is still the
right answer if you'd rather not think about protocol versions at all - or if a
printer's TLS turns out to be broken in some way no version cap fixes.
Stop letting `cups-browsed` choose. Add the printer by hand, over **plain IPP**,
at its mDNS hostname:

```bash
# drop the broken auto-discovered queue
sudo lpadmin -x Canon_TS5300_series

# static, plain-IPP queue
sudo lpadmin -p TS5351 -E -v ipp://246989000000.local:631/ipp/print -m everywhere

# test
lp -d TS5351 /etc/hostname
```

Instant, reliable, on both machines - because it never attempts a TLS handshake
at all. The printer's broken IPPS advertisement is simply never consulted. The
trade is that IPP traffic on your LAN goes in the clear, which for a home
network and a document you were about to print onto paper anyway is a trade I'd
make without much thought.

`cups-browsed` will keep re-discovering the printer and parking its broken
`implicitclass` queue right next to your working one, so you end up with two
entries that look identical. You don't need to disable the service for that -
just open **Settings → Printers** in Gnome, find your new `TS5351` queue, and
set it as the default from its ⋮ menu. Jobs then go to the static plain-IPP
queue unless something explicitly asks for the other one, and `cups-browsed`
stays available for any other network printers you actually want
auto-discovered.

**Use the hostname, not the IP.** My first version of this queue pointed at
`ipp://192.168.1.50:631/ipp/print` and that is a latent bug: the printer gets
its address from DHCP, so sooner or later the lease moves and the static queue
silently stops working - which is the same symptom I had just spent two hours
chasing. `246989000000.local` doesn't move. You can paper over the IP version
with a DHCP reservation for the printer's MAC, and that works, but it's a second
piece of configuration to remember, in the router rather than on the machine
doing the printing, and it only holds for that one router - move the printer
somewhere else and you're back to hunting down its new address.

The one thing the hostname costs is a runtime dependency on mDNS: Avahi has to
be running and multicast has to reach the printer at print time. That's a real
consideration if your printer lives behind a VLAN boundary or on an AP that
filters multicast - in which case fall back to the IP plus a DHCP reservation.
On a flat home network it's a non-issue, and worth noting: name resolution was
never the broken part here. Step 3's Avahi rabbit hole was noise; `avahi-browse`
resolved this printer correctly the entire time.

And if you tried the `/etc/gnutls/config` override from Step 6, revert it -
there's no reason to hold an entire machine at TLS 1.2 for the benefit of one
appliance.

# What I'd do differently

1. **Establish which process is going to read the file you are editing.** On a
   stock Ubuntu 26.04 desktop `client.conf` exists in three places, and the
   tools you would naturally reach for to check your work answer about
   whichever CUPS shipped them rather than about the one holding your print
   queue. I spent a stretch of that afternoon editing a file no process on this
   machine ever opens - [its own write-up](../ubuntu-two-cupses/).
2. **Read the error log first.** `A TLS fatal alert has been received` was
   sitting there from the very beginning. I went looking for an Avahi bug
   instead, because "printer not found" *feels* like discovery.
3. **`implicitclass://` is not an error.** It's normal multi-backend behaviour.
   Don't build a theory on it.
4. **Note who sent the alert.** "A TLS fatal alert has been **received**"
   means the *server* rejected you. I read that line a dozen times and spent an
   hour relaxing my own client's policy anyway, which by construction could not
   have been the problem.
5. **Probe with the library your program actually links.** `openssl s_client`
   was the right tool for establishing that this was a TLS interop problem at
   all - it takes CUPS and Avahi out of the picture. But the *specific* answer
   it gave was OpenSSL's answer, not CUPS's. `ldd` the binary, `readelf -d` the
   library, then pick your probe: `gnutls-cli` here, not `openssl s_client`.
6. **Two TLS stacks routinely disagree about the same server.** OpenSSL 3.x
   refused this printer over RFC 5746; GnuTLS never cared, because its default
   `%PARTIAL_RENEGOTIATION` permits the initial handshake and IPP never
   renegotiates. Same printer, same firmware, two entirely different objections
   - and only one of them was breaking my printing.
7. **`ipptool` is the end-to-end probe for CUPS.** `gnutls-cli` tells you what
   the *printer* will accept; `ipptool` goes through libcups and the same
   `client.conf`, so it tells you whether your configuration actually reached
   CUPS. Those are different questions and I needed both - a config that looks
   right but is never read would otherwise go unnoticed. Two caveats:
   `ipptool` given an `ipps://` URI goes straight to the printer, so it is a
   test of your client configuration and not of your print path; and it reads
   `~/.cups/client.conf` before the system file, so check that one exists
   nowhere before you trust the result.
8. **TLS 1.3 intolerance in embedded devices is a pattern**, not a one-off.
   Printers, switches, IoT gadgets: a stack that predates 1.3 and chokes on the
   ClientHello rather than negotiating down. Worth trying `-VERS-TLS1.3` early.
9. **A silent no-op is worse than an error.** I found the correct fix in the
   first twenty minutes. It then sat in the right file, on the right machine,
   doing nothing at all, because CUPS handed GnuTLS a priority string GnuTLS
   could not parse and dropped the error on the floor. Everything after that was
   a hunt for the process that was ignoring my configuration - a process which
   did not exist. One `if` around one return value would have turned this whole
   post into a paragraph.

# The whole fix, start to finish

```bash
# 0. cap TLS for CUPS. NoSystem is not optional - see OpenPrinting/cups#1677
LINE='SSLOptions NoSystem MinTLS1.2 MaxTLS1.2'
ls -la ~/.cups/client.conf     # must not exist, or it silently wins
echo "$LINE" | sudo tee -a /etc/cups/client.conf
echo "$LINE" | sudo tee -a /var/snap/cups/common/etc/cups/client.conf
sudo systemctl restart cups
# or even better, REBOOT

# check it from the client side before trusting it
ipptool -tv ipps://246989000000.local:631/ipp/print get-printer-attributes.test
```

That's it - the auto-discovered queue prints from there. If you'd rather stay off
TLS altogether, the Step 7 route instead:

```bash
# 1. find the printer's mDNS hostname
#    (or read it off the printer: OK menu -> System Information -> Printer Name)
avahi-browse -r _ipp._tcp

# 2. remove the broken auto-discovered queue
sudo lpadmin -x Canon_TS5300_series

# 3. add a static plain-IPP queue, by hostname - not by IP, which DHCP will move
sudo lpadmin -p TS5351 -E -v ipp://246989000000.local:631/ipp/print -m everywhere

# 4. test
lp -d TS5351 /etc/hostname

# 5. in Gnome Settings -> Printers, set TS5351 as the default queue
#    (cups-browsed's duplicate can stay; it just won't be picked)
```

If you're staring at `(null):631` and an endless stream of `No suitable
destination host found` - hopefully this saves you the two hours it cost me.
