---
layout: post
title: Raspberry PI 3 and Ubuntu Server aarch64
---

Random thoughts on having the Ubuntu Server 21.10 running on top of Raspberry PI 3, and 23.04 running on Raspberry
PI Zero 2 W.

## Installation

* [Raspberry PI Ubuntu Page](https://ubuntu.com/download/raspberry-pi)
* Tutorial on [how to install Ubuntu server on your RPI](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi)

Download the appropriate image from the download page, flash it according to the tutorial, and boot it. I'm running aarch64 Ubuntu Server
on my Raspberry PI 3 with 1GB of RAM, however there's no real advantage over aarch32
and aarch32 takes up less disk space and memory, therefore I advise you to go with aarch32.

You can either use the `rpi-imager` tool, or flash the microsd card from cmdline:
```bash
xzcat ubuntu-23.04-preinstalled-server-armhf+raspi.img.xz |sudo dd of=/dev/XYZ bs=1M conv=fsync status=progress
```
Ubuntu will resize the filesystem automatically on first boot, to span over the entire microsd card.

I'd recommend not to go with Ubuntu Desktop - Raspberry PI 3 is simply not powerful enough /
doesn't have enough RAM to run Ubuntu Desktop properly - both Gnome Shell and KDE
are sluggish as hell.

The default username/password is `ubuntu`/`ubuntu`, but you can only log in after cloud-init configured the user.
Just wait a bit for a line that says `cloud-init v xyz finished at xyz`.

## Networking

The network may be down since netplan refers to the eth0 interface,
while you will most probably have something starting with `enx7.....`.
List your network interfaces with `ip link show`, then run `sudo dhclient enx7......` to configure
the interface for your network.

## Upgrading & cleaning up

You can remove `snapd`:

```bash
$ sudo apt autoremove --purge snapd
```

Then upgrade the system:
```bash
$ sudo apt update
$ sudo apt -V dist-upgrade
```

If you'll get an error during update that "Release file not valid yet", set the timezone correctly,
[using timedatectl](https://linuxhint.com/set-change-timezone-ubuntu-22-04/):

```bash
$ timedatectl
$ sudo timedatectl set-timezone Europe/Helsinki
```

### Wifi

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

Also see [Ubuntu Netplan no NetworkManager](../ubuntu-netplan-no-networkmanager/).

## Controlling GPIO

* Python: see [gpiozero](https://gpiozero.readthedocs.io/en/stable/)
* Kotlin: see [ktgpio-example-app](https://github.com/mvysny/ktgpio-example-app/)
