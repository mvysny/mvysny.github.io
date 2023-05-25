---
layout: post
title: Starfive VisionFive2 Installation Guide
---

Getting this device up and running is almost impossible for the uninitiated, but finally
I managed to get this bloody device up-and-running WITHOUT having to connect to UART-TTL.
The [Starfive VisionFive2 homepage](https://www.starfivetech.com/en/site/boards).

First, the [official visionfive2 manual](https://doc-en.rvspace.org/VisionFive2/PDF/VisionFive2_QSG.pdf)
is almost useless. It's not clear which distribution to download, which boot mode to choose,
doesn't contain links to download the updated SPL and U-Boot; in short
it's a complete disaster. Second, I failed to boot up [Ubuntu 23.04](https://wiki.ubuntu.com/RISC-V/StarFive%20VisionFive%202)
no matter how hard I tried. Even if it would boot up, USB wouldn't work anyway,
so it was going to be a bit useless anyway.

You'll need:

* StarFive VisionFive 2. My device is V1.3B, I have no idea whether the following will work on earlier devices.
* Ethernet cable, since VisionFive2 doesn't have a WIFI
* Ubuntu Linux to run the commands on
* A SD Card, 8GB is enough.

Let's start by [downloading the VisionFive2 Debian](https://debian.starfivetech.com/).
Go to Google Cloud, then enter the `Engineering Release` folder. I've installed the
`starfive-jh7110-VF2-SD-wayland.img.bz2` from the `202303` folder.
Unzip via `bunzip2 starfive-jh7110-VF2-SD-wayland.img.bz2`, then copy to your SD-Card
using `sudo dd if=starfive-jh7110-VF2-SD-wayland.img of=/dev/sda status=progress`.
WARNING: figure out first on which device your SD Card is located - on my system it's `/dev/sda` but your system will vary.

Ubuntu will unhelpfully mount `/dev/sda*`, run `sudo unmount /dev/sda*` to unmount them.

When the copy is done, you'll need to resize the filesystem since it has zero free space by default.
Run `gparted`, choose `/dev/sda` and resize the last partition to occupy the entire SD Card.
GParted will increase the partition size and also will resize the filesystem (it's ext4).
For some reason the filesystem may contain errors, run `sudo fsck -f /dev/sda4` to check and fix them.
Mount via `sudo mount /dev/sda4 /mnt` then check that the FS has free space:
`df -h /mnt` shows some free space. Unmount.

In order to boot successfully, you need to switch the VisionFive2 device to the SDIO boot mode.
Check out the PDF manual on how to flip the boot switches, this part is actually described pretty well.
Then, insert the SD Card, Ethernet cable and the power. You can also connect the device to the monitor -
if everything goes well you'll see the system booting up. Success!

The system starts in 1024x768 resolution in pink mode for some unknown reason, and blinks like crazy. The best way is to
figure out the IP address assigned to the device, then ssh to it via `ssh user@192.168.0.36`, password
`starfive`.

It's recommended to update the SPL and U-Boot otherwise the newest Debian 12 won't work.
Download the files named `visionfive2_fw_payload.img`
and `u-boot-spl.bin.normal.out` from [starfive's github](https://github.com/starfive-tech/VisionFive2/releases/).
You can also download & copy `sdcard.img` to your SD Card then boot off it - the image is
intended to assist you with the U-Boot upgrade. It's not clear whether you need to follow "4.3.1 Updating SPL and U-Boot of Flash",
or "4.3.2. Updating SPL and U-Boot of SD Card and eMMC" or both, I went with both
and the device still works. For `4.3.1` obviously choose the `flashcp` version.

The device feels very fast over ssh and runs all commands very quickly. The device shows a lot of promise.
Having Ubuntu Server with all drivers in the mainline kernel would definitely be awesome.

## Further Experiments

The `202303` folder contains Debian 11 with kernel 5.15.0; I'll also try out the `image-69` - I've [found
out that this is the newest distro to use](https://www.cnx-software.com/2023/02/12/starfive-visionfive-2-sbc-review-debian-12/),
but it only works with the newest U-Boot (which we upgraded above). I'll test it out and let you know.
The article however failed to boot up the device into UI, so probably it's pointless to try.

Anyway, I've downloaded `starfive-jh7110-VF2_515_v2.5.0-69.img.bz2` from the link above, from the `image69` folder,
then copied to SDCard via
```bash
bzcat starfive-jh7110-VF2_515_v2.5.0-69.img.bz2 |sudo dd of=/dev/sda status=progress conv=fsync
```
This image is huge though, you'll need 32GB+ SD Card. Unpacked size is 17GB and it took almost 2 hours to copy to a SD Card.
Then, after you switch the boot mode to QSPI, it draws the VisionFive2 logo and doesn't boot.
Fuck it, I'm tired, I'm going to sleep.
