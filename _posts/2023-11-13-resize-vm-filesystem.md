---
layout: post
title: Resize Root Filesystem in a VM
---

It's possible to increase the root filesystem size of the Linux VM machine, quite easily.

First, shut down the VM and increase the size of the qcow2 file:

```
$ qemu-img resize disk.qcow2 60G
```

After that's done, you can start up the VM again. Now we need to increase both the
partition size, and the filesystem size. To increase the partition size, run this command
*from within the VM*:

```bash
$ sudo growpart /dev/vda 2
```

You can now grow the ext4 filesystem of the root FS while the OS is running:
```bash
$ sudo resize2fs /dev/vda2
```

btrfs can be resized via
```bash
$ sudo btrfs filesystem resize max /
```
