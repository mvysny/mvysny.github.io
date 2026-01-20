---
layout: post
title: New Machine - Ubuntu in Parallels/UTM Apple Silicon/virt-manager
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes. I won't setup any encryption since I expect MacBook disk itself to be already encrypted.

# Getting ISO

## virt-manager

Install virt-manager on host os:
```bash
$ sudo apt install virt-manager
```
This will add your user to libvirt automatically; log out and back in to be able to access the VMs.
Then, simply [download the Ubuntu Desktop ISO](https://ubuntu.com/download/desktop) for x86-64, the newest Ubuntu.

Go to virt-manager settings:

* General > Enable system tray icon
* New VM > x86 Firmware: UEFI
* Console > Resize guest with window: On

## Parallels/arm64

The only way that worked for me is to let Parallels download and install Ubuntu 22.04. Manual installations failed for me:

* None of the [Ubuntu 23.10 ISO arm64 images](https://cdimage.ubuntu.com/releases/23.10/release/) worked for me - they simply wouldn't boot.
* [Ubuntu 24.04 ISO arm64 image](https://cdimage.ubuntu.com/ubuntu/daily-live/current/) would install and boot and
  would work reasonably fast, but not buttery-smooth and parallels guest addons would fail to install (Parallels 19).
  However, this is the right way to use Ubuntu under UTM with GPU acceleration.
* Alternatively you can try to install Ubuntu 23.10 server, then install `ubuntu-desktop` and [go through troubleshooting](../virtual-machines-macbook/)
  to make desktop work, but I wonder what's the point since Ubuntu 22.04 works just as good.

## UTM/arm64

The [UTM Ubuntu](https://docs.getutm.app/guides/ubuntu/) guide is straightforward - you download the Ubuntu Server ARM64 ISO
straight from Canonical and install it. Use Ubuntu 24.04 since it contains newest drivers which will work with UTM 3d-accelerated hardware.
Couple of tips:

* When the installation finishes and you're asked to reboot the machine, the machine freezes. Just power it down and up again.
* Before powering the machine up, remove the CD device, so that the VM boots off the hard drive.
* After installing `ubuntu-desktop` and rebooting, it can take up to 5 minutes for Ubuntu to boot up,
  during which the VM will appear frozen. The reason is that `systemd-networkd-wait-online.service` can wait 90 seconds for network to come up.
* Go through [Speed Up Ubuntu Boot](../speed-up-Ubuntu-boot/)
* Before any change done to the VM that might cause the VM not no boot, clone the VM.

# Installation

The best way is to let Ubuntu wipe the disk and install things automatically. It will create two partitions using the GPT partitioning table: 1GB for EFI, rest for ext4 root.
Go with ext4: btrfs uses COW and would most probably balloon the VM disk size much more than ext4.
Therefore, let's use ext4. It will also create a 2G swapfile, you can resize it later. This is also what Parallels auto-installation
will do.

Name the machine after its expected usage, e.g. `mavi-xyz-vmpar-experiments` or `mavi-xyz-vmutm-base`.

## Post-installation

### ext4

Enable trim. You need to enable discard for all of your ext4 partitions: simply add the `discard` option to
`/etc/fstab`. Note that swap on a swap partition will perform discard automatically. Make sure the VM disk supports trim:
`lsblk --discard` should print non-zero value in DISC-GRAN for `sda`.

Regarding additional fs flags:
* `user_xattr` is enabled by default on ext4; check with `sudo tune2fs -l /dev/mapper/ubuntu--vg-root`
  and also [user_xattr ubuntu forums thread](https://ubuntuforums.org/showthread.php?t=2400092)
* `extents` - ext4: unknown. There's no longer a mount option `extent` or `extents`,
  probably they are on by default, but it doesn't hurt to turn them on via `tune2fs -O extents`.

# Install basic software

```bash
sudo apt update
sudo apt -V dist-upgrade
sudo snap refresh
sudo apt install git lazygit neovim htop fish gnome-text-editor libreoffice net-tools curl whois fzf eza duf errands
sudo apt autoremove --purge rhythmbox thunderbird
sudo update-alternatives --config editor     # select nvim
sudo snap install pinta
```

Uninstall gedit and CUPS (printing support):
```bash
sudo apt autoremove --purge gedit ufw
sudo apt autoremove --purge "cups*"
```

UTM/virt-manager: to enable proper [memory ballooning](https://en.wikipedia.org/wiki/Memory_ballooning),
install [qemu-guest-agent](https://pve.proxmox.com/wiki/Qemu-guest-agent):
```bash
sudo apt install qemu-guest-agent
```
It runs a process named `qemu-ga` via systemd. How to check from guest/host that the ballooning works correctly - unknown yet.

## gnome keyboard shortcuts

Open "Keyboard Settings" GNOME settings, "View and customize shortcuts", set:

* "Launchers" / "Launch Terminal" to `Super+Enter`.
* Navigation:
  * "Move Window one workspace to the left" set to **Shift+Super+Page Up**, setting it to the same setting as before.
    This, for some fucking reason, stops capturing **Shift+Ctrl+Alt+Arrow Left** from Intellij
  * "Move Window one workspace to the right" set to **Shift+Super+Page Down**, setting it to the same setting as before.
* "Windows":
  * "Hide window": disabled
  * "Move window": disabled; you can always move window by Win+left-dragging anywhere within the window
  * "Resize window": disabled; you can always resize window by Win+middleclick-dragging near appropriate border of the window

In order to fix mouse scrolling speed, open `gnome-tweaks`, "Keyboard & Mouse" and set "Acceleration profile" to "Flat".

# Software & Updates

Go to the "Updates" tab and set:
* When there are other updates: Display Immediately
* Notify me of new Ubuntu version: For LTS only

LTS: the reason is that Parallels only supports Ubuntu 22.04; it shows scary segfaults on Ubuntu 23.10+.
Before upgrading to Ubuntu 24.04, I need to test that it's rock-solid; also this may require Parallels 20+.

## Boot Settings (UTM only)

To see the kernel log on boot: see [UTM #6732](https://github.com/utmapp/UTM/discussions/6732).
In short, edit `/etc/default/grub` and set `GRUB_CMDLINE_LINUX_DEFAULT="noquiet console=tty1 systemd.log_target=kmsg` -
that will make UTM show the tty1 on boot. If not, press `⌥←` or `⌥→` to toggle between tty1, tty2, ..., tty12 until you arrive to tty1 and see the boot messages.
Don't forget to run `sudo update-grub` to write changes done to the `GRUB_CMDLINE_LINUX_DEFAULT` variable.

Tips: Never use the `nomodeset` option - the VM no longer initializes the display in UTM and is no longer usable.

Beware though: if you use GPU-accelerated drivers for UTM (which you should), those drivers
are very slow showing/scrolling bootup kernel logs, and will cause the VM bootup time
to increase from 22 seconds to 28 seconds. If you don't need to see those messages
(you usually don't), revert `GRUB_CMDLINE_LINUX_DEFAULT=""`, `sudo update-grub` and reboot.
The downside is that you'll see "Display output is not active" for 20 seconds until
Ubuntu graphical interface boots up.

# Shared Folders

## virt-manager

Read [virt-manager](../virt-manager/).

## UTM

We'll use the [UTM VirtFS shared folder support](https://docs.getutm.app/guest-support/linux/#virtfs).

Run these commands to prepare stuff:
```bash
$ sudo mkdir /mnt/utm
$ sudo apt install bindfs
```
Add this to `/etc/fstab`:
```
# https://docs.getutm.app/guest-support/linux/
share	/mnt/utm	9p	trans=virtio,version=9p2000.L,rw,_netdev,nofail	0	0
# bindfs mount to remap UID/GID
/mnt/utm /home/mavi/shared fuse.bindfs map=501/1000:@20/@1000,x-systemd.requires=/mnt/utm,_netdev,nofail,auto 0 0
```

I'm assuming the user id (UID) of 501 and GID of 20. To figure out these values,
run terminal on your Mac and run `ls -na`: it should list all files in your home
folder and the UID and GID of the owner (you).

