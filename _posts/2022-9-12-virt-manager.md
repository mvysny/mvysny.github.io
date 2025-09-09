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
* The UI performance is brilliant after I enabled the 3d acceleration. It's rock-solid Intel
  GPUs so far, not so great on AMD cards.

## Performance

The CPU performance is fine. My highly unscientific test of compiling [karibu-testing](https://github.com/mvysny/karibu-testing/)
on openjdk-11 on Ubuntu 22.04 x86-64 machine with "AMD Ryzen 7 PRO 4750U" CPU:

* Host machine with 8 cores+hyperthreading: 2m 1s
* Docker image: 2m 12s
* Ubuntu 22.04 Guest in virt-manager: 2m 31s

Not bad - very usable. The UI performance is perfect with 3D acceleration enabled, but only on
Intel GPUs: AMD GPUs offer choppy performance even with 3d acceleration enabled and are
unusable for any professional work. However, increasing the GPU-allocated memory to 2GB in BIOS
seem to help a bit.

## Video

I always enable "Auto-resize VM with window" which makes sure the VM fills all the available
screen space of the virt-manager window.

Video drivers:

* Virtio and QXL are the best supported. Virtio supports 3d acceleration which should offer the best performance.
  Make sure the 3D acceleration support is enabled;
  then head to Display, select Spice and enable OpenGL.
* QXL doesn't offer 3d acceleration, but performs faster with software renderer than virtio.
   But the "Auto-resize VM with window" needs a workaround: change the guest display resolution to something high, like 1920x1200 -
  the image won't be chopped off but rather will correctly match the host window size.
* Bochs, VGA and ramfb are horribly slow, don't bother.

### Ubuntu 23.10 Host

Intel: `virtio` with 3d acceleration works smooth.

AMD GPUs: `virtio` with 3d acceleration works best, but is far from smooth. Use Intel.

### Ubuntu 22.10 Host

With AMD graphics: use the `QXL` video driver. Virtio with 3D acceleration is utter crap - slow & choppy
Virtio without 3D acceleration is okay, but moving a window around the screen clearly shows that the performance is lacking.
QXL is the smoothest, but needs the auto-resize workaround.

With Intel graphics: `virtio` with 3d acceleration works smooth.

### Ubuntu 22.04 Host

Use the `virtio` video driver, and make sure the 3D acceleration support is enabled.

Firefox+Wayland+Screen sharing: on all video drivers, if you try to share a screen where your VM is running, the screen will
soon stop updating in Firefox. Workaround is to share just the virt-manager window with the VM and not the entire screen.

## Shared folders

See [Share Folder Between Guest and Host in virt-manager (KVM/Qemu/libvirt)](https://www.debugpoint.com/share-folder-virt-manager/).

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

## Bridging

If you want to expose the Virtual Machine fully on your LAN, so that it's accessible from other
LAN machines and mDNS lookup works, read on. Based on excellent [KVM Bridged](https://www.dedoimedo.com/computers/kvm-bridged.html).

First, create a bridge interface, add your network card to it and make DHCP assign an address to it:

```bash
$ sudo brctl addbr br0
$ sudo brctl addif br0 eth0   # use ifconfig to find your eth address; doesn't work with wifi interfaces
$ sudo dhclient br0
```
`br0` must have its own IP address otherwise it won't work. dhclient should assign one to it.

Now, open virt manager and edit the NIC properties of your VM. Set the "Network Source:" to "Bridge devices..."
and enter `br0` into "Device name:". Start the VM - it is now exposed on your LAN network.

## Windows Guest

If you must:

* Create a VM with QXL graphics
* [Download Windows 11 ISO](https://www.microsoft.com/en-us/software-download/windows11)
* [Install Windows without Microsoft Account](https://www.tomshardware.com/how-to/install-windows-11-without-microsoft-account)
* Install guest tools
  * Download the [latest virtio-win-*.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/?C=M;O=D)
  * Mount it to the VM
  * Install `virtio-win-gt-x64` and `virtio-win-guest-tools`
* Shutdown the VM and change the driver to `virtio` with 3d acceleration
