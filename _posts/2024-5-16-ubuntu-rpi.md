---
layout: post
title: Ubuntu on Raspberry PI
---

Even though RPI Zero 2W is quite limited and 32bit OS would work much better, Ubuntu 24.04+ only ships as arm64
so there's nothing you can do. [Flash a SD Card with arm64 Ubuntu](https://ubuntu.com/download/raspberry-pi) and choose the "Server" option.

> WARNING: Both Ubuntu 24.04+ Server and Core editions only come in 64 bit. 64bit OS
> is more demanding on RAM and you can find your RPI Zero running
> out of memory quickly; you can try to enable swap but swapping to SD Card is very slow
> and will completely trash the performance of the OS. Consider using the 32-bit
> [Raspberry PI OS instead](../raspberry-pi-os/), which has an actively maintained 32-bit version.

## Post-installation

Enable user-accessible dmesg: edit `/etc/sysctl.d/10-kernel-hardening.conf` and `kernel.dmesg_restrict = 0`.

### ext4

Enable trim. You need to enable discard for all of your ext4 partitions: simply add the `discard` option to
`/etc/fstab`. Note that swap on a swap partition will perform discard automatically. Make sure the kernel supports trim on RPI flash card:
`lsblk --discard` should print non-zero value in DISC-GRAN.

Alternatively, disable trim and make sure the [fstrim.service is running](https://askubuntu.com/a/1242804/22996):
```bash
$ systemctl list-timers
```

Also enable `noatime`. Maybe [disable journal](https://raspberrypi.stackexchange.com/questions/169/how-can-i-extend-the-life-of-my-sd-card),
but I wouldn't go that far.

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

### Disk encryption

The Ubuntu Raspberry PI SDCard image comes with two partitions:

1. `/dev/mmcblk0p1` of type `vfat` mounted to `/boot/firmware` - this contains RPI firmware bits which allow RPI to boot up.
2. `/dev/mmcblk0p2` of type `ext4` mounted to `/` which contains the root FS.

While it's possible to [LUKS reencrypt](https://unix.stackexchange.com/a/584275/256417) a partition, you shouldn't,
since RPI firmware doesn't know how to deal with LUKS and won't boot. You can encrypt the home folder though. You have two options:

1. Encrypt home via [ecryptfs](https://ubuntuhandbook.org/index.php/2024/05/encrypt-home-ubuntu-24-04/)
2. Encrypt home via LUKS (TODO link)

Note that the decryption will slow down the RPI, so it's advisable on RPI 5+ only.

### Setup wifi & remote access (ssh)

* Set new hostname, e.g. `rpizero`: `sudo hostnamectl set-hostname rpizero`
* Setup [WiFi via netplan](../ubuntu-netplan-no-networkmanager/).
* Make sure `rpizero.local` host works on your LAN: [Ubuntu LAN Local](../ubuntu-lan-local/)
* Make sure you can ssh to the machine via public key, then disable ssh password access: edit `/etc/ssh/sshd_config` and set `PasswordAuthentication` to `no`, then reload the ssh daemon config via `systemctl reload sshd`.
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

## Scripts

`~/shutdown`:

```bash
#!/bin/bash
set -e -o pipefail
sudo shutdown -h now
```

`~/reboot`:

```bash
#!/bin/bash
set -e -o pipefail
sudo reboot
```

`~/update`:
```bash
#!/bin/bash
set -e -o pipefail
sudo apt update
sudo apt -V dist-upgrade
sudo apt autoremove --purge
# clean residual config
sudo apt purge $(dpkg -l | grep '^rc' | awk '{print $2}')
```

To run these scripts without needing to type in root password, run `sudo visudo` and add this line:
```sudoers
ubuntu ALL=(ALL) NOPASSWD:/usr/bin/apt *, /usr/bin/snap refresh, /usr/sbin/shutdown -h now, /usr/sbin/reboot
```
