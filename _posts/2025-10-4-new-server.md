---
layout: post
title: New Server Setup with Ubuntu
---

I need to setup new server from time to time, and I always forget all the things that need to be set up.
So, here it goes. Once the Ubuntu server is provisioned, it's usually on ext4 and it's configured
correctly, so no need to modify the fs options.

# Post-installation

Create the 2G swapfile according to [btrfs swapfile docs](https://btrfs.readthedocs.io/en/latest/Swapfile.html).

Enable user-accessible dmesg: edit `/etc/sysctl.d/10-kernel-hardening.conf` and `kernel.dmesg_restrict = 0`.

# Install basic software

```bash
sudo apt update
sudo apt -V dist-upgrade
sudo apt install git neovim htop fish net-tools whois fzf eza
sudo update-alternatives --config editor     # select neovim
```

## fish

[Install fish](../fish/).

## Server Setup

More tips on when you're setting up a server:

* Create a [Byobu Startup](../byobu-startup/) script which runs all necessary stuff in Byobu windows
* [Setup a network using netplan](../ubuntu-netplan-no-networkmanager/)

## Docker

```bash
sudo apt install docker docker-buildx docker-compose-v2
```

Add your user to the docker group:
```bash
sudo usermod -aG docker mavi
```
Reboot, and test it out:
```bash
docker run --rm -ti ubuntu /bin/bash
```

## Scripts

See [Updating Ubuntu Quickly](../updating-ubuntu-quickly/).

