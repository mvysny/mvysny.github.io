---
layout: post
title: New Computer/New Machine Setup with Ubuntu
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes.

# OS and Filesystem

Ubuntu 22.04 Desktop installer is now able to create an encrypted block device using
dm-crypt, so it's no longer necessary to use the Ubuntu Server text installer.

Simply download the Desktop Installer ISO and `dd` it to `/dev/sda` (replace with your USB drive).

Boot the Desktop and run `gparted`.
Partition the disk using the GPT partitioning table, and not the old MBR one.
Create three partitions (don't set the fs type just yet and leave it unallocated, we'll
do that in the installer):

1. 2GB `btrfs` for `/boot` - unencrypted. [It's better to have a separate /boot even when using ESP](https://www.reddit.com/r/archlinux/comments/ogfa3e/do_i_need_a_boot_partition_for_system_encryption/)
2. 256MB ESP `vfat` for `/boot/efi`
3. Rest of the disk `unallocated` for dm-crypt - the `btrfs` for `/` will go here.
4. No swap yet - we'll swap to a file.

Prefer btrfs: even though COW wears down SSD a bit faster, it's also
far more reliable in case of kernel panics; also btrfs by default checksums data
as well, reducing disk corruption.

Name the machine after the computer type, e.g. `mavi-t14s`.

Install & reboot. Select no updates and just a minimum installation - we'll add
everything later on, after we verify that the system boots :-D

## Post-installation

Create the 2G swapfile according to [btrfs swapfile docs](https://btrfs.readthedocs.io/en/latest/Swapfile.html).

Run `lsblk` to make sure the root fs resides on an encrypted dm-crypt partition; also
run `sudo dmsetup ls --tree -o blkdevname`.

Enable trim: [Enable Discard/Trim for your SSD](../ssd-discard/).

### btrfs

Trim doesn't need to be enabled since
[btrfs by default performs async discard since kernel 6.2](https://btrfs.readthedocs.io/en/latest/Trim.html).

Make sure there are no btrfs errors: `dmesg|grep -i btrfs`.

Optimize systemd journal by disabling copy-on-write (COW): `sudo chattr +C /var/log/journal`

Both `user_xattr` and `extends` are enabled automatically for btrfs.

Install `dracut` to replace old tools: `sudo apt install dracut`

Reboot.

## gnome console

[Install Alacritty](https://github.com/mvysny/lazyvim-ubuntu).

## fish

[Install fish](../fish/).

## LazyVim

[Install LazyVim](https://github.com/mvysny/lazyvim-ubuntu).

## Firefox

Install [LibreWolf](https://librewolf.net/).

[Firefox HW Acceleration](../firefox-hw-acceleration/).

## gnome system monitor extension

Follow [Install System Monitor Extension To Ubuntu Gnome](../ubuntu-system-monitor/).

## Commander

See [Commander](../commander/).

## Rhythmbox

* Preferences > Plugins > Disable "Alternative Toolbar", "DAAP Music Sharing", "Last FM", "Portable Players"
* `cd Music && ln -s "../Resilio Sync/muf-music/music" ./`

Install additional Gstreamer plugins:

* `gstreamer1.0-libav` to add support for m4a and mpc
* `gstreamer1.0-plugins-bad` to add support for mod

## GNOME Settings

Go to Settings. Then:

* Multitasking > Application Switching > Include Apps From Current Workspace only
* Appearance > Color: select blue
* Ubuntu Desktop
  * Enhanced Tiling: On
  * Tiling Popup: Off
  * Tile Groups: Off
* Privacy
  * Location Services > Turn on
  * File History & trash
    * Enable "Automatically Delete Trash Content" and "Automatically Delete Temporary Files"
  * Screen Lock: Blank Screen Display: Never 
* Date & Time: Enable Automatic Time Zone
* Region & Language: Manage Installed Languages, add Finnish/Suomi and make it default.
* Keyboard: Add "Slovak QWERTY" and "Finnish".

## Software & Updates

Go to the "Updates" tab and set:
* When there are other updates: Display Immediately
* Notify me of new Ubuntu version: For any new version

Also [Updating Ubuntu Quickly](../updating-ubuntu-quickly/).

## Docker

```bash
sudo apt install docker.io docker-buildx docker-compose-v2
```

Add your user to the docker group:
```bash
sudo usermod -aG docker parallels
```
Reboot, and test it out:
```bash
docker run --rm -ti ubuntu /bin/bash
```

## Fixing Ubuntu Desktop

If you installed Ubuntu Server first,
go through [ubuntu-desktop-from-server](../ubuntu-desktop-from-server/).

## Increase security

[Secure Boot 2](../ubuntu-secure-boot2/)

## Steam

```bash
sudo snap install steam
```
Create a 'gaming' user and set up Steam there.

