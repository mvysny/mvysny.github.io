---
layout: post
title: Setup local wildcard DNS resolution on Ubuntu
---

Say you have a local nginx or traefik, routing traffic to multiple Vaadin apps
based on a hostname, and you want to resolve `*.foo.fake` to `127.0.0.1` to test
http://app1.foo.fake routes to app1 and http://app2.foo.fake routes to app2.
The easiest way is to add entries to `/etc/hosts` but
[/etc/hosts does not support wildcard dns entries](https://stackoverflow.com/questions/20446930/how-to-put-wildcard-entry-into-etc-hosts).

The simplest solution is to add both `app1.foo.fake` and `app2.foo.fake` to `/etc/hosts`,
but that can be tedious when there are many such apps.

A better solution is to [use dnsmasq](https://stackoverflow.com/questions/20446930/how-to-put-wildcard-entry-into-etc-hosts):

```bash
$ sudo apt install dnsmasq
$ sudo vim /etc/dnsmasq.conf   # add address=/foo.fake/127.0.0.1
$ systemctl reload dnsmasq
```
Unfortunately, this is not enough:
```bash
$ ping foo.fake
ping: foo.fake: Name or service not known
$ host foo.fake
Host foo.fake not found: 3(NXDOMAIN)
```
The reason is that systemd-resolved is in charge of DNS resolution and it
won't use your local dnsmasq automatically, as can be seen via `resolvectl status`.
Also see [Linux DNS](../linux-dns/).

The solution is to force `systemd-resolved` to use the local dnsmasq server.
Edit `/etc/systemd/resolved.conf` and set `DNS=127.0.0.1`.
Then, restart `systemd-resolved` and check that your DNS server is now in effect:
```bash
$ sudo systemctl restart systemd-resolved
$ resolvectl status
$ host app1.foo.fake
app1.foo.fake has address 127.0.0.1
```
