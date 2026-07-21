---
layout: post
title: Linux Wireless USB dongles
---

Pampered by the generally awesome hardware support straight by the
vanilla linux kernel, I gave a couple of WiFi
WiFi USB dongles a go, unfortunately the result is a bit of a mixed bag. I'm using Ubuntu 23.04
with kernel 6.2.0. 

## TP-Link AC600

* [TP-Link Archer T2U Nano Dual-Band AC600: 14€](https://www.verkkokauppa.com/fi/product/587119/TP-LINK-Archer-T2U-Nano-Dual-band-WiFi-adapteri)
* [linux-hardware 2357:011e](https://linux-hardware.org/?id=usb:2357-011e&page=1)

Doesn't work out-of-the-box. The USB device is recognized and `lsusb` prints the correct name:

```
Bus 001 Device 004: ID 2357:011e TP-Link AC600 wireless Realtek RTL8811AU [Archer T2U Nano]
```

Unfortunately, `ifconfig` doesn't show any new network interface, and `iwconfig` predictably
says on all interfaces that there are no wireless extensions.

I expected this outcome: there's no linux support mentioned on the vendor page. There
are ways to compile a kernel module, but I won't bother trying that. The [linux hardware](https://linux-hardware.org/?id=usb:2357-011e&page=1)
page recommends installing [aircrack-ng/rtl8812au](https://github.com/aircrack-ng/rtl8812au) which looks
pretty straightforward though; unfortunately RISC-V architecture doesn't seem to be supported.

The lack of direct support from Linux kernel is a bit of a pity though: the price is great and the adapter supports both 2.4Ghz and 5Ghz wifi.

## D-Link DWA-121

* [D-Link N150 DWA-121 Pico USB Dongle: 10€](https://www.verkkokauppa.com/fi/product/140427/D-Link-DWA-121-WiFi-adapteri)
* [linux-hardware 2001:331b](https://linux-hardware.org/?id=usb:2001-331b)

I had high expectations from this dongle - someone did mention in the Verkkokauppa forums
that the adapter works with the Raspberry PI computer. Indeed, linux-hardware lists the device as supported,
for quite a long time (since kernel 3.16). `lsusb` shows

```
Bus 001 Device 005: ID 2001:331b D-Link Corp.
```

`dmesg` shows that a network interface has been created, which sounds really promising. Indeed,
`ifconfig -a` shows new interface and `iwconfig` is able to talk to it.
Ubuntu Gnome Network Manager connects to the WiFi properly. Only 2.4Ghz band is supported
though.

The problem is that, after 10 minutes or so, the link quality on the wlan interface drops to 15/100
for no apparent reason, and the wifi basically stops working.
When pulling out the dongle from the machine, the black plastic wrap seems to move a bit,
and the dongle feels warm. I wonder whether it's just my device that looks defective. I'll observe this a bit more.
This could be also caused by the Network Manager, skipping through access points like crazy.
The wifi feels unreliable.
