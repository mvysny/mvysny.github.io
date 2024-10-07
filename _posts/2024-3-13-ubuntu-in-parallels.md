---
layout: post
title: New Machine - Ubuntu in Parallels Apple Silicon
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes. I won't setup any encryption since I expect MacBook disk itself to be already encrypted.

The only way that worked for me is to let Parallels download and install Ubuntu 22.04. Manual installations failed for me:

* None of the [Ubuntu 23.10 ISO arm64 images](https://cdimage.ubuntu.com/releases/23.10/release/) worked for me - they simply wouldn't boot.
* [Ubuntu 24.04 ISO arm64 image](https://cdimage.ubuntu.com/ubuntu/daily-live/current/) would install and boot and
  would work reasonably fast, but not buttery-smooth and parallels guest addons would fail to install (Parallels 19).
  However, this is the right way to use Ubuntu under UTM with GPU acceleration.
* Alternatively you can try to install Ubuntu 23.10 server, then install `ubuntu-desktop` and [go through troubleshooting](../virtual-machines-macbook/)
  to make desktop work, but I wonder what's the point since Ubuntu 22.04 works just as good.

## OS and Filesystem

When auto-installing, Parallels will create two partitions using the GPT partitioning table: 1GB efi and 64GB ext4. I'd argue ext4 is better
for VM disks since btrfs uses COW and would balloon the VM disk size much more than ext4.
Therefore, let's use ext4. It will also create a 2G swapfile, you can resize it later.

Name the machine after its expected usage, e.g. `mavi-macbook-vm-experiments`.

## Post-installation

Enable user-accessible dmesg: edit `/etc/sysctl.d/10-kernel-hardening.conf` and `kernel.dmesg_restrict = 0`.

### ext4

Enable trim. You need to enable discard for all of your ext4 partitions: simply add the `discard` option to
`/etc/fstab`. Note that swap on a swap partition will perform discard automatically. Make sure the VM disk supports trim:
`lsblk --discard` should print non-zero value in DISC-GRAN for `sda`.

Regarding additional fs flags:
* `user_xattr` is enabled by default on ext4; check with `sudo tune2fs -l /dev/mapper/ubuntu--vg-root`
  and also [user_xattr ubuntu forums thread](https://ubuntuforums.org/showthread.php?t=2400092)
* `extents` - ext4: unknown. There's no longer a mount option `extent` or `extents`,
  probably they are on by default, but it doesn't hurt to turn them on via `tune2fs -O extents`.

## Install basic software

```bash
sudo apt update
sudo apt -V dist-upgrade
sudo snap refresh
sudo apt install git vim htop fish doublecmd-qt gnome-text-editor libreoffice net-tools curl whois
sudo apt autoremove --purge rhythmbox thunderbird
sudo update-alternatives --config editor     # select vim.basic
```

*Note:* install `doublecmd-qt` rather than `doublecmd-gtk` since [GTK version doesn't support wayland](https://github.com/doublecmd/doublecmd/issues/927).

Uninstall gedit:
```bash
sudo apt autoremove --purge gedit
```

### gnome keyboard shortcuts

Open "Keyboard Settings" GNOME settings, "View and customize shortcuts", set:

* "Launchers" / "Launch Terminal" to `^T`
* Navigation:
  * "Move Window one workspace to the left" set to **Shift+Super+Page Up**, setting it to the same setting as before.
    This, for some fucking reason, stops capturing **Shift+Ctrl+Alt+Arrow Left** from Intellij
  * "Move Window one workspace to the right" set to **Shift+Super+Page Down**, setting it to the same setting as before.
* "Windows":
  * "Hide window": disabled
  * "Move window": disabled; you can always move window by Win+left-dragging anywhere within the window
  * "Resize window": disabled; you can always resize window by Win+middleclick-dragging near appropriate border of the window

I tend to configure Gnome to swap `Alt`, `Ctrl` and `Meta` keys, so that `^` works as `Meta`, `⌥` works as Alt and `⌘` works as `Ctrl` in guest.
To configure this, follow [Mac-like cursor control: Win/Alt/Ctrl scenario](../mac-like-cursor-control-in-linux/).

In order to fix mouse scrolling speed, open `gnome-tweaks`, "Keyboard & Mouse" and set "Acceleration profile" to "Flat".

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

```bash
chsh -s /usr/bin/fish
```

To add environment variables, add them at the end of the `~/.config/fish/config.fish` file:
```
export M2_HOME="$HOME/local/apache-maven"
export PATH="$PATH:$M2_HOME/bin"
```

### Firefox

Firefox should run in Wayland mode by default; verify in the `about:support` page: the "Window Protocol"
setting should read "wayland" instead of "xwayland".

Make sure to disable "smooth scrolling" in settings.

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
  * cm_PackFiles: `⌘P`
  * cm_ExtractFiles: `⌘U`
  * cm_TargetEqualSource: `⌘=`
  * cm_ChangeDirToHome: ` (grave accent)
  * cm_RenameOnly: `F9`
  * cm_Search: `⇧⌘F`
* Tools / Editor:
  * Use External Program;
  * executable: `gnome-text-editor`
  * additional parameters: `-n`

Sort by extension.

### MacBook

Follow [New MacBook Setup](../new-macbook-setup/).

### Intellij

There's [no IDEA snap for arm64 distro](https://youtrack.jetbrains.com/issue/IDEA-253637/snapcraft.io-Add-ARM64-snap-package-for-Idea-based-IDEs),
therefore you have to download & unpack it manually, then run it from the command-line. IDEA will update itself correctly.

Login to my user account. To restore settings, follow [Sync settings between IDE instances](https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html#IDE_settings_sync).
Make sure to:

1. overwrite local settings from jetbrains account
2. enable "sync plugins silently"

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

### Software & Updates

Go to the "Updates" tab and set:
* When there are other updates: Display Immediately
* Notify me of new Ubuntu version: For LTS only

LTS: the reason is that Parallels only supports Ubuntu 22.04; it shows scary segfaults on Ubuntu 23.10+.
Before upgrading to Ubuntu 24.04, I need to test that it's rock-solid; also this may require Parallels 20+.

## Docker

```bash
sudo apt install docker.io docker-compose
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

## netplan/NetworkManager

[netplan](https://netplan.io/) by default uses [systemd.networkd](https://manpages.ubuntu.com/manpages/bionic/man5/systemd.network.5.html)
to control network interfaces. Using NetworkManager is much easier though, let's switch to that (otherwise VPN via NetworkManager will refuse to enable).
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
sudo snap refresh
```

To run these scripts without needing to type in root password, run `sudo visudo` and add this line:
```sudoers
parallels ALL=(ALL) NOPASSWD:/usr/bin/apt update, /usr/bin/apt -V dist-upgrade, /usr/bin/snap refresh, /usr/sbin/shutdown -h now, /usr/bin/apt autoremove --purge, /usr/sbin/reboot
```

`~/killintellij`:
```bash
#!/bin/bash
set -e -o pipefail

echo "Soft-killing IDEA"
killall idea || echo "IDEA not running"
sleep 3
echo "Hard-killing IDEA"
killall -9 idea || echo "IDEA not running"
sleep 3
echo "Deleting cache"
rm -rf .cache/JetBrains
```

`~/Desktop/IDEA.desktop`:
```
[Desktop Entry]
Encoding=UTF-8
Exec=/home/parallels/local/idea/bin/idea
Icon=/home/parallels/local/idea/bin/idea.svg
Name=IDEA
Terminal=false
Type=Application
Version=1.0
X-DBUS-ServiceName=
X-DBUS-StartupType=
X-KDE-RunOnDiscreteGpu=false
X-KDE-SubstituteUID=false
X-KDE-Username=
```
Then right-click the icon on the desktop and select "Allow Launching".
