---
layout: post
title: "Two CUPSes: what a stock Ubuntu 26.04 desktop actually runs"
date: 2026-08-22 18:14:22 +0300
---

I spent an evening fixing a printer by editing `client.conf`, watched
`ipptool` start working, and then watched printing keep failing. Same machine,
same config file, same protocol. The reason turned out to be that the machine
had **two complete CUPS installations** on it - the Ubuntu deb and the
OpenPrinting snap - and I had been configuring the one that wasn't printing.

One thing to get straight before anything else, because it is easy to read the
paragraph above as a confession: **I didn't build this arrangement, and neither
did you.** A stock Ubuntu 26.04 desktop has both CUPSes. It is what the default
install looks like - there is no leftover experiment to blame, no exotic
decision to un-make, and both halves are there on purpose.

This is a write-up of how that arrangement actually works, because every
troubleshooting guide on the internet assumes there is one CUPS, and on a
current Ubuntu desktop that assumption is no longer safe. The specific bug that
sent me down here is [a Canon PIXMA that can't handle TLS
1.3](../canon-pixma-cups-tls/); this post is only about the two-daemon problem,
which is worth understanding on its own.

# Why there are two, and why it's deliberate

Neither half is something you opt into.

**The deb comes with the desktop.** `ubuntu-desktop-minimal` recommends it, and
Ubuntu installs recommends by default:

```bash
$ apt-cache depends ubuntu-desktop-minimal | grep -i cups
  Recommends: bluez-cups
  Recommends: cups
  Recommends: cups-bsd
  Recommends: cups-client
  Recommends: cups-filters
```

**The snap arrives as somebody else's dependency.** Nobody types `snap install
cups`. Snapped applications that want to print declare the cups snap as a
*default provider*, and snapd pulls it in silently. Chromium does it with a
dummy content interface that exists for no other purpose:

```yaml
# /snap/chromium/current/meta/snap.yaml
  install-cups-runtime-dependency:
    content: foo
    interface: content
    target: $SNAP_DATA/foo
    default-provider: cups
```

The printing itself then goes over snapd's `cups` interface - and the only thing
in the world that provides a slot for that interface is the cups snap. snapd
itself provides `cups-control` (full, unmediated control) but not `cups` (send
a job, nothing else):

```bash
$ snap connections cups          # abridged to the printing rows
Interface      Plug                       Slot                                  Notes
content        -                          cups:install-cups-runtime-dependency  -
cups           chromium:cups              cups:cups                             -
cups-control   thunderbird:cups-control   cups:cups-control                     -
cups-control   cups:cups-host             -                                     -

$ snap interface cups
name:          cups
summary:       allows access to the CUPS socket for printing
documentation: https://snapcraft.io/docs/cups-interface
plugs:
  - chromium
slots:
  - cups        # <- the snap, and nothing else
```

Read the `chromium:cups` and `cups:cups-host` rows together and the whole design
falls out: `chromium:cups` &rarr; `cups:cups` is a snapped application handing its
job to the snap under Snap mediation, and `cups:cups-host` is the snap handing
that job on to the host's CUPS. The snap is a mediation shim. Its own source
says so:

```sh
# Determine if we have a classically installed system CUPS (from
# DEB/RPM/source for example). If so, we will run as a proxy to pass
# through jobs of snapped applications to prevent these applications
# from doing administrative tasks on the system's CUPS, even if the
# system's CUPS has no Snap mediation functionality.
```

So both halves have a job: the deb is the system print service for everything
classic, and the snap is the mediated door that snapped applications knock on so
that they can submit a job without being handed administrative control of your
print system. The two-stack machine is not a misconfiguration, and it isn't two
copies of one thing with one of them redundant. It's the design.

What's missing is any hint, anywhere at the command line, about which half you
are talking to.

# What's on the machine

Two independent stacks, each with its own daemon, its own libcups, its own
config tree, its own logs, and its own command-line tools:

```bash
$ dpkg -l | grep -E '^ii\s+(cups|libcups)' | awk '{print $2, $3}'
cups                 2.4.16-1ubuntu1.3
cups-browsed         2.1.1-0ubuntu3
cups-client          2.4.16-1ubuntu1.3
cups-daemon          2.4.16-1ubuntu1.3
cups-filters         2.0.1-0ubuntu4.1
cups-ipp-utils       2.4.16-1ubuntu1.3
libcups2t64:amd64    2.4.16-1ubuntu1.3
...

