---
layout: post
title: New Computer/New Machine Setup
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes.

## OS and Filesystem

Ubuntu 22.04 Desktop installer is now able to create an encrypted block device using
dm-crypt, so it's no longer necessary to use the Ubuntu Server text installer.

Boot the Desktop and run `gparted`.
Partition the disk using the GPT partitioning table, and not the old MBR one.
Create three partitions (don't set the fs type just yet and leave it unallocated, we'll
do that in the installer):

1. 2GB `ext4` for `/boot`
2. 256MB `vfat` for `/boot/efi`
3. Rest of the disk `unallocated` for dm-crypt - the `btrfs` for `/` will go here.
4. No swap yet - we'll swap to a file.

Install & reboot. Select no updates and just a minimum installation - we'll add
everything later on, after we verify that the system boots :-D

## Post-installation

Create the 2G swapfile according to [btrfs swapfile docs](https://btrfs.readthedocs.io/en/latest/Swapfile.html).

## Install basic software

```bash
sudo apt install git vim htop gparted
```

### git

Create the `~/.gitconfig` file:
```
[user]
  name = Martin Vysny
  email = mavi@vaadin.com
[alias]
  ci = commit
  st = status
[color]
  ui = auto
[push]
  default = current
  followTags = true
[core]
  editor = vim
  autocrlf = input
[merge]
  conflictstyle = diff3
```
