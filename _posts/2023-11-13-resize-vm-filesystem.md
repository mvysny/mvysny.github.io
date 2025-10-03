---
layout: post
title: Resize Root Filesystem/Disk in a VM
---

It's possible to increase the root filesystem size of the Linux VM machine, quite easily.

First, shut down the VM and increase the size of the qcow2 file:

```
$ qemu-img resize disk.qcow2 60G
```

After that's done, you can start up the VM again. Now we need to increase both the
partition size, and the filesystem size. To increase the partition size, run this command
*from within the VM* (Ubuntu only):

```bash
$ sudo growpart /dev/vda 2
```

If there is no `growpart`, you can do the same thing with fdisk. Fdisk doesn't support
resize, but you can remove the partition and create a new one, starting at the same sector
as the old one, but with a larger size:
```bash
$ sudo fdisk /dev/vda
p
d 2
n
p
w
```
Keep the partition type to "Linux Filesystem" when asked. Make sure the UUID of `/dev/vda2` wasn't changed,
by checking `/etc/fstab` and `ls -la /dev/disk/by-uuid`.

You can now grow the ext4 filesystem of the root FS while the OS is running:
```bash
$ sudo resize2fs /dev/vda2
$ duf -only local
```

btrfs can be resized via
```bash
$ sudo btrfs filesystem resize max /
$ duf -only local
```
