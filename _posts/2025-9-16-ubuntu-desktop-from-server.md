---
layout: post
title: Installing Ubuntu Desktop from Ubuntu Server
---

As of Ubuntu 25.04, Ubuntu Desktop installer still doesn't support a fully custom
disk partitioning schema with [LUKS/LVM](../luks-lvm-boot/) encryption.
The workaround is to install Ubuntu Server first (the text-based installer
does support all wild combinations), then `apt install ubuntu-desktop`. However,
there are a couple of things to fix afterwards.

## netplan/NetworkManager

[netplan](https://netplan.io/) by default uses [systemd.networkd](https://manpages.ubuntu.com/manpages/bionic/man5/systemd.network.5.html)
to control network interfaces. Using NetworkManager is much easier though, let's switch to that
(otherwise VPN via NetworkManager will refuse to enable itself).

Edit `/etc/netplan/00-installer-config.yaml` and add `renderer: NetworkManager`:
```yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    enp0s5:
      dhcp4: true
  version: 2
  renderer: NetworkManager
```

## Boot-up speed

The server boots up way slower than a desktop. Go through
[Speed up Ubuntu Boot](../speed-up-Ubuntu-boot/).

## Fonts

To fix ugly fonts, install Ubuntu Tweaks. Go to Fonts and make sure the
"Interface Text" is "Ubuntu" and not "Ubuntu Sans".

You may also need to install additional fonts that are not pulled in by `ubuntu-desktop`
meta-package:

* fonts-crosextra-caladea, fonts-crosextra-carlito
* fonts-dejavu
* fonts-linuxlibertine
* fonts-noto-extra, fonts-noto-ui-core
* fonts-sil-gentium
