---
layout: post
title: Make Ubuntu discoverable as hostname.local on your LAN
---

The `.local` top-level-domain (TLD) is reserved to be used for your LAN. Every machine
has its own hostname, and if configured properly, it is accessible on your LAN by
the name of `hostname.local`. Keywords: avahi, mdns, dns.

There are two competing standards, [mDNS/multicast DNS](https://en.wikipedia.org/wiki/Multicast_DNS)
and [LLMNR](https://en.wikipedia.org/wiki/Link-Local_Multicast_Name_Resolution); both use the same principle
of listening to broadcasts. Basically, when a computer needs to resolve `foo.local` to an IP address
it will perform a broadcast query on the LAN; the `foo` machine will then respond to the broadcast
with an answer which contains its IP address. mDNS is primarily used by Linux, LLMNR is used primarily by Windows.
I'll focus on mDNS.

In order for this to work, you need two things:

1. mDNS needs to be enabled on the client machine that's trying to resolve `foo.local` to the IP address.
2. The `foo` machine needs to listen to the mDNS query broadcasts.

For 1. you can run `ping` from command line, to check whether the machine is discoverable. 
For troubleshooting see [Linux DNS](../linux-dns/) on how to configure Linux client-side DNS resolution.

For 2. simply make sure that `avahi-daemon` is installed: `sudo apt install avahi-daemon`. After the daemon
is installed, it immediately starts responding to broadcast requests.

## Troubleshooting

Verify that `avahi-daemon` is actually running:

```bash
$ ps -ef|grep avahi-daemon
avahi     104107       1  0 12:56 ?        00:00:00 avahi-daemon: running
avahi     104119  104107  0 12:56 ?        00:00:00 avahi-daemon: chroot helper
$ systemctl status avahi-daemon
```

In my case, avahi was not running, and it suddenly sprung to life after I run `systemctl status avahi-daemon`...
wtf systemd?

Make sure to read the [Avahi: Troubleshooting](https://wiki.archlinux.org/title/Avahi#Troubleshooting) article.

In case of host name conflict, avahi adds the `-2` suffix to the host name; you can verify that by ping/ssh
`machine-2.local`. If that works, browse the logs via
`journalctl -u avahi-daemon` and search for the "Host name conflict" line.
You can try a bunch of tips from [this archlinux forum](https://bbs.archlinux.org/viewtopic.php?id=284081), e.g. disable ipv6 for
avahi, or just restart avahi-daemon via `systemctl restart avahi-daemon`. The "Avahi Troubleshooting:
Hostname changes with appending incrementing numbers" mentions this:

This is a [known bug](https://github.com/lathiat/avahi/issues/117) that is caused by a hostname race condition.
One possible workaround is [disabling IPv6](https://github.com/lathiat/avahi/issues/117#issuecomment-302849130)
to attempt to prevent the race condition. If multiple interfaces are present [use allow-interfaces](https://github.com/lathiat/avahi/issues/117#issuecomment-401225716)
to limit Avahi to a single interface. Another possible workaround is to [disable the cache](https://github.com/lathiat/avahi/issues/117#issuecomment-442201162)
to prevent Avahi from checking for host name conflicts altogether, but this prevents Avahi from performing lookups.

In my case (using Raspberry PI OS as of 2025), disabling ipv6 by setting `use-ipv6=no` in `/etc/avahi/avahi-daemon.conf` helped.
