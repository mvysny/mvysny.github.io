---
layout: post
title: New Computer/New Machine Setup
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes.

## OS and Filesystem

Ubuntu 22.04 Desktop installer is now able to create an encrypted block device using
dm-crypt, so it's no longer necessary to use the Ubuntu Server text installer.

Simply download the Desktop Installer ISO and `dd` it to `/dev/sda` (replace with your USB drive).

Boot the Desktop and run `gparted`.
Partition the disk using the GPT partitioning table, and not the old MBR one.
Create three partitions (don't set the fs type just yet and leave it unallocated, we'll
do that in the installer):

1. 2GB `ext4` for `/boot` - unencrypted. [It's better to have a separate /boot even when using ESP](https://www.reddit.com/r/archlinux/comments/ogfa3e/do_i_need_a_boot_partition_for_system_encryption/)
2. 256MB ESP `vfat` for `/boot/efi`
3. Rest of the disk `unallocated` for dm-crypt - the `btrfs` for `/` will go here.
4. No swap yet - we'll swap to a file.

Name the machine after the computer brand & type, e.g. `mavi-lenovo-t14s`.

Install & reboot. Select no updates and just a minimum installation - we'll add
everything later on, after we verify that the system boots :-D

## Post-installation

Create the 2G swapfile according to [btrfs swapfile docs](https://btrfs.readthedocs.io/en/latest/Swapfile.html).

Run `lsblk` to make sure the root fs resides on an encrypted dm-crypt partition; also
run `sudo dmsetup ls --tree -o blkdevname`.

Enable trim: [Enable Discard/Trim for your SSD](../ssd-discard/).

Enable dmesg: edit `/etc/sysctl.d/10-kernel-hardening.conf` and `kernel.dmesg_restrict = 0`.

Make sure there are no btrfs errors: `dmesg|grep -i btrfs`.

Optimize systemd journal: `sudo chattr +C /var/log/journal`

Regarding additional fs flags:
* `user_xattr` is enabled by default on ext4 and btrfs; check with `sudo tune2fs -l /dev/mapper/ubuntu--vg-root`
  and also [user_xattr ubuntu forums thread](https://ubuntuforums.org/showthread.php?t=2400092)
* `extents` - used by default by btrfs; ext4: unknown. There's no longer a mount option `extent` or `extents`,
  probably they are on by default, but it doesn't hurt to turn them on via `tune2fs -O extents`.

Reboot.

## Install basic software

```bash
sudo apt update
sudo apt -V dist-upgrade
sudo snap refresh
sudo apt install git vim htop gparted fish doublecmd-gtk gnome-console gnome-text-editor libreoffice net-tools rhythmbox thunderbird-gnome-support curl whois
sudo update-alternatives --config editor     # select vim.basic
```

Uninstall gedit:
```bash
sudo apt autoremove --purge gedit nautilus-extension-gnome-terminal
```

### gnome console

Follow [How to Install Gnome Console as Default Terminal in Ubuntu 22.04](https://fostips.com/gnome-console-default-terminal-ubuntu-2204/).

### gnome keyboard shortcuts

Open "Keyboard Settings" GNOME settings, "View and customize shortcuts", set:

* "Launch Terminal" to `Super+t`
* "Move Window" set to **Disabled** (press Backspace to clear the shortcut): conflict with Intellij

### gnome text editor

* Settings Cog wheel > Show Line numbers
* Settings Cog wheel > Show Right Margin
* Settings Cog wheel > disable "Text Wrapping"
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

### gnome system monitor extension

Follow [Install System Monitor Extension To Ubuntu Gnome](../ubuntu-system-monitor/).

1. Enable CPU, Memory, Swap and Net
2. Set "Graph Width" to 40 and "Refresh Time" to 500.

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

Create ssh key & press enter to keep the default settings:
```bash
ssh-keygen
```

Upload the public key to [github ssh keys](https://github.com/settings/keys)

### Double Commander

Go to Configuration:

* Colors / File Panels / Text Color: black
* Colors / File types:
  * category name: `executable`, mask: `*`, attributes: `-*x*`, color: `Green`
  * `dir`, `*`, `d*`, `Navy`
  * `symlink`, `*`, `l*`, `Teal`
* Files views / Files views extra / Show system and hidden files
* Folder tabs / "Show tab header also when there is only one tab" - uncheck
* Fonts:
  * Main Font: Ubuntu 11 Regular
  * Viewer font: Monospace 11
* Icons / File panel: 16x16
* Keys / Hot Keys:
  * cm_RunTerm: `F2`
  * cm_PackFiles: `Alt+P`
  * cm_ExtractFiles: `Alt+U`
  * cm_ChangeDirToHome: ` (grave accent)
  * cm_RenameOnly: `F9`
* Tools / Editor:
  * Use External Program;
  * executable: `gnome-text-editor`
  * additional parameters: `-n`

Sort by extension.

### Resilio Sync

Download [Resilio Sync](https://www.resilio.com) from [Desktop download page](https://www.resilio.com/platforms/desktop/);
[direct link to x86-64 binary](https://download-cdn.resilio.com/stable/linux-x64/resilio-sync_x64.tar.gz) and
unzip to `~` and run it: `./rslsync`.

Head to [localhost:8888](http://localhost:8888). Webui runs on localhost only, thus no strong password
is needed: use `v` for both username and password. Use computer hostname as name shown when you send and receive folders.

Create the base folder for rslsync: `cd ~ && mkdir -p "Resilio Sync"`. Now click `+ / Enter a key or link`. On other
computer click "Share" on a folder, then "Key" and "Read & Write". Then select the target folder, e.g.
`/home/mavi/Resilio Sync/muf`. The sync should now start.

### HOME Setup

Copy home files from resilio sync to `~`.

### Intellij

```fish
sudo snap install intellij-idea-ultimate --classic
```

Login to my user account. To restore settings, follow [Sync settings between IDE instances](https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html#IDE_settings_sync).
Make sure to:

1. overwrite local settings from jetbrains account
2. enable "sync plugins silently"

To get rid of fish-related `read-only file system` uncheck `File / Settings / Tools -> Terminal -> un-checking "Shell Integration"`

### Desktop

Create a file named `Startup2.desktop` in `~/Desktop`, with the following contents:
```
[Desktop Entry]
Encoding=UTF-8
Exec=/home/mavi/local/startup.sh
Icon=/usr/share/pixmaps/debian-logo.png
Name=Startup
Terminal=false
Type=Application
Version=1.0
X-DBUS-ServiceName=
X-DBUS-StartupType=
X-KDE-RunOnDiscreteGpu=false
X-KDE-SubstituteUID=false
X-KDE-Username=
```

Make it executable, then right-click it on the Desktop and check "Allow Launching".

### Rhythmbox

* Preferences > Plugins > Disable "Alternative Toolbar", "DAAP Music Sharing", "Last FM", "Portable Players"
* `cd Music && ln -s "../Resilio Sync/muf-music/music" ./`

## GNOME Settings

Go to Settings. Then:

* Appearance > Color: select blue
* Search > disable completely - turn off the main switch in window's caption bar
* Multitasking > Application Switching > Include Apps From Current Workspace only
* Privacy
  * Location Services > Turn on
  * File History & trash
    * Disable File History; also click the "Clear History"
    * Enable "Automatically Delete Trash Content" and "Automatically Delete Temporary Files"
  * Screen Lock: Blank Screen Display: Never; 
* Date & Time: Enable Automatic Time Zone
* Keyboard: Add "Slovak QWERTY" and "Finnish".

### Software & Updates

Go to the "Updates" tab and set:
* When there are other updates: Display Immediately
* Notify me of new Ubuntu version: For any new version

## OS Recovery

Boot Ubuntu 22.04 Desktop Installer.

1. Decrypt the root device: `sudo cryptsetup luksOpen TODO`
2. mount the root fs: TODO
3. mount subvolumes according to fstab
