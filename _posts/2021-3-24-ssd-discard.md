---
layout: post
title: Enable Discard/Trim for your SSD
---

After Linux is installed on your SSD, don't forget to enable the Discard operation,
to let your SSD know which blocks are free to be reclaimed.

## Checking the `trim` support

In order to check that the SSD properly supports the discard command, run

```bash
$ lsblk --discard
NAME   DISC-ALN DISC-GRAN DISC-MAX DISC-ZERO
sdc           0        4K       4G         0
├─sdc1        0        4K       4G         0
└─sdc2        0        4K       4G         0
```

If the DISC-GRAN and DISC-MAX are non-zero, discard is supported for that particular drive.

However, that's not enough. You must make sure to check that trim is supported for
the block device hosting your root filesystem (and possibly other filesystems, e.g. `/home` etc).
See tips below for enabling trim all the way for the most common cases.

If you have installed your Linux into a LVM, then you need to
configure LVM to pass-through the Discard operation. Edit `/etc/lvm/lvm.conf`
and make sure the `devices{}` section contains `issue_discards = 1`.

Alternatively if you're using dm-crypt, edit `/etc/crypttab` and make sure the `discard` option is there.

Finally, you need to enable discard for all of your ext4 partitions: simply add the `discard` option to
`/etc/fstab`. Note that swap on a swap partition will perform discard automatically.

Please see the excellent [SSD Optimization](https://wiki.debian.org/SSDOptimization)
article for more details.

## Running `trim` manually

Simply run the `sudo fstrim -a` command which will trim all unused blocks on all mounted
filesystems. It is safe to run the command on a running Linux machine since the command
is designed to run on live filesystems.

On Ubuntu the command is scheduled to be run every week: read
[Is TRIM enabled on my Ubuntu 18.04 installation?](https://askubuntu.com/questions/1034169/is-trim-enabled-on-my-ubuntu-18-04-installation)
for more info. Run

```bash
$ journalctl -u fstrim.service
```

to check that the trim was run on your machine.
