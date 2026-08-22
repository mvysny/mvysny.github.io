# Research notes: filing an Ubuntu bug for the Canon PIXMA / CUPS TLS 1.3 failure

Working document, **not** the bug report itself. Captures the state of the
research so it can be picked up after a reboot.

Related blog post: `_posts/2026-08-22-canon-pixma-cups-tls.md`
Date of research: 2026-08-22.

---

## 1. The bug we want to report

**Environment:** Ubuntu 26.04, CUPS from the `openprinting` snap
(`cups 2.4.19-2`, rev `1238`, `latest/stable`, `core22` base), not a deb.
Printer: Canon PIXMA TS5351, mDNS hostname `246989000000.local`.

**Chain of events:**

1. The printer advertises itself over mDNS as, among other things, both
   `Internet Printer` (plain IPP) and `Secure Internet Printer` (IPPS).
2. `cups-browsed` auto-creates an `implicitclass://` queue and **prefers the
   IPPS route**.
3. The printer's embedded TLS server cannot tolerate a **TLS 1.3 ClientHello** -
   it replies with alert 40 (`handshake_failure`) and hangs up. It is perfectly
   happy with TLS 1.2 + ECDHE + AES-256-GCM; the defect is purely a protocol
   *ceiling* problem, not a weak-crypto problem.
4. CUPS logs `Unable to connect to 246989000000.local:631: A TLS fatal alert has
   been received.` and the job is held, forever, retried forever.
5. **The user is shown nothing at all.** No error dialog, no notification, no
   paper. The queue reports itself as enabled and accepting jobs.

**Two separable defects, worth stating separately in the report:**

- **(a)** `cups-browsed` picks the IPPS advertisement and **never falls back to
  the plain-IPP route that the very same printer advertises in the very same
  mDNS record**, even after the TLS handshake fails deterministically, every
  time, forever. Arguable as a design decision; still wrong here.
- **(b)** The resulting failure **reaches the user as nothing at all**. This is
  the indefensible half and the one most likely to get traction with a triager.
  The expected behaviour is an error at print time, not silence.

Verified facts backing the report (all in the blog post):

- `gnutls-cli --insecure --priority 'NORMAL' -p 631 <ip>` reproduces the CUPS log
  line character for character (`*** Received alert [40]: Handshake failed`).
- `gnutls-cli --insecure --priority 'NORMAL:-VERS-TLS1.3' -p 631 <ip>` completes
  the handshake.
- `NORMAL:-VERS-TLS-ALL:+VERS-TLS1.2` also completes.
- CUPS does its TLS with **GnuTLS**, not OpenSSL
  (`readelf -d .../libcups.so.2 | grep NEEDED` -> `libgnutls.so.30`).
- `SSLOptions MinTLS1.2 MaxTLS1.2` in the *correct* `client.conf`
  (`/var/snap/cups/common/etc/cups/client.conf` - the snap's compiled-in
  `ServerRoot`) **does not help**. Confirmed with `cups.ipptool`. This is a real
  finding, not a wrong-path mistake: the config is loaded and ineffective.
- The only thing that worked was `disabled-version = tls1.3` in the
  `[overrides]` section of `/etc/gnutls/config` - system-wide, wrong blast
  radius, since reverted.
- Pragmatic workaround in use: a static plain-IPP queue,
  `lpadmin -p TS5351 -E -v ipp://246989000000.local:631/ipp/print -m everywhere`.

---

## 2. Verdict of the search: NOT REPORTED

Nothing on Launchpad describes TLS 1.3 intolerance in a printer causing CUPS to
swallow jobs silently. Nothing upstream either.

### Searches run (Launchpad API, ALL statuses incl. Expired / Invalid / Won't Fix)