$ snap list cups
Name  Version   Rev   Tracking       Publisher
cups  2.4.19-2  1238  latest/stable  openprinting**
```

Different CUPS versions, note - 2.4.16 against 2.4.19. The snap is `strict`
confinement on the `core22` base, so it also gets a different GnuTLS than the
host: 3.7.3 from `core22` versus 3.8.12 on the host. Two stacks that can behave
differently even when configured identically.

Here is the map. Left column is what every guide tells you; right column is
where the snap actually keeps it:

| classic (deb) | snap |
| --- | --- |
| `/etc/cups/cupsd.conf` | `/var/snap/cups/common/etc/cups/cupsd.conf` |
| `/etc/cups/client.conf` | `/var/snap/cups/common/etc/cups/client.conf` |
| `/etc/cups/cups-browsed.conf` | `/var/snap/cups/common/etc/cups/cups-browsed.conf` |
| `/var/log/cups/error_log` | `/var/snap/cups/current/var/log/error_log` |
| `cups-browsed` &rarr; syslog | `/var/snap/cups/current/var/log/cups-browsed_log` |
| `/usr/lib/x86_64-linux-gnu/libcups.so.2` | `/snap/cups/current/lib/libcups.so.2` |
| `/usr/lib/cups/backend/ipp` | `/snap/cups/current/lib/cups/backend/ipp` |
| `/usr/sbin/cupsd` | `/snap/cups/current/sbin/cupsd` |
| `systemctl restart cups cups-browsed` | `sudo snap restart cups` |
| `lpstat`, `lpadmin`, `lp`, `ipptool` | `cups.lpstat`, `cups.lpadmin`, `cups.lp`, `cups.ipptool` |

Both trees are fully populated at the same time. Both `ipp` and `ipps` backends
exist twice; each backend links its own libcups, and therefore reads its own
`client.conf`. That single sentence is the whole bug I opened with.

And this is what makes the arrangement a genuine nightmare to debug: the design
is defensible, but **nothing on the box tells you which daemon honours which
file.** Two `cupsd`s, two `cupsd.conf`s, three `client.conf`s, two sets of
command-line tools with the same names, two error logs - and every single one of
those looks correct and complete when you inspect it on its own. You can open a
config file, confirm the setting is exactly right, restart the service you
believe owns it, and be no closer, because the process that actually reads that
file is the other one. Nothing errors. Nothing warns. The snap's launcher is the
only thing on the machine that even acknowledges the other stack, and it does so
once, silently, at startup - so nothing ever tells you that you are working in
the wrong tree. You just get the old behaviour back, with a more confident
expression on your face.

# Three modes, and the one line that picks between them

The snap doesn't just start a daemon. `/snap/cups/current/scripts/run-cupsd`
first decides *which of three modes* to run in, and the decision is four lines
long:

```sh
PROXY_MODE=NO
SYSTEM_CUPS_SERVER=
rm -f $SNAP_DATA/var/run/proxy-mode
if [ ! -f $SNAP_COMMON/no-proxy ]; then
    # Check if CUPS is installed classically
    if [ -r /etc/cups/cupsd.conf ]; then
        # Mark that we are in proxy mode, to block execution of cups-browsed
        touch $SNAP_DATA/var/run/proxy-mode
        PROXY_MODE=YES
        ...
```

Read that condition carefully, because it is the source of most of the
confusion:

**The test is whether `/etc/cups/cupsd.conf` is *readable*. Not whether the deb
daemon is installed, enabled, or running.** A config file on disk is the entire
signal.

The three modes:

- **standalone** - no deb CUPS detected. The snap binds port 631, takes
  `/run/cups/cups.sock`, and runs its own `cups-browsed`. It is the printing
  system.
- **proxy** - `/etc/cups/cupsd.conf` is readable. The snap binds *no TCP port at
  all*, listens only on its own private socket, does not run `cups-browsed`, and
  spawns `cups-proxyd` to mirror the deb's queues. The deb is the printing
  system; the snap is a shim so that snapped applications get Snap mediation
  instead of talking to an unmediated system CUPS directly.
- **parallel** - `no-proxy` was set, but port 631 is already taken. The snap
  falls back to port 10631 plus its private socket. The script's own comments
  call this "not recommended for production... only intended for development".

The intent is reasonable - the snap deliberately steps aside rather than fight
the system daemon for port 631. The trouble is that nothing tells you which mode
you ended up in unless you go looking.

# What proxy mode actually changes

Everything below is done by `run-cupsd` at startup, to files you may have edited
by hand:

```sh
if [ "${PROXY_MODE}" = "YES" ]; then
    # In proxy mode do not listen on any port but on the domain socket
    # of the Snap's CUPS
    PORT=
    DOMAINSOCKET=$ALTDOMAINSOCKET      # /var/snap/cups/common/run/cups.sock
