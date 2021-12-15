---
layout: post
title: Raspberry PI 3 and Ubuntu Server aarch64
---

Random thoughts on having the Ubuntu Server 21.10 running on top of Raspberry PI 3.

## Installation

Simply follow the [Raspberry PI Ubuntu Page](https://ubuntu.com/download/raspberry-pi)
tutorial, download appropriate image, flash it and boot it. I'm running aarch64 Ubuntu Server
on my Raspberry PI 3 with 1GB of RAM, however there's no real advantage over aarch32
and aarch32 takes up less disk space and memory, therefore I advise you to go with aarch32.

I'd recommend not to go with Ubuntu Desktop - Raspberry PI 3 is simply not powerful enough /
doesn't have enough RAM to run Ubuntu Desktop properly - both Gnome Shell and KDE
are sluggish as hell.

## Wifi

[Using netplan with ubuntu](https://linuxconfig.org/ubuntu-20-04-connect-to-wifi-from-command-line)
works for me well: when configured properly, Raspberry PI will automatically connect
to wifi on boot and you can simply ssh to it.

I have the following file `/etc/netplan/00-wifi.yaml`:

```yaml
network:
  wifis:
    wlan0:
      dhcp4: true
      optional: true
      access-points:
        "<YOUR_AP_NAME>":
          password: "<YOUR_AP_PASSWORD>"
  version: 2
  renderer: networkd
```

Make sure you have the `netplan.io` package installed. Then, run `sudo netplan --debug apply`
and your wifi should be up - you can verify that by running `ifconfig -a`.

## Controlling GPIO

* Python: see [gpiozero](https://gpiozero.readthedocs.io/en/stable/)
* Kotlin: see [ktgpio-example-app](https://github.com/mvysny/ktgpio-example-app/)
