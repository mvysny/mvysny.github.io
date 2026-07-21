---
layout: post
title: Logitech and linux
---

You can connect Logitech keyboards and mices to Linux either via bluetooth, or the USB dongle (Bolt receiver).
Connecting via Bolt Receiver has the advantage that the keyboard is connected immediately and can be
used in BIOS, or to enter the LUKS disk encryption password upon boot.

# Monitoring battery level

```bash
$ sudo apt install solaar
```

To fix permission issues, run
```bash
$ sudo ln -s /lib/udev/rules.d/60-solaar.rules /etc/udev/rules.d/
```
Reboot and run Solaar.

