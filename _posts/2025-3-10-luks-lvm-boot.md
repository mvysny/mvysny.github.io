---
layout: post
title: LUKS, LVM and Linux Boot
---

LUKS encrypts your hard drive, while LVM allows to have partitions on your hard drive which are easier to
manage and resize than with MBR/GPT. We won't discuss MBR/GPT since LVM is better.
From the point of view of Linux, hard disk is a block device; MBR/GPT/LVM allows you to
have multiple block devices stored on one block device, while LUKS creates a block device
which encrypts/decrypts data and stores it on an underlying block device.

It's common to have:

- A hard disk partitioned via GPT. Note that every partition is a block device.
- A LUKS, encrypting contents of one block device
- LVM which allows you to have multiple block device on your LUKS-encrypted block device. See the
  [Basic Guide to Encrypting Linux Partitions With LUKS](https://linuxconfig.org/basic-guide-to-encrypting-linux-partitions-with-luks) for more details.

Overview of partitioning schemes:

- MBR (Master Boot Record) - an old way to "partition" your hard-drive: divide a block device into multiple block devices.
  No longer used. Use `fdisk` or `gparted` to resize and move partitions. Note that resizing/moving partitions involves
  physically copying data around.
- GPT (GUID Partition Table) - an upgrade over MBR; this is what you most probably use. Use `fdisk` or `gparted` to resize and move partitions. Note that resizing/moving partitions involves
  physically copying data around. See [Difference between GPT and MBR](https://www.howtogeek.com/193669/whats-the-difference-between-gpt-and-mbr-when-partitioning-a-drive/) for more details.
- LVM - an upgrade over MPR+GPT, allows resizing/moving partitions without the need of physically copying data around;
  supports all sorts of RAIDs which we won't discuss here. See the [Complete Beginner's Guide to LVM in Linux](https://linuxhandbook.com/lvm-guide/) for more details.

Note that GPT is preferred on physical devices over LVM, simply because [booting from LVM disk is very tricky](https://www.system-rescue.org/lvm-guide-en/Booting-linux-from-LVM-volumes/).
Therefore, use GPT for disks you boot from, use LVM for everything else.

## Analysing the current setup

Use the following commands to analyze your current setup:

- `sudo dmsetup ls --tree -o blkdevname` prints a tree of how block devices are nested
- `sudo lsblk -o name,size,fstype` same as above but better: also prints sizes and filesystems:

```
NAME                  SIZE FSTYPE
loop0                   4K 
loop1                44.4M 
...
sda                   1.7T 
├─sda1                  1M 
├─sda2                  1G ext4
└─sda3                1.7T crypto_LUKS
  └─dm_crypt-0        1.7T LVM2_member
    ├─vg0-lv0--swap     4G swap
    └─vg0-lv1--root   1.7T ext4
```
You can find the devices here:

- `/dev/sda`, `/dev/sda1`, `/dev/sda2`, `/dev/sda3`
- `/dev/mapper/dm_crypt-0` which usually symlinks to `/dev/dm-0`
- `/dev/vg0/lv0-swap` which symlinks to `/dev/dm-1`

### Analysing LUKS

```
> sudo cryptsetup status /dev/mapper/dm_crypt-0
/dev/mapper/dm_crypt-0 is active and is in use.
  type:    LUKS2
  cipher:  aes-xts-plain64
  keysize: 512 bits
  key location: keyring
  device:  /dev/sda3
  sector size:  512
  offset:  32768 sectors
  size:    3748612096 sectors
  mode:    read/write
  flags:   discards 
```

### Analysing LVM

We won't be using RAID capabilities of LVM, so in this case, physical volume is "the same thing"
as volume group. in other words, we'll have one volume group on a physical volume, which is stored on
one block device. Use:

- `pvscan`, `pvs` and `pvdisplay` to learn about physical volumes
- `vgscan`, `vgs` and `vgdisplay` to learn about volume groups
- `lvscan`, `lvs` and `lvdisplay` to learn about logical volumes

### discard

Make sure [discard](../ssd-discard/) is enabled for both LUKS and LVM when running on a SSD.

## Creating

I'll experiment on a Linux running in a VM, but you can experiment on an actual machine as well -
just plug in USB stick or a new hard drive, or create a partition on your existing hard drive.

First, let's create the GPT partition on your new disk, say it's `/dev/vdb`.
Just follow the [Partition+Format Storage Tutorial](https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux),
or use `parted`/`gparted`. First, make sure with `parted` and `lsblk` that the device is indeed `/dev/vdb`.
Then:
```bash
$ sudo parted /dev/vdb mklabel gpt
$ sudo parted -a opt /dev/vdb mkpart primary 0% 100%
$ sudo parted -l
```
The partition should now be ready, and a new block device should be available: `/dev/vdb1`.

> Note: Actually you don't have to partition the disk and you can create LUKS directly
> on `/dev/vdb`. You can skip the steps above if you'd like, then use `/dev/vdb` instead
> of `/dev/vdb1` in steps below.

### LUKS

Now we'll use LUKS to create an encrypted block device on top of `/dev/vdb1`. We can input the password via keyboard,
but then the password will need to be inputted every time the system boots. If you already have an encrypted partition,
you can store password into a key file, unlocking the second encrypted block device automatically.

To generate the key file:
```bash
$ sudo openssl genrsa -out /root/vdb1_keyfile 4096
$ sudo chmod -v 0400 /root/vdb1_keyfile 4096
```

To encrypt the device:
```bash
$ sudo cryptsetup luksFormat /dev/vdb1 /root/vdb1_keyfile
$ sudo cryptsetup open /dev/vdb1 dmcrypt0 --key-file /root/vdb1_keyfile
$ sudo cryptsetup status /dev/mapper/dmcrypt0
```
We have a block device that encrypts its contents automatically. However,
the device won't be opened automatically upon boot, you need the `/etc/crypttab` file;
see below.

### LVM

We can now configure LVM on top of LUKS. In theory we could also use GPT, but
it's far more common to use LVM:

```bash
$ sudo pvcreate /dev/mapper/dmcrypt0
$ sudo pvdisplay
$ sudo vgcreate vg0 /dev/mapper/dmcrypt0
$ sudo vgdisplay
```
We'll create two logical volumes: one for swap, other for a btrfs filesystem.
```bash
$ sudo lvcreate -L 1GB -n vg0-lv0-swap vg0
$ sudo lvcreate -l 100%FREE -n vg0-lv1-btrfs vg0
$ sudo lvdisplay
```
To create the final filesystems, run:
```bash
$ sudo mkswap /dev/vg0/vg0-lv0-swap
$ sudo swapon /dev/vg0/vg0-lv0-swap
$ free -h
$ sudo mkfs.btrfs /dev/vg0/vg0-lv1-btrfs
$ sudo mkdir -p /mnt/mydisk
$ sudo mount /dev/vg0/vg0-lv1-btrfs /mnt/mydisk
$ sudo lsblk -o name,size,fstype
```
Done - now we have an encrypted swap and an encrypted disk mounted at `/mnt/mydisk`.
However, those things won't activate automatically upon reboot - for that we need
to enable auto-mounting.

## Auto-mounting

In order for the LUKS block device to open automatically during the boot, you need to mention
it in the `/etc/crypttab` file:
```
dmcrypt0 /dev/vdb1 /root/vdb1_keyfile luks,discard
```
If not using the key file, replace `/root/vdb1_keyfile` with `none`.

Rebuild initramfs to take new `crypttab` into effect:
```bash
$ sudo update-initramfs -u
```

Reboot - Ubuntu will now ask for password to unlock the encrypted device upon boot.
See [crypttab man pages](https://www.man7.org/linux/man-pages/man5/crypttab.5.html) for more details.

In order to auto-activate swap and the encrypted btrfs filesystem, we need to add those to
`/etc/fstab`:

```fstab
/dev/vg0/vg0-lv0-swap none swap sw 0 0
/dev/vg0/vg0-lv1-btrfs /mnt/mydisk btrfs defaults 0 1
```
Done. Now, if you reboot, Linux will ask for the LUKS password on boot, then it will
auto-activate swap and auto-mount the btrfs filesystem. Reboot, enter the password
and verify that all works:
```bash
$ sudo lsblk -o name,size,fstype
vdb                          10G 
  vdb1                       10G crypto_LUKS
    dmcrypt0                 10G LVM2_member
      vg0-vg0--lv0--swap      1G swap
      vg0-vg0--lv1--btrfs     9G btrfs
```

