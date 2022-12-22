---
layout: post
title: Custom DNS on your LAN
---

The DNS Relay functionality on the Arris Cable Modem/Router/whatever is a fucking disaster - it's slow as hell
and randomly stops working. I therefore set up my own DNS relay server on my LAN.

The steps are as follows:

1. Have an always-up machine with a fixed IP. If your network is `192.168.0.x`, then
   configure your Arris router to allocate `192.168.0.10-254` IPs via DHCP, then configure
   the machine with a fixed IP of `192.168.0.2` via [Ubuntu netplan](../ubuntu-netplan-no-networkmanager/).
2. Install bind9 on that machine and set it up according to [Ubuntu DNS](https://ubuntu.com/server/docs/service-domain-name-service-dns).
   We'll use the bind dns server as Caching Nameserver: simply add your DSP DNS IPs (just google for your DSP name + 'dns')
   to the list of `forwarders{}` of `/etc/bind/named.conf.options`. Verify via `sudo netstat -tnlp` that
   `named` listens on `192.168.0.2:53`.
3. Test the server out: from some other machine, run `host -v google.com 192.168.0.2` and verify you're getting good results.
   Also see [Linux DNS](../linux-dns/).
4. Configure Arris to offer the new DNS via DHCP: go to its settings and make sure to:
    * allocate `192.168.0.10-254` IPs via DHCP, leaving space for the DNS machine with fixed IP `192.168.0.2`
    * Disable DNS relay
    * Override DNS servers and use just one: `192.168.0.2`
5. Reboot your notebook and test. The notebook should have received IP of 192.168.0.10 or larger,
   and should use the `192.168.0.2` DNS directly.
