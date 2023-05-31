---
layout: post
title: Make Ubuntu discoverable as hostname.local on your LAN
---

The `.local` top-level-domain (TLD) is reserved to be used for your LAN. Every machine
has its own hostname, and if configured properly, it is accessible on your LAN by
the name of `hostname.local`.

There are two competing standards, [mDNS/multicast DNS](https://en.wikipedia.org/wiki/Multicast_DNS)
and [LLMNR](https://en.wikipedia.org/wiki/Link-Local_Multicast_Name_Resolution); both use the same principle
of listening to broadcasts. Basically, when a computer needs to resolve `foo.local` to an IP address
it will perform a broadcast query on the LAN; the `foo` machine will then respond to the broadcast
with an answer which contains its IP address.

In order for this to work, you need two things:

1. mDNS or LLMNR needs to be enabled on the machine that's trying to resolve `foo.local` to the IP address.
2. The `foo` machine needs to listen to the broadcasts.

For 1. you can run `resolvectl status` from command line, to check whether there is `+LLMNR` or `+mDNS` on
the appropriate links.

For 2. simply make sure that `avahi-daemon` is installed: `sudo apt install avahi-daemon`. After the daemon
is installed, it immediately starts responding to broadcast requests.
