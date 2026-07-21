---
layout: post
title: Speed up Ubuntu boot
---

Run `systemd-analyze blame` to learn which service took the longest to start.

The `systemd-networkd-wait-online.service` waits for the network to start, which is useful for server but useless for desktop.
And it can add 90 seconds waiting time. Disable on desktop: [disable systemd-networkd-wait-online.service](https://askubuntu.com/a/979493/22996):
```bash
$ systemctl disable systemd-networkd-wait-online.service
$ systemctl mask systemd-networkd-wait-online.service
```

Similar thing, `NetworkManager-wait-online.service` caused my boot to stall for 5 seconds. I've disabled and it caused no side-effects:
```bash
$ sudo systemctl disable NetworkManager-wait-online.service
```

`gpu-manager.service` added 5 seconds to the boot time. Apparently [it generates Xorg.conf](https://askubuntu.com/questions/813826/what-does-gpu-manager-do)
which is useless for wayland => disable:
```bash
$ sudo systemctl disable gpu-manager.service
```
