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

1. 2GB `btrfs` for `/boot` - unencrypted. [It's better to have a separate /boot even when using ESP](https://www.reddit.com/r/archlinux/comments/ogfa3e/do_i_need_a_boot_partition_for_system_encryption/)
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

Enable user-accessible dmesg: edit `/etc/sysctl.d/10-kernel-hardening.conf` and `kernel.dmesg_restrict = 0`.

Enable trim: [Enable Discard/Trim for your SSD](../ssd-discard/).

### ext4 only

Regarding additional fs flags:
* `user_xattr` is enabled by default on ext4; check with `sudo tune2fs -l /dev/mapper/ubuntu--vg-root`
  and also [user_xattr ubuntu forums thread](https://ubuntuforums.org/showthread.php?t=2400092)
* `extents` - ext4: unknown. There's no longer a mount option `extent` or `extents`,
  probably they are on by default, but it doesn't hurt to turn them on via `tune2fs -O extents`.

### btrfs only

Trim doesn't need to be enabled since
[btrfs by default performs async discard since kernel 6.2](https://btrfs.readthedocs.io/en/latest/Trim.html).

Make sure there are no btrfs errors: `dmesg|grep -i btrfs`.

Optimize systemd journal by disabling copy-on-write (COW): `sudo chattr +C /var/log/journal`

Both user_xattr and extends are enabled automatically for btrfs.

Reboot.

## Install basic software

```bash
sudo apt update
sudo apt -V dist-upgrade
sudo snap refresh
sudo apt install git neovim htop gparted fish doublecmd-qt gnome-text-editor libreoffice net-tools rhythmbox thunderbird-gnome-support curl whois fzf eza endeavour
sudo update-alternatives --config editor     # select neovim
```

*Note:* install `doublecmd-qt` rather than `doublecmd-gtk` since [GTK version doesn't support wayland](https://github.com/doublecmd/doublecmd/issues/927).

Uninstall gedit:
```bash
sudo apt autoremove --purge gedit
```

### gnome console

Keep gnome-terminal. Set the color scheme to:

* Secure machine: Colors from the system theme + slightly transparent background
* Unsecure/VM: Tango Light

### gnome keyboard shortcuts

Open "Keyboard Settings" GNOME settings, "View and customize shortcuts", set:

* "Launchers" / "Launch Terminal" to `Super+t`
* Navigation:
  * "Move Window one workspace to the left" set to **Shift+Super+Page Up**, setting it to the same setting as before.
    This, for some fucking reason, stops capturing **Shift+Ctrl+Alt+Arrow Left** from Intellij
  * "Move Window one workspace to the right" set to **Shift+Super+Page Down**, setting it to the same setting as before.
* "Windows":
  * "Hide window": disabled
  * "Move window": disabled; you can always move window by Win+left-dragging anywhere within the window
  * "Resize window": disabled; you can always resize window by Win+middleclick-dragging near appropriate border of the window

### gnome text editor

* Settings Cog wheel > Show Line numbers
* Settings Cog wheel > Show Right Margin
* Settings Cog wheel > disable "Text Wrapping"
* Settings Cog wheel > disable "Check Spelling"
* Preferences > Appearance: select 2nd row 2nd column.
* Preferences > Highlight current line
* Preferences > Display overview map
* Preferences > Right margin: set to 120
* Preferences > Restore Session: disable

### fish

[Install fish](../fish/).

### Firefox

Add `MOZ_ENABLE_WAYLAND=1` to `/etc/environment` to force Firefox to run on `wayland`
instead of `xwayland`, then reboot. Verify in the `about:support` page: the "Window Protocol"
setting should read "wayland" instead of "xwayland".

Login to firefox account and sync.

### gnome system monitor extension

Follow [Install System Monitor Extension To Ubuntu Gnome](../ubuntu-system-monitor/).

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
  autoSetupRemote = true
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

Install `qgnomeplatform-qt5` to enable proper window borders around doublecmd. Then, edit
`/etc/environment` and add `QT_QPA_PLATFORMTHEME='gnome'`. The borders will be applied after reboot.

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
  * Viewer font: Ubuntu Mono 13
* Icons / File panel: 16x16
* Keys: "Ctrl+Alt+Letters": None
* Keys / Hot Keys:
  * cm_RunTerm: `F2`
  * cm_PackFiles: `Alt+P` (or `⌘P` when in Mac mode)
  * cm_ExtractFiles: `Alt+U` (or `⌘U` when in Mac mode)
  * cm_TargetEqualSource: `Alt+=` (or `⌘=` when in Mac mode)
  * cm_ChangeDirToHome: ` (grave accent)
  * cm_RenameOnly: `F9`
  * cm_Search: `Shift+Alt+F`
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

Install additional Gstreamer plugins:

* `gstreamer1.0-libav` to add support for m4a and mpc
* `gstreamer1.0-plugins-bad` to add support for mod

## GNOME Settings

Go to Settings. Then:

* Appearance > Color: select blue
* Multitasking > Application Switching > Include Apps From Current Workspace only
* Privacy
  * Location Services > Turn on
  * File History & trash
    * Enable "Automatically Delete Trash Content" and "Automatically Delete Temporary Files"
  * Screen Lock: Blank Screen Display: Never 
* Date & Time: Enable Automatic Time Zone
* Keyboard: Add "Slovak QWERTY" and "Finnish".

### Software & Updates

Go to the "Updates" tab and set:
* When there are other updates: Display Immediately
* Notify me of new Ubuntu version: For any new version

## Server Setup

More tips on when you're setting up a server:

* Create a [Byobu Startup](../byobu-startup/) script which runs all necessary stuff in Byobu windows
* [Setup a network using netplan](../ubuntu-netplan-no-networkmanager/)

## Docker

```bash
sudo apt install docker docker-compose
```

Add your user to the docker group:
```bash
sudo usermod -aG docker parallels
```
Reboot, and test it out:
```bash
docker run --rm -ti ubuntu /bin/bash
```

## Terminal

Set Initial terminal size in the "Profile" setting to 160x50.
