---
layout: post
title: Ubuntu doesn't boot into GUI - Troubleshooting
---

This article lists a couple of tips to try out. First, let's talk about GRUB since it's responsible
for booting up your Linux. This tips apply to Ubuntu 22.04 and higher.

## GRUB Tips

Perhaps you recently updated a newer kernel
which has trouble booting up (or freezes when trying to activate the GUI). To boot the older kernel,
or to at least drop into the root terminal:

1. Reboot the machine and hold the `shift` key (both left and right shift work). That will cause GRUB to show the boot menu.
2. Select the second option "Advanced options for Ubuntu"
3. Select an older kernel; optionally select the new kernel + recovery mode. You may be able
   to drop into the root terminal, without trying to activate GUI/the GDM login screen.

Another thing to test is to disable splash, perhaps the splash+modesetting is broken in the new kernel.

1. Go into GRUB boot menu.
2. Press the `e` key to edit the boot entry.
3. Go to the `linux` row, remove the trailing `quiet splash` and add `nosplash`

To make the `nosplash` setting permanent, edit the `/etc/default/grub` file, then
modify the `GRUB_CMDLINE_LINUX_DEFAULT` option to `nosplash`, then run `sudo update-grub` to
update GRUB configuration file with these new settings.

## Kernel tips

If your machine freezes, it's always better to reboot it cleanly, by pressing the
[Magic SysRq key combination](https://en.wikipedia.org/wiki/Magic_SysRq_key). The following three
keys are worthy of remembering:

* `Alt+PrintScreen+S` performs a filesystem sync which writes everything to the disk
* `Alt+PrintScreen+U` remounts all filesystems read-only, eliminating risk of corruption
* `Alt+PrintScreen+B` reboots immediately.

It can happen that the machine freezes because of a kernel to panic (crash) in the video driver,
when trying to enter the GUI mode (the login screen).
Once you boot up to the root terminal, you can view the kernel logs via `less /var/log/kern.log`.
The file contains logs also from previous bootups, and it should therefore contain any
previous crashes.

If you identify that the crash is coming from `nouveau` (the open-source Nvidia driver) with the new kernel,
you can try to use the proprietary Nvidia drivers; note this will disable Wayland and
force you to use X11. Try to boot up on older kernel, then open the "Additional drivers"
program and install the proprietary drivers.

Once you have the kernel crash log, you can file a bug in Ubuntu: type `ubuntu-bug linux`
and follow through with the bug report, pasting the kernel log part which contains the crash into the report.

You can also try additional kernel parameters, to disable/modify kernel behavior:
see [kernel parameters](https://www.kernel.org/doc/html/v6.0/admin-guide/kernel-parameters.html) for more info.
Favourite settings:

* noapic
* noacpi
* pci=noacpi
* nomodeset

You add these kernel parameters right after the `nosplash` option into GRUB above.