Method - the Launchpad REST API, which is far more reliable than scraping the
web bug-search pages (the HTML pages kept reporting "There are currently no open
bugs" even for searches that do have hits):

```bash
curl -s -G 'https://api.launchpad.net/devel/ubuntu/+source/cups' \
  --data-urlencode 'ws.op=searchTasks' \
  --data-urlencode 'search_text=TLS' \
  --data-urlencode 'status=New' --data-urlencode 'status=Confirmed' \
  --data-urlencode 'status=Triaged' --data-urlencode 'status=In Progress' \
  --data-urlencode 'status=Incomplete' --data-urlencode 'status=Fix Released' \
  --data-urlencode 'status=Fix Committed' --data-urlencode 'status=Invalid' \
  --data-urlencode "status=Won't Fix" --data-urlencode 'status=Opinion' \
  --data-urlencode 'status=Expired'
```

Drop the `/+source/cups` path segment to search all of Ubuntu.
A reusable script was written to `$SCRATCHPAD/lp.py` (gone after reboot -
recreate from the snippet above; it just loops the above over a list of
`[package, search_text]` pairs).

| package | search text | hits |
| --- | --- | --- |
| `cups` | `TLS` | 6 (see table below) |
| `cups` | `TLS 1.3` | **0** |
| `cups` | `fatal alert` | **0** |
| `cups` | `handshake` | **0** |
| `cups` | `ipps fallback` | **0** |
| `cups` | `TLS handshake printer` | **0** |
| `cups` | `gnutls` | 2 |
| `cups` | `silently` | 12, none relevant |
| `cups` | `PIXMA` | 68, all driver/USB-era noise |
| `cups-browsed` | `TLS` | **0** |
| `cups-browsed` | `handshake` | **0** |
| `cups-browsed` | `silently` | **0** |
| `cups-browsed` | `destination host` | **0** |
| `cups-browsed` | *(everything)* | **18 bugs total, ever** |
| `cups-filters` | `TLS` | **0** |
| `cups-filters` | `No suitable destination host` | 2 |
| `gnutls28` | `TLS 1.3` | 1, unrelated |
| all of Ubuntu | `TLS 1.3 printer` | **0** |
| all of Ubuntu | `cups-browsed TLS` | **0** |
| all of Ubuntu | `printer TLS handshake fails silently` | **0** |

The `cups-browsed` source package has **18 bugs in its entire history** - all
crashes, AppArmor denials, CPU spin, MIR/packaging. Not one mentions TLS.

### Near misses and why each is not our bug

| Bug | Status | Why not |
| --- | --- | --- |
| [#1855595](https://bugs.launchpad.net/bugs/1855595) - "CUPS fails to print to autodetected printers because of cups-browsed error" | Confirmed, filed 2019-12-08, last touched 2022-05-18, `cups-filters` | Same `No suitable destination host found by cups-browsed` string. HP LaserJet CM1415fn + Samsung C48x, Ubuntu 20.04, `implicitclass://` queues. **Symptom only - no diagnosis of the cause.** Workaround given is restarting `cups-browsed` + `cups`, which buys exactly one print job. Pre-dates the snap era. |
| [#1909818](https://bugs.launchpad.net/bugs/1909818) - "Printer stops working with a message 'No suitable destinatin host found by cups-browsed'" | New, filed 2021-01-01, **never touched since**, `cups-filters` | Same string, Brother DCP-9020CDW, Ubuntu 20.10, intermittent rather than deterministic. Crucially the reporter **did** get the message shown in Firefox / Document Viewer - so the silent-failure half of our complaint is not in this report at all. Log shows `Job held for 300 seconds since it could not be sent.` |
| [#1526999](https://bugs.launchpad.net/bugs/1526999) - "cups is intolerant to TLS 1.2" | Invalid, 2015 | Mirror image of ours: CUPS acting as the *server*. Not applicable. |
| [#2160989](https://bugs.launchpad.net/bugs/2160989) - "remote communications using TLS stall for 10 seconds" | New, 2026-07-16 | Backport request for upstream [cups#1128](https://github.com/OpenPrinting/cups/issues/1128) / commit `cdd7cf4`. A 10s stall, not a failure. Unrelated. |
| [#879625](https://bugs.launchpad.net/bugs/879625) - "CUPS fails to request authentication when printing over IPP w/ TLS" | Fix Released, 2011 | Auth prompt regression, Ubuntu 11.04 era. |
| [#374416](https://bugs.launchpad.net/ubuntu/+source/cups/+bug/374416) / [#309314](https://bugs.launchpad.net/ubuntu/+source/cups/+bug/309314) - "Documents silently fail to print" | Expired / Fix Released | 2008-2009, right complaint shape, completely different (pre-IPP-Everywhere) cause. |

### Upstream searches (GitHub, via `gh search issues --repo ...`)

| repo | query | result |
| --- | --- | --- |
| `OpenPrinting/cups-browsed` | `TLS 1.3` | nothing |
| `OpenPrinting/cups-browsed` | `TLS` | only #51 "implicitclass returned status 4/7" |
| `OpenPrinting/cups-browsed` | `fallback ipp` | nothing |
| `OpenPrinting/cups-browsed` | `ipps` | #41, #57, #58, #51, #10 - queue churn, none TLS |
| `OpenPrinting/cups` | `TLS 1.3` | #1497, #1217, #606, #104 - all unrelated |
| `OpenPrinting/cups` | `TLS` | #1128 (10s hang, closed) is the closest; nothing about 1.3 intolerance |
| `OpenPrinting/cups-filters` | `TLS` | #620 "cups-browsed does not use encryption" - *opposite* direction |
| `OpenPrinting/cups-snap` | `TLS` / `TLS 1.3` | nothing |
| Debian BTS | `cups-browsed` package page | nothing relevant |

Note: `gh search issues 'repo:Owner/Name text'` does **not** work - the repo
qualifier must be passed as `--repo Owner/Name` with the search terms as the
positional argument, otherwise gh quotes the whole thing as one repo name.

---

## 3. Bonus find worth folding into the blog post

[**Bug #2028459**](https://bugs.launchpad.net/ubuntu/+source/cups/+bug/2028459) -
"cups apparmor: read access to /etc/gnutls/config" - **Confirmed, still open**,
filed 2023-07-23, last touched 2024-02-25.

On deb CUPS, AppArmor has denied `cupsd` and `cups-browsed` reading
`/etc/gnutls/config`:

```
apparmor="DENIED" operation="open" class="file" profile="/usr/sbin/cupsd"
  name="/etc/gnutls/config" pid=11222 comm="cupsd" requested_mask="r" denied_mask="r"
apparmor="DENIED" operation="open" class="file" profile="/usr/sbin/cups-browsed"
  name="/etc/gnutls/config" pid=11224 comm="cups-browsed" requested_mask="r" denied_mask="r"
```

This is a **second way the Step 6 fix can be loaded-but-inert**, distinct from
the `client.conf` path problem, and it is checkable in one line:

```bash
journalctl -k | grep 'apparmor.*gnutls'
```

Fits naturally next to the post's "this config was loaded and did not help"
paragraph. (Our machine is on the snap, whose AppArmor profile is a different
one, so this did not bite us - but it will bite deb readers following Step 6.)

---

## 4. Where to file

**Snag:** on a snap-only machine `ubuntu-bug cups-browsed` has nothing to attach
to - there is no deb `cups-browsed` installed, so apport cannot produce a
payload. And the CUPS snap is published by `openprinting`, not Canonical.

Plan - file **both**:

1. **Launchpad, `cups` source package** - https://bugs.launchpad.net/ubuntu/+source/cups/+filebug
   Ubuntu 26.04 ships this stack by default, so the UX failure is Ubuntu's to
   own. Use the **web form**, since apport will not generate a report for a snap.
   Consider also adding a `cups-browsed` (Ubuntu) task, since defect (a) lives
   there.
2. **https://github.com/OpenPrinting/cups-snap/issues** - where the snap's
   actual maintainers read. Possibly better routed to
   `OpenPrinting/cups-browsed` for defect (a).

Cross-link the two, and link the blog post from both.

## 5. Next step

Draft the report text. Frame it as the two separable defects (a) and (b) from
section 1, leading with **(b) - silent failure** - as the headline, because it
is the indefensible one; (a) is arguable design and will attract debate that
buries the report.

Not yet done: the draft itself, and the actual filing (needs a Launchpad login
in a browser).
