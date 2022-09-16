---
layout: post
title: Virt Manager
---

After [VirtualBox 6.1.34 stopped working with kernel 5.15.0.47](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1012627),
I decided it was time to ditch the VirtualBox kernel-tainting VM modules and move to
virt-manager (gnome-boxes offered almost zero configuration options and its UI performance was horrible).
Pretty happy so far with my Linux-in-Linux setup:

* clipboard works out-of-the-box on the Spice/Virtio video driver since `spice-vdagent`
  (client required for the Spice protocol to work flawlessly) comes preinstalled with Ubuntu 22.04
* The UI performance is brilliant after I enabled the 3d acceleration. It's rock-solid on both AMD and Intel
  GPUs so far.

## Performance

The CPU performance is fine. My highly unscientific test of compiling [karibu-testing](https://github.com/mvysny/karibu-testing/)
on openjdk-11 on Ubuntu 22.04 x86-64 machine:

* Host machine with 8 cores+hyperthreading: 2m 1s
* Docker image: 2m 12s
* Ubuntu 22.04 Guest in virt-manager: 2m 31s

Not bad - very usable. The UI performance is perfect with 3D acceleration enabled.

## UI issues

I always enable "Auto-resize VM with window" which makes sure the VM fills all the available
screen space of the virt-manager window.

Use the `virtio` video driver, and make sure the 3D acceleration support is enabled.
Then head to Display, select Spice and enable OpenGL. This is the best and fastest setting for smoothest UI.

* Virtio without 3D still offers quite decent performance. If you don't want to enable 3D acceleration, I still recommend to use this driver.
* QXL doesn't support 3D acceleration. The speed is fine, but the "Auto-resize VM with window" is very buggy with this driver
  and stubbornly refuses to resize the screen of your VM.
* Bochs driver is horribly slow.
* Haven't tried others.

Firefox+Wayland+Screen sharing: on all video drivers, if you try to share a screen where your VM is running, the screen will
soon stop updating in Firefox. Workaround is to share just the virt-manager window with the VM and not the entire screen.

## Quick VM cloning

I miss the ability to clone the VM without having to clone the disk. VirtualBox
simply created additional filesystem layers, allowing for quick prototyping (and
then continuing with the new VM or dropping it away).

The virt-manager's features in this regard is either an absolute disaster (in case of internal snapshots)
or non-existing (no support for backing images). I have no idea how to use
the internal snapshot functionality on stopped machines: the "Run Selected Snapshot"
button does nothing; running the full VM randomly runs either the main image (and thus changes persist) or some random
snapshot (and thus changes are gone after shutoff). I haven't figured out a way to tell
what the virt-manager UI is going to do. But I digress.

### diff-cloning images manually

The solution is to use the cli tool [qemu-img](https://linux.die.net/man/1/qemu-img)
(see [qemu-img documentation](https://qemu.readthedocs.io/en/latest/tools/qemu-img.html) for a better doc).
First, stop the VM. Then, go to where your `*.qcow2` image is located, and run the following command:

```bash
$ qemu-img create -f qcow2 -F qcow2 -b image.qcow2 image-1.qcow2
```

Now duplicate your VM. Since virt-manager doesn't allow you to
specify another disk to run the VM on, we'll need a bit of a hack.
Select to run the VM on the original disk; then head to the new VM settings, select "VirtIO Disk 1", then the "XML" tab and
change the image file name to `image-1.qcow2` manually (you may need to enable XML editing in virt-manager settings).

If you want to run the original VM as well, you'll need to create a new image for it - the original
`image.qcow2` MUST NOT BE MODIFIED otherwise all child images will most probably get corrupted.

```bash
$ qemu-img create -f qcow2 -F qcow2 -b image.qcow2 image-2.qcow2
```

Notice the `-1` and `-2` suffixes - this way we're creating a "tree" of images; this way we can clearly
tell who's the parent of whom. When creating a child image out of `image-1.qcow2`, you can
name it `image-1-1.qcow2` etc.

If you decide to stop experimenting and delete the new VM, simply delete the VM including the `image-1.qcow2` file.

On the other hand if you decide to keep the changes, just leave the images as-is, and
maybe delete the old VM without deleting the image file. Later on, if the base image has no other children,
you can merge changes done to `image-1.qcow2` to `image.qcow` and get rid of `image-1.qcow2`:

```bash
$ qemu-img commit -f qcow2 -d image-1.qcow2.
```

This will merge all data from `image-1` to `image` and will delete `image-1`. You'll
need to modify your VM to refer to the `image.qcow2`.
