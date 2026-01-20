---
layout: post
title: Parallels vs UTM
---

I'll compare Parallels 1.9.4 AppStore Edition vs UTM 4.5.4 (100). Time of writing of this blog post: 8. Oct. 2024.
You have two options: UTM and Parallels. Neither is unfortunately perfect.
Know that your guest OSes will be arm64 for best performance.

Parallels is much more expensive. Requires a license which need to be purchased on a yearly
basis and costs 120 eur. Compared to that, UTM App Store edition costs 10 eur one-time only.
Parallels AppStore Edition is massively outdated when compared to Parallels downloaded from
the Parallels web site.

# Linux (Ubuntu)

Parallels starts Ubuntu VM much quicker. On my MacBook Pro M3, Ubuntu fully starts in 10 seconds,
while it takes 23 seconds to start the Ubuntu VM in UTM. However, this looks to be a problem with UTM
drivers: `virtio-gpu-gl-pci` causes Ubuntu to start slowly, while `virtio-gl-pci` starts Ubuntu blazingly
fast.

UTM is able to boot and install off ubuntu server ISO coming straight from Canonical; Parallels
just breaks if you try that, and you have to stick with whatever Parallels downloads for you - potential
privacy/security concerns as the origin of the ISO is unknown.
Also, on Parallels, you're stuck with latest Ubuntu LTS. Parallels is notoriously slow to adopt newer kernels with their
addons - newer kernels either display some scary core dump on bootup (and work),
or the addons will fail to install, making the experience really bad, or even making
Linux unbootable. But, if you're fine with latest

Parallels is closed-source while UTM is open-source.

Both UTM and Parallels support 3d acceleration; even YouTube videos play and seem to be accelerated.
I haven't measured the CPU usage and effectivity of the video play; native video playback on host OS
is definitely most effective and that's what I'm using.

Intellij IDEA works in guest Linux:

* UTM accelerated only runs Intellij in Wayland mode. IDEA works very well in this mode.
  * IDEA in guest MacOS in UTM is very slow and unusable though.
* Parallels runs Intellij in both Wayland and Xorg mode correctly.

Parallels App Store Edition is severely crippled compared to UTM:

* MacOS in VM: UTM auto-magically downloads the installer and installs guest MacOS single-click style,
  while Parallels App Store Edition doesn't support guest MacOS at all - you need to download the full Parallels app for that.
* Parallels App Store Edition doesn't allow you to resize the linux guest hard disk (!!!) -
  you need to create a new disk and mount it somewhere, to get more disk space. This releases all sorts of hell in IDEA -
  IDEA just hates when opening projects from symlinked path (or having .m2/repository on symlinked drive), tries to resolve the files
  and then duplicates them - just crazy quirks all over the place.
* Parallels App Store Edition doesn't support newest Linux kernels. Kernel 6.8 boots,
  but dmesg shows scary `UBSAN: array-index-out-of-bounds in /var/lib/dkms/parallels-tools/1.9.4.23885/build/prl_tg/Toolgate/Guest/Linux/prl_tg/prltg_call.c:143:21`
  segfaults and Ubuntu later shows the crash report window.

Input capturing: Parallels auto-captures the input so that `⌥⇥` and `⌘␣` are captured by linux rather than host MacOS,
and does that seamlessly. Compared to that, UTM requires you to manually capture the input. UTM supports auto-capture but
the mouse cursor jumps to a different place in screen, the mouse movements acceleration changes slightly and is slightly laggy;
the overall feel is that Parallels offers much more polished experience. UTM is however usable.

Both shared folders and clipboard sharing works well; UTM allows only one shared folder though.
Shared folders are mounted automatically by Parallels; in UTM you need to follow the [UTM Linux Sharing Guide](https://docs.getutm.app/guest-support/linux/);
the VirtFS option worked for me well.

When logging in to Linux, UTM would randomly pretend that Ctrl is pressed (or Alt) all the time. That means that you can't
type with keyboard and mouse clicks randomly don't work or show crazy menus. The only way is to logout and log back in.
Very annoying and frustrating. The solution is to avoid pressing any modifier keys until Linux-in-UTM fully
boots and you log in.

## UTM shared folders

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

## UTM Blockers

Some Linux apps **DO NOT WORK** in UTM with 3d acceleration/gpu: the apps will only display a blank rectangle,
and the only workaround I found is to boot with the `virtio-gl-pci` driver. I suspect that all xorg/xwayland apps do that. Examples:

* Citrix Workspace ARM64 remote desktop - no known workaround, disable 3d acceleration.
* `qemu-system` (VM-in-a-VM); workaround: use `-vnc :0` and connect a VNC viewer to `localhost:0`.
* Intellij in xorg mode: enable Wayland mode
* vice and uae c64/amiga emulators: no known workaround, disable 3d acceleration
* Chromium randomly doesn't work: no known workarounds, disable 3d acceleration

Reported as [UTM #6968](https://github.com/utmapp/UTM/issues/6968).

# Windows

You're installing ARM64 Windows, but they are capable of running x86-64 apps very quickly, via some JIT
Rosetta-like mechanism. Parallels runs Windows buttery-smooth, all guest addons work remarkably well.
UTM also installs guest addons; the UI performance is jittery but usable.

## Gaming

Steam games won't work on UTM, neither in Windows nor Linux. Just no.

On Parallels, Windows works buttery-smooth - the virtualization truly is top-notch
in this regard. Windows arm64 installs and works out-of-the-box, and many apps do
work as well. Even x86-64 apps work - Windows has something akin to Rosetta, translating
apps to arm64 in JIT style, and the apps run remarkably quick.

Games generally do run, which is amazing. The downside is that not all games work.
For example Starcraft 2 launches and works, but some missions crawl down to 5 FPS
and stay there (notably Nova missions), making them unplayable.

The best way is to run Steam games on native Linux.

# Conclusion

UTM supports newer Ubuntu and sticks to standards (the SPICE protocol) and is much better privacy-wise but has
its quirks. Parallels (the AppStore Edition) offers a bit more polished experience UI-wise, but
the drivers are closed, they taint kernel and throw strange segfaults on Ubuntu 24.04+.
The support from Parallels is horrible, and the strange UI blinking in Linux and segfaults
persuaded me to switch to UTM.

However, if you need to run X apps then UTM won't work for you. This is quite a blocker.

The best way to run Linux Guest OS by far, is to get a x86-64 machine with AMD Radeon or
Intel integrated GPU, and run the Guest OS via [virt-manager](../virt-manager/).
Added bonus: you'll use the same set of keyboard shortcuts for both host OS and guest OS.
Added bonus: you'll be able to play many (not all) Steam games on Linux; even better,
you can setup a dual-boot of Windows (for games only) and Linux (for everything else).
