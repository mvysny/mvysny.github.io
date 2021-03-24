---
layout: post
title: Enable Discard for your SSD
---

After Linux is installed on your SSD, don't forget to enable the Discard operation,
to let your SSD know which blocks are free to be reclaimed.

In order to check that the SSD properly supports the discard command, run

```bash
$ lsblk --discard
NAME   DISC-ALN DISC-GRAN DISC-MAX DISC-ZERO
sdc           0        4K       4G         0
├─sdc1        0        4K       4G         0
└─sdc2        0        4K       4G         0
```

If the DISC-GRAN and DISC-MAX are non-zero, discard is supported for that particular drive.

However, that's not enough. If you've installed your Linux into a LVM, you need to
configure LVM to pass-through the Discard operation: edit `/etc/lvm/lvm.conf`
and make sure the `devices{}` section contains `issue_discards = 1`.

Alternatively if you're using dm-crypt, edit `/etc/crypttab` and make sure the `discard` option is there.

Finally, you need to enable discard for all of your ext4 partitions: simply add the `discard` option to
`/etc/fstab`. Note that swap on a swap partition will perform discard automatically.

Please see the excellent [SSD Optimization](https://wiki.debian.org/SSDOptimization)
article for more details.