```

- Every `Listen` and `Port` line is **stripped out of the snap's `cupsd.conf`**.
- `client.conf` is rewritten so `ServerName` points at the private socket.
- `$SNAP_DATA/var/run/proxy-mode` is created as a marker.
- `run-cups-browsed` sees that marker and refuses to start the daemon. It runs
  this instead, purely so that the systemd unit has something to stop:

  ```sh
  # Proxy mode, do not start cups-browsed
  ( while true; do sleep 3600; done ) &
  ```

- `cups-proxyd` is spawned, pointed at whatever it parsed out of the deb's
  `cupsd.conf`:

  ```sh
  exec $PROXY_DAEMON $DOMAINSOCKET $SYSTEM_CUPS_SERVER -l --logdir $SNAP_DATA/var/log &
  ```

  `SYSTEM_CUPS_SERVER` comes from grepping the deb's `cupsd.conf` for `Listen
  /socket`, then `Port N`, then `Listen *:N`, then `Listen host:N`, defaulting to
  `localhost:631`.

On a proxy-mode box that whole arrangement looks like this, and it's worth
knowing what a healthy one looks like so you recognise it:

```
$ ps -eo pid,ppid,args | grep -E '[c]upsd|[c]ups-browsed|[c]ups-proxyd'
 1644     1 /usr/sbin/cupsd -l                                    <- DEB daemon
 1649     1 /bin/sh /snap/cups/1238/scripts/run-cups-browsed
 1651     1 /bin/sh /snap/cups/1238/scripts/run-cupsd
 1719     1 /usr/sbin/cups-browsed                                <- DEB browsed
 2605  1651 cupsd -f -s /var/snap/.../cups-files.conf -c ...      <- SNAP daemon
 2606  1651 cups-proxyd /var/snap/cups/common/run/cups.sock /run/cups/cups.sock -l ...
 2749  1649 /bin/sh /snap/cups/1238/scripts/run-cups-browsed      <- the sleep loop

$ sudo ss -lptne 'sport = :631'
LISTEN 127.0.0.1:631  users:(("cupsd",pid=1644,fd=7))
LISTEN    [::1]:631   users:(("cupsd",pid=1644,fd=6))

