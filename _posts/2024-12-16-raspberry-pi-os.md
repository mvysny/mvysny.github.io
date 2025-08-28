---
layout: post
title: Raspberry PI OS (nee-Raspbian) on Raspberry PI (RPI)
---

Even though RPI Zero 2W is quite limited, 32bit OS works really well and is surprisingly
snappy. When running from SDCard, the performance is great but make sure to choose
a fast SDCard which is class C10, U3, V30 and A2. The best way is to get the [official RPI SDCard](https://www.raspberrypi.com/documentation/accessories/sd-cards.html#about).

The [Raspberry Pi OS Documentation](https://www.raspberrypi.com/documentation/computers/os.html) is excellent
and please refer to it whenever something is not clear.

## Post-installation

dmesg is user-accessible, no need to edit `/etc/sysctl.d/10-kernel-hardening.conf` and `kernel.dmesg_restrict = 0`.

### ext4

No need to enable trim on ext4: the SDCard is trimmed automatically periodically since the [fstrim.service is running](https://askubuntu.com/a/1242804/22996):
```bash
$ systemctl list-timers
```

`noatime` is also enabled automatically.

### swap

swap is already enabled.

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

Run `sudo raspi-config`:

* Go to `System Options` / `Wireless LAN` and connect to your WIFI. Note that rpizero only supports 2.4GHz WIFI.
* Set new hostname, e.g. `rpizero`: Go to `System Options` / `Hostname`
* Make sure `rpizero.local` host works on your LAN: [Ubuntu LAN Local](../ubuntu-lan-local/)
* Enable SSH: Go to `Interface Options` / `SSH` and enable it.
* Make sure you can ssh to the machine via public key, then disable ssh password access: edit `/etc/ssh/sshd_config` and set `PasswordAuthentication` to `no`, then reload the ssh daemon config via `systemctl reload sshd`.
* Set the correct time zone: `Localisation Options` / `Timezone`
* Reboot & test that remote ssh via wifi works.

You can now unplug the RPI from your monitor and keyboard and continue the setup via ssh/byobu.

## Install basic software

```bash
sudo apt update
sudo apt -V dist-upgrade
sudo apt install git vim fish net-tools curl whois byobu
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
mavi ALL=(ALL) NOPASSWD:/usr/bin/apt *, /usr/bin/snap refresh, /usr/sbin/shutdown -h now, /usr/sbin/reboot
```

## Fixes

Avahi: disable ipv6 by setting `use-ipv6=no` in `/etc/avahi/avahi-daemon.conf` solves a
race condition which causes avahi to respond to `hostname-2.local` lookups, making the machine unaccessible by `hostname.local`.
More info at [Make Ubuntu discoverable as hostname.local on your LAN](../ubuntu-lan-local/).
