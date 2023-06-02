---
layout: post
title: How to make a change in `/sys/devices` permanent on Ubuntu
---

[Recently](https://github.com/mvysny/renogy-klient/issues/2) I need to change
the clocksource on Ubuntu 22.04 running on RISC-V LicheeRV Dock to something else,
since the default `timer` was unreliable. The question is, how to make a change to
`/sys/devices` permanent?

At first, I thought to use `sysctl` and modify one of `/etc/sysctl.conf` or `/etc/sysctl.d`
but [that actually only works for `/proc/sys` and not `/sys` sysfs](https://unix.stackexchange.com/questions/652398/how-to-find-sysctl-conf-option-name-from-sys-devices-path).

Alternative was to use `sysfsutils` but the documentation is totally lacking.

How about the good old `/etc/rc.local`? [The systemctl way looks quite complicated though](https://www.linuxbabe.com/linux-server/how-to-enable-etcrc-local-with-systemd).

Cron offers the `@reboot` directive, so it's quite easy to do `sudo crontab -e` then add the following line:
```
@reboot echo riscv_clocksource > /sys/devices/system/clocksource/clocksource0/current_clocksource
```
Verify that cron is enabled:
```bash
sudo systemctl status cron
```
And reboot.
