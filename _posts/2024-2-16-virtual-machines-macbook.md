---
layout: post
title: Virtual Machines on MacBook
---

I've tested two VMs: [UTM](https://getutm.app/) and Parallels. Testing hardware is
an old MacBook Air 2015 x86-64.

## UTM

You can get UTM also from App Store (which I did), then you'll get automatic updates and you'll
support the developers.

General Settings:

* Application / Prevent system from sleeping -> on
* Input: "Option Is Meta Key" -> ignore this. I thought it swaps "Cmd" and "Alt", allowing
  Cmd to function as Alt and Alt/Option as Super, but I was wrong: [it's some gimmick for Emacs](https://docs.getutm.app/preferences/macos/#option-is-meta-key).
* [To swap "Cmd" and "Alt"](https://unix.stackexchange.com/a/417708/256417),
  causing the Mac keyboard having the same modifier key order as a PC keyboard "Fn, Ctrl, Super, Alt":
  * install `gnome-tweaks`, then "Keyboard & Mouse", "Additional Layout Options", "Alt and Win behavior", "Alt is swapped with Win"
* Input: invert scrolling

VM Settings:

* QEMU / Balloon Device -> on

Additional keyboard shortcuts I [found for Parallels but work for UTM too](https://forum.parallels.com/threads/keyboard-shortcut-for-home-end.208263/):

* Home = Fn+ArrowLeft
* End = Fn+ArrowRight
* PgUp = Fn+ArrowUp
* PgDown = Fn+ArrowDown
* Backspace = Fn+Delete

GPU drivers to use:

* `virtio-gpu-gl-pci` only works with Ubuntu 24.04+ which has newest mesa drivers required for GPU acceleration. Note that Java-based
  apps (such as Intellij IDEA) won't work and will display black rectangle.
* `virtio-gpu-pci` works with any Ubuntu, the acceleration is disabled and the performance is horrible.

Network card:

* Maybe switch to `virtio-net-pci`. TODO investigate the best option.

### Troubleshooting

A lot of these issues comes from the fact that I installed from ubuntu-server image then installed `ubuntu-desktop` package. Probably
should have went with ubuntu-desktop iso instead.

Q: Ubuntu prints `9pnet_virtio: no channels available for device share`

A: No idea what that is. Ubuntu eventually boots up. The messages went away, probably because I uninstalled `lxd-agent-loader` (below).

Q: `lxd-agent.service` fails to start.

A: [lxd](https://wiki.archlinux.org/title/LXD)
`journalctl -u lxd-agent.service` shows that "couldn't mount virtiofs or 9p, failing".
No idea what that is, removed it with `sudo apt autoremove --purge lxd-agent-loader` which fixed this issue.

Q: Boot blocked by "Job systemd-networkd-wait-online.service/start running"

A: `cloud-init` configures `netplan` to initialize network interfaces upon boot.
I've uninstalled `cloud-init` and removed `/etc/netplan/50-cloud-init.yaml`. That didn't help.
Ultimately [systemctl disable systemd-networkd.service](https://askubuntu.com/a/1501504/22996) helped.

## Parallels

TODO
