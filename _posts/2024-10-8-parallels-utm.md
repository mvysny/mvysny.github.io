---
layout: post
title: Parallels vs UTM
---

Parallels is much more expensive. Requires a license which need to be purchased on a yearly
basis and costs 120 eur. Compared to that, UTM App Store edition costs 10 eur one-time only.

Parallels starts Ubuntu VM much quicker. On my MacBook Pro M3, Ubuntu fully starts in 10 seconds,
while it takes 23 seconds to start the Ubuntu VM in UTM.

Parallels correctly shows the kernel boot log messages, while UTM shows the UTM logo until
Ubuntu fully boots.

Both UTM and Parallels support 3d acceleration; even YouTube videos play and seem to be accelerated.
I haven't measured the CPU usage and effectivity of the video play; native video playback on host OS
is definitely most effective and that's what I'm using.

Intellij IDEA works:

* UTM accelerated only runs Intellij in Wayland mode. IDEA works very well in this mode, but the update
  screen doesn't show anything. If IDEA update fails, turn off UTM acceleration.
* Parallels runs Intellij in both Wayland and Xorg mode correctly.

Parallels App Store Edition is severely crippled compared to UTM:

* MacOS in VM: UTM auto-magically downloads the installer and installs guest MacOS single-click style,
  while Parallels App Store Edition doesn't support guest MacOS at all - you need to download the full Parallels app for that.
* Parallels App Store Edition doesn't allow you to resize the linux guest hard disk (!!!) -
  you need to create a new disk and mount it somewhere, to get more disk space.
* Parallels App Store Edition doesn't support newest Linux kernels. Kernel 6.8 boots,
  but dmesg shows scary `UBSAN: array-index-out-of-bounds in /var/lib/dkms/parallels-tools/1.9.4.23885/build/prl_tg/Toolgate/Guest/Linux/prl_tg/prltg_call.c:143:21`
  segfaults and Ubuntu later shows the crash report window.

Input capturing: parallels auto-captures the input so that Alt+tab and Command+Space are captured by linux rather than host MacOS,
and does that seamlessly. Compared to that, UTM requires you to manually capture the input. UTM supports auto-capture but
the mouse cursor moves to a different place in screen, the mouse acceleration changes according to Linux profile;
the overall feel is that Parallels offers much more polished experience. UTM is however usable.

Both shared folders and clipboard sharing works well; UTM allows only one shared folder though.
Shared folders are mounted automatically by Parallels; in UTM you need to follow the [UTM Linux Sharing Guide](https://docs.getutm.app/guest-support/linux/);
the VirtFS option worked for me well.

When logging in to Linux, UTM would randomly pretend that Ctrl is pressed (or Alt) all the time. That means that you can't
type with keyboard and mouse clicks randomly don't work or show crazy menus. The only way is to logout and log back in.
Very annoying and frustrating.

UTM doesn't show the kernel boot log, no matter what Grub/Plymouth settings I use. This gets fucking
annoying when Ubuntu doesn't boot for 2-3 minutes and just appears frozen. The reason is that
`systemd-networkd-wait-online.service` can wait for up to 90 seconds for the network to come online.
Kill that shit with fire:
```bash
$ systemctl disable systemd-networkd-wait-online.service
$ systemctl mask systemd-networkd-wait-online.service
```

