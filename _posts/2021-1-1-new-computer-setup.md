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

Name the machine after the computer brand & type, e.g. `mavi-lenovo-t14s`.

Install & reboot. Select no updates and just a minimum installation - we'll add
everything later on, after we verify that the system boots :-D

## Post-installation

Create the 2G swapfile according to [btrfs swapfile docs](https://btrfs.readthedocs.io/en/latest/Swapfile.html).

Run `lsblk` to make sure the root fs resides on an encrypted dm-crypt partition.

Enable trim: [Enable Discard/Trim for your SSD](../ssd-discard/).

## Install basic software

```bash
sudo apt update
sudo apt -V dist-upgrade
sudo apt install git vim htop gparted fish doublecmd gnome-console gnome-text-editor libreoffice
```

Uninstall gedit:
```bash
sudo apt autoremove --purge gedit nautilus-extension-gnome-terminal
```

### gnome console

Follow [How to Install Gnome Console as Default Terminal in Ubuntu 22.04](https://fostips.com/gnome-console-default-terminal-ubuntu-2204/).

### gnome text editor

* Settings Cog wheel > Show Line numbers
* Settings Cog wheel > Show Right Margin
* Preferences > Appearance: select 2nd row 2nd column.
* Preferences > Highlight current line
* Preferences > Display overview map
* Preferences > Right margin: set to 120
* Preferences > Restore Session: disable

### fish

```bash
chsh -s /usr/bin/fish
```

To add environment variables, put them to `~/.config/fish/config.fish`:
```
export M2_HOME=$HOME/local/apache-maven
```

### Firefox

Add `MOZ_ENABLE_WAYLAND=1` to `/etc/environment` to force Firefox to run on `wayland`
instead of `xwayland`, then reboot. Verify in the `about:support` page: the "Window Protocol"
setting should read "wayland" instead of "xwayland".

Login to firefox account and sync.

### git+sshkey

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

Create a ssh key & press enter to keep the default settings:
```bash
ssh-keygen
```

Upload the public key to [github ssh keys](https://github.com/settings/keys)

### Double Commander

TODO

### Resilio Sync

TODO

### Intellij

```fish
sudo snap install intellij-idea-ultimate
```

Login to my user account. To restore settings, follow [Sync settings between IDE instances](https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html#IDE_settings_sync).
Make sure to:

1. overwrite local settings from jetbrains account
2. enable "sync plugins silently"

To get rid of fish-related `read-only file system` uncheck `File / Settings / Tools -> Terminal -> un-checking "Shell Integration"`
