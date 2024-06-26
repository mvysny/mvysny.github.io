---
layout: post
title: Ubuntu on Raspberry PI
---

Even though RPI Zero 2W is quite limited and 32bit OS would work much better, Ubuntu 24.04+ only ships as arm64
so there's nothing you can do. [Flash a SD Card with arm64 Ubuntu](https://ubuntu.com/download/raspberry-pi) and choose the "Server" option.

## Post-installation

Enable user-accessible dmesg: edit `/etc/sysctl.d/10-kernel-hardening.conf` and `kernel.dmesg_restrict = 0`.

### ext4

Enable trim. You need to enable discard for all of your ext4 partitions: simply add the `discard` option to
`/etc/fstab`. Note that swap on a swap partition will perform discard automatically. Make sure the kernel supports trim on RPI flash card:
`lsblk --discard` should print non-zero value in DISC-GRAN.

### swap

512mb of RAM isn't enough for running software and apt update at the same time - it will crash
RPI.

```bash
sudo fallocate -l 2G /swap
sudo chmod 0600 /swap
sudo mkswap /swap
sudo swapon /swap
```

Add this to `/etc/fstab`:
```
/swap	none	swap	sw	0	0
```

### Setup wifi & remote access (ssh)

* Set new hostname, e.g. `rpizero`: `sudo hostnamectl set-hostname rpizero`
* Setup [WiFi via netplan](../ubuntu-netplan-no-networkmanager/).
* Make sure `rpizero.local` host works on your LAN: [Ubuntu LAN Local](../ubuntu-lan-local/)
* Make sure you can ssh to the machine via public key, then disable ssh password access.
* Reboot & test that remote ssh via wifi works.

You can now unplug the RPI from your monitor and keyboard and continue the setup via ssh/byobu.

## Install basic software

```bash
sudo apt update
sudo apt -V dist-upgrade
sudo apt install git vim htop fish net-tools curl whois
sudo apt autoremove --purge snap
sudo update-alternatives --config editor     # select vim.basic
```

### fish

```bash
chsh -s /usr/bin/fish
```

To add environment variables, add them at the end of the `~/.config/fish/config.fish` file, e.g.:
```
export PATH="$PATH:$HOME/local"
```