$ sudo ss -lpx | grep cups.sock
/var/snap/cups/common/run/cups.sock  users:(("cupsd",pid=2605,fd=6))
/run/cups/cups.sock                  users:(("cupsd",pid=1644,fd=3)),(("systemd",pid=1,fd=89))
```

Two `cupsd` processes, and three lines matching `cups-browsed` of which
exactly one - the deb's - is a real daemon; the other two are the snap's
wrapper script and the `sleep 3600` loop standing in for the daemon it
declined to start. The deb owns both port 631 and the canonical socket.

One detail worth internalising: in **standalone** mode the snap's cupsd listens
on *both* `/run/cups/cups.sock` and its private socket. In proxy and parallel
mode it listens only on the private one. So the private socket is present in all
three modes - which means its existence tells you nothing, and only the
`ServerName` value does.

# The mode is decided once, at snap start

This is the part that produced a genuinely baffling afternoon.

`run-cupsd` evaluates that condition exactly once, when the snap service starts.
It does not watch for the deb appearing or disappearing. So the mode is **sticky
until the next `snap restart cups` or reboot**, and both directions of the
discrepancy are observable:

- Snap started at 16:11 (standalone, owning 631). Deb installed and started at
  17:55. Result: the deb loses the race for port 631 and logs `Unable to open
  listen socket for address 127.0.0.1:631 - Address already in use`, while the
  snap stays standalone - no proxy marker, `ServerName /run/cups/cups.sock`,
  snap `cups-browsed` still running. Installing the deb changed nothing.
- Reboot, both start together at 18:02. Now `/etc/cups/cupsd.conf` is readable
  at snap start, the deb wins 631, and the snap comes up in proxy mode.

Same two packages, same disk, two completely different topologies depending on
boot order. If you install or remove one of the two stacks and don't restart,
what you observe afterwards describes the *previous* arrangement.

(How I got to watch that happen, given that both are supposed to be installed
from the start: months earlier I had run an `apt autoremove --purge ufw cups*`
during an unrelated cleanup, so this box had been snap-only for a while.
Reinstalling the deb during this session put it back into the stock Ubuntu
configuration - and let me observe the arrangement forming in the wrong order
first, then correctly after a reboot.)

# Six things that bite

**1. There are three `client.conf` files, and libcups picks one.** The search
order, straight out of the library:

```bash
$ strings /snap/cups/current/lib/libcups.so.2 | grep -E 'client\.conf|/var/snap'
/var/snap/cups/common/etc/cups
/var/snap/cups/common/etc/cups/ssl
%s/client.conf
%s/.cups/client.conf
```

So: `$HOME/.cups/client.conf` first, then `$ServerRoot/client.conf` - where
`ServerRoot` is compiled in per build, `/etc/cups` for the deb and
`/var/snap/cups/common/etc/cups` for the snap. **If the home file opens, the
system one is never read.** A forgotten `~/.cups/client.conf` silently disables
both of the others, for both stacks.

Note also that **no deb ships `/etc/cups/client.conf` at all**:

```bash
$ dpkg -S /etc/cups/client.conf
dpkg-query: no path found matching pattern /etc/cups/client.conf
```

It's a file you create. Which means it's also a file that a
"revert-my-experiments" cleanup pass will delete without trace, since nothing
owns it.

**2. There are two of every command-line tool, and they read different config.**
With both stacks installed you get `/usr/bin/lpstat` from `cups-client`
*and* `/snap/bin/cups.lpstat`. They are different binaries against different
libcups against different `client.conf`. Worse, given an `ipps://` URI,
`cups.ipptool` talks straight to the printer using the *snap's* config and
bypasses both daemons entirely - so it is not a test of your print path. It was
this exact asymmetry that had me believing a fix worked.

**3. Queue names can be identical while the queues are not.** `cups-proxyd`
mirrors the deb's queues into the snap, so `lpstat -v` and `cups.lpstat -v` can
list the same names. The DeviceURI is what distinguishes them - a `proxy://`
DeviceURI means you are looking at a mirror, and the real device URI (and the
real TLS handshake) lives on the deb side.

**4. There are two error logs.** `/var/log/cups/error_log` and
`/var/snap/cups/current/var/log/error_log`. Whichever one moves when you submit
a job belongs to the daemon that owns printing. That's the fastest empirical
answer to the whole question.

**5. `cups-config` only exists in the snap.** Handy advice like "ask
`cups-config --serverroot` where the config lives" doesn't work for the deb -
`cups-config` isn't in the deb runtime at all, it ships in `libcups2-dev`. On a
box with the complete deb stack installed, the only one present is
`/snap/cups/current/bin/cups-config`, and it will happily tell you about the
snap's paths when you were asking about the deb's.

**6. `apt remove` without `--purge` leaves the snap proxying to nothing.**
Because the trigger is a readable config file rather than a running daemon,
removing `cups-daemon` while leaving `/etc/cups/cupsd.conf` behind pins the snap
in proxy mode permanently, forwarding jobs to a daemon that no longer exists.
The script's own comment calls this out and tells you the fix:

> Also if you disable a system's CUPS but keep its configuration files and want
> to run the Snap's CUPS instead, please create the
> `/var/snap/cups/common/no-proxy` file to force the Snap into standard mode.

# Telling them apart in five seconds

```bash
# 1. Is the snap merely a proxy?
ls /var/snap/cups/current/var/run/proxy-mode

# 2. Which mode does the snap think it is in?
grep ServerName /var/snap/cups/common/etc/cups/client.conf
#   /run/cups/cups.sock                  => standalone
#   /var/snap/cups/common/run/cups.sock  => proxy (or parallel)

# 3. Who actually owns the port and the socket?
sudo ss -lptne 'sport = :631'
sudo ss -lpx | grep cups.sock

# 4. The one that settles it: submit a job and see which log moves.
sudo tail -f /var/log/cups/error_log \
             /var/snap/cups/current/var/log/error_log
```

