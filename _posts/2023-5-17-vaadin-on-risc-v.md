---
layout: post
title: Vaadin App Running on a RISC-V machine
---

RISC-V architecture is on the rise, along with the ARM architecture. RISC-V is
OSS and royalty-free as opposed to ARM and x86. There
are compelling machines being introduced as we speak. Recently, Ubuntu
created a new [Ubuntu Download page for RISC-V](https://ubuntu.com/download/risc-v)
where you can download images for your RISC-V machine. We're going to install Ubuntu and Java on
three RISC-V machines, and we'll run a [very simple Vaadin example app](https://github.com/mvysny/vaadin-boot-example-gradle) on those.

The machines are:

1. Virtual RISC-V machine running in QEMU
2. [Sipeed Lichee RV Dock](https://wiki.sipeed.com/hardware/en/lichee/RV/Dock.html) - a low-cost low-performance
   machine, yet still capable of running Vaadin
3. [StarFive VisionFive 2](https://www.starfivetech.com/en/site/boards) - a more powerful machine, performance-wise
   somewhere between RaspberryPI 3 and 4.

## QEMU

Follow the [Ubuntu QEMU Tutorial](https://wiki.ubuntu.com/RISC-V/QEMU). Download the preinstalled Ubuntu 23.04
image, unpack it with `xz` and run it with this huge command from your Ubuntu host machine:

```bash
qemu-system-riscv64 \
-machine virt -nographic -m 2048 -smp 4 \
-bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.bin \
-kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
-device virtio-net-device,netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::10022-:22,hostfwd=tcp::8080-:8080 \
-drive file=ubuntu-23.04-preinstalled-server-riscv64+unmatched.img,format=raw,if=virtio
```

First boot will take some time, just wait patiently until you finally see the `Cloud-init finished` line.

QEMU will use the [User Networking (SLIRP)](https://wiki.qemu.org/Documentation/Networking#User_Networking_(SLIRP)) -
ping doesn't work from guest but the machine has access to the internet. You can run `byobu`
(it comes preinstalled) then `sudo apt update` and `sudo apt -V dist-upgrade` to upgrade the system.

The openssh server comes preinstalled too, and it has been port-forwarded via the `hostfwd` clause
to the host port of 10022. To ssh to the machine, run `ssh ubuntu@localhost -p10022`.
Run `uname -a` to see that the architecture is indeed riscv.

To build the Vaadin app, run this on your host machine (you can also compile the project in guest machine but it will take ages):

```bash
git clone https://github.com/mvysny/vaadin-boot-example-gradle
cd vaadin-boot-example-gradle
./gradlew -Pvaadin.productionMode
cd build/distributions
scp -P 10022 vaadin-boot-example-gradle.tar ubuntu@localhost:/home/ubuntu/
```

Back to the guest machine: install Java via `sudo apt install openjdk-20-jre-headless`.
Then, unpack the Vaadin app via `tar xvf vaadin-boot-example-gradle.tar`.
Finally, run the Vaadin app via `cd vaadin-boot-example-gradle/bin` and `./vaadin-boot-example-gradle`.

After the app starts, open the browser and navigate to [http://localhost:8080](http://localhost:8080).
On my rather fast AMD Ryzen 7 PRO 4750U x86-64 machine the qemu emulation of RISC-V is a bit slow and it takes some time for the
mechine to boot up (95 seconds) and the app to boot up (26 seconds), then additional 70 seconds to render the first page
(mostly because of computing various sizes of the PWA icon set).
However, after the app is fully initialized it is very responsive and fast to respond.

## StarFive VisionFive 2

Installing this device was a major PITA, but I managed to do it without the UART-TTL device.
See my [starfive-visionfive2 installation guide](../starfive-visionfive2/) for more details.

Installing openjdk-20-jre-headless doesn't work because of [Bug #1023748](https://groups.google.com/g/linux.debian.bugs.dist/c/-vfxBsw5fkg?pli=1),
simply install `openjdk-17-jre-headless`.

Rebuild vaadin-boot-example-gradle with the `@PWA` annotation removed, otherwise it will take ages to resize
the PWA icons (they're resized after Vaadin app boots up and prints "running in production mode").
The app boots up in 26 seconds then serves the pages pretty swiftly. It occupies 80mb of RAM which is great.

## Sipeed Lichee RV Dock

[Sipeed Lichee RV Dock homepage](https://wiki.sipeed.com/hardware/en/lichee/RV/Dock.html). Note that the
device lacks ethernet port and only introduces one USB A host, but that's enough. USB-C
used to power the device; the device is pretty low-power, thus a cellphone charger is enough to power the device.

Ubuntu installation instructions look easy: [Ubuntu RISC-V Lichee](https://wiki.ubuntu.com/RISC-V/LicheeRV).
The Ubuntu 23.04 preinstalled image doesn't work: Lichee's Power LED slowly blinks and nothing boots up.
The Ubuntu 22.04 preinstalled image works though, just be patient: even after the system shows
`ubuntu login` on HDMI screen, the `ubuntu`/`ubuntu` user/password doesn't work initially: it
says "login incorrect" until the CloudInit finishes, which may take up to 5 minutes. Be patient and you'll be able
to log in eventually.

The device is much much slower than StarFive VisionFive 2. It's a single-core-only machine.
In fact the device is so slow, the wifi driver + wifi encryption is too demanding for the poor chip,
effectively limiting the wifi network speed to roughly 100kb/s, and eth network speed to roughly 1000kb/s.

The Vaadin app boots up in 2 minutes. First page is served quite slowly, but afterwards the app
works quite well. However, there is slight but noticeable delay in requests (the requests usually take 200-300ms to complete).
Definitely usable, but the device slowness shows a bit.
