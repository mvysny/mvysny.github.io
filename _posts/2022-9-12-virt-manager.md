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

# Performance

The CPU performance is fine. My highly unscientific test of compiling [karibu-testing](https://github.com/mvysny/karibu-testing/)
on openjdk-11 on Ubuntu 22.04 x86-64 machine with "AMD Ryzen 7 PRO 4750U" CPU:

* Host machine with 8 cores+hyperthreading: 2m 1s
* Docker image: 2m 12s
* Ubuntu 22.04 Guest in virt-manager: 2m 31s

Not bad - very usable. The UI performance is perfect with 3D acceleration enabled, but only on
Intel GPUs: AMD GPUs offer choppy performance even with 3d acceleration enabled and are
unusable for any professional work. However, increasing the GPU-allocated memory to 2GB in BIOS
seem to help a bit.

# Video

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

## Ubuntu 23.10 Host

Intel: `virtio` with 3d acceleration works smooth.

AMD GPUs: `virtio` with 3d acceleration works best, but is far from smooth. Use Intel.

## Ubuntu 22.10 Host

With AMD graphics: use the `QXL` video driver. Virtio with 3D acceleration is utter crap - slow & choppy
Virtio without 3D acceleration is okay, but moving a window around the screen clearly shows that the performance is lacking.
QXL is the smoothest, but needs the auto-resize workaround.

With Intel graphics: `virtio` with 3d acceleration works smooth.

## Ubuntu 22.04 Host

Use the `virtio` video driver, and make sure the 3D acceleration support is enabled.

Firefox+Wayland+Screen sharing: on all video drivers, if you try to share a screen where your VM is running, the screen will
soon stop updating in Firefox. Workaround is to share just the virt-manager window with the VM and not the entire screen.

# Shared folders

See [Share Folder Between Guest and Host in virt-manager (KVM/Qemu/libvirt)](https://www.debugpoint.com/share-folder-virt-manager/).
In short:

0. `sudo apt install virtiofsd`
1. Make sure "Memory / Enabled Shared Memory" is checked
2. Add Hardware, "Filesystem"
3. Source path points to guest OS path, target path is a mount point, e.g. "foobar"
4. `sudo mount -t virtiofs foobar /home/mavi/shared`
5. To make the mount permanent, edit `/etc/fstab` and add:

```fstab
foobar /home/mavi/shared virtiofs defaults 0 2
```

# Image pruning

qcow2 images tend to grow large, even with guest using ext4 with discard. The solution is to
prune the images from time to time. POWER OFF all VMs, then:

```bash
cd /var/lib/libvirt/images
mv image.qcow2 image.qcow2_backup
qemu-img convert -O qcow2 -p image.qcow2_backup image.qcow2
rm image.qcow2_backup
```

More info at [Proxmox: Shrinking Qcow2](https://pve.proxmox.com/wiki/Shrink_Qcow2_Disk_Files).

# Bridging

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

# Windows Guest

If you must:

* Create a VM with QXL graphics and TPM 2.0 - virt-manager will do this automatically once it detects Win11 system
* [Download Windows 11 ISO](https://www.microsoft.com/en-us/software-download/windows11)
* [Install Windows without Microsoft Account](https://www.tomshardware.com/how-to/install-windows-11-without-microsoft-account)
* Install guest tools: download and install [virtio-win-guest-tools.exe](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/?C=M;O=D)
* Shutdown the VM and change the driver to `virtio` with 3d acceleration

From time to time, Guest Tools will lower the client resolution. Just set the resolution manually in Windows:
right-click on desktop, Display settings, Display resolution.

WARNING: `virtio` (even with 3d acceleration) introduces significant mouse cursor delay lag (on AMD Radeon). Switching to QXL fixes that,
but makes the GPU performance worse. Yet, mouse lag with `virtio` on any resolution higher than 800x600 makes the VM impossible to work with,
so switching to QXL fixes the issue.

To enable higher resolutions with QXL, edit "Video QXL" as XML and make sure it looks like this:
```xml
<video>
  <model type="qxl" ram="131072" vram="131072" vgamem="65536" heads="1" primary="yes"/>
  <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
</video>
```