If the marker exists, stop reading the snap's paths - **configure the deb.**

I wrote all of that up as a read-only probe script,
[`cups-probe.sh`](https://github.com/mvysny/mvysny.github.io/blob/master/cups-probe.sh),
which dumps versions, daemons, port and socket ownership, snap mode, all three
`client.conf` files, both queue views, both logs and the GnuTLS system config in
one pass. `sudo ./cups-probe.sh`. It changes nothing and restarts nothing.

# Can you just have one?

Partly - but not the way I first assumed. "Purge the other one" was going to be
my advice until I read the interfaces, and for one of the two directions it is
wrong.

**Removing the snap costs you snapped-application printing.** Chromium's only
route to a print queue is the `cups` interface, and the only slot for that
interface is the snap. Take the snap away and that connection has nowhere to go;
snapd's own `cups-control` is a different interface that Chromium does not plug.
Nothing degrades gracefully here, and the next snap you install that names cups
as its default provider quietly brings it back anyway.

```bash
# only if you genuinely have no snapped application that prints
sudo snap remove cups
```

**Purging the deb is the one that really collapses to a single stack.** The snap
re-evaluates on restart, finds no `/etc/cups/cupsd.conf`, and comes up
standalone - which means it binds port 631 *and* `/run/cups/cups.sock`, so
classic applications keep working through the socket they already use while
snapped ones keep their mediation. Both constituencies are served by one daemon:

```bash
# purge, so that /etc/cups/cupsd.conf is really gone - remove is not enough
sudo apt purge cups cups-daemon cups-browsed
sudo snap restart cups
```

The catch is that `ubuntu-desktop-minimal` recommends the deb, so you are one
`apt install` of something printing-adjacent away from being back here, without
being told.

**Keeping both and forcing the snap to be the real daemon** is the third option,
and the escape hatch exists for it - but the script's own comments call this mode
under-tested and not recommended for production, so I'd treat it as a debugging
tool rather than a configuration:

```bash
sudo touch /var/snap/cups/common/no-proxy
sudo snap restart cups
```

Leaving the default two-stack arrangement in place is the honest recommendation:
it's what Ubuntu ships and what snapped applications expect. What you owe
yourself instead is the five-second check above, every time - before editing
anything, establish which daemon reads it.

# The worked example

Back to the printer. The Canon needs CUPS to stop offering TLS 1.3, and the
lever for that is a line in `client.conf`:

```
SSLOptions NoSystem MinTLS1.2 MaxTLS1.2
```

`NoSystem` is load-bearing - without it CUPS 2.4.12 and later throw the whole
`SSLOptions` line away without saying so, which is [a separate bug and a
separate story](../canon-pixma-cups-tls/). Assume for the rest of this section
that the line is complete. On this machine that lever exists in three places and
only one of them matters:

- `cups.ipptool -tv ipps://printer:631/ipp/print` is a **snap** binary using the
  **snap's** libcups, so it reads
  `/var/snap/cups/common/etc/cups/client.conf`, and given an `ipps://` URI it
  connects to the printer directly. Putting `SSLOptions` there makes this
  command pass.
- A print job goes to the **deb** `cupsd`, which forks the **deb** backend
  `/usr/lib/cups/backend/ipp`, linked against the deb's libcups, which reads
  `/etc/cups/client.conf`. Whatever you put in the snap's copy, this path never
  reads it.

Which is exactly the split I saw: a passing diagnostic and a printer that
wouldn't print. The diagnostic I was using to check my work was the one tool on
the box that couldn't tell me anything about the path I cared about.

So: put the line in `/etc/cups/client.conf`, add it to the snap's copy too for
the benefit of snapped applications, and `sudo systemctl restart cups` - the
*deb* unit, since restarting the snap doesn't touch it. That prints. Check
`ls -la ~/.cups/client.conf` before you bother, per bite #1: a file there wins
over both.

# The lesson

The generic version of this, which I'll be keeping:

> Before you edit a config file, establish which process is going to read it.

That sounds too obvious to write down. But "CUPS is not printing" quietly
carries the assumption that there is a *the* CUPS, and once two of them are
installed, every command you'd naturally reach for to check your work -
`lpstat`, `ipptool`, even `cups-config` - answers about whichever stack shipped
it, not about the one holding your print queue. The tooling can't warn you,
because from each side the arrangement looks completely normal.
