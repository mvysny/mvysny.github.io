---
layout: post
title: Raspberry 5 + Ubuntu 24.10 - a disaster
---

Ubuntu 24.10 arm64 is easy to flash and install using the RPI Imager app.
The OS is incredibly snappy, but afterwards huge problems start to appear:

- Neither Firefox nor Chromium works - they just display a white window (Firefox)
  or some garbled graphics (Chromium). Only `./chromium --disable-gpu` works.
  Apparently the RPI5 3d drivers aren't working correctly in Ubuntu.
  - Chromium prints `vkCreateInstance failed with VK_ERROR_INCOMPATIBLE_DRIVER` which
    definitely suggests broken GPU drivers. Couldn't find an Ubuntu bug report for this though.
- There are others complaining: [here](https://askubuntu.com/questions/1533833/how-can-ubuntu-24-04-and-24-10-be-certified-with-raspberry-pi5-and-not-work-at-a)
  and [here - read the comments](https://www.omgubuntu.co.uk/2024/05/ubuntu-24-04-raspberry-pi-5).
- `gnome-terminal` suddenly stopped working and wouldn't launch. Workaround is to install `gnome-console` and uninstall
  gnome-terminal.
- (Unrelated to Ubuntu): The Micro-HDMI ports are a disastrous choice - they look extremely fragile,
  they can't support the weight of the hdmi cable and a micro-hdmi-to-hdmi adapter. I'm
  expecting those ports to eventually snap off from RPI.

Raspberry PI OS seems to be working much better - both Firefox and Chromium
work, the [webgl aquarium](http://webglsamples.org/aquarium/aquarium.html)
shows 60 FPS for 1000 fish. However, YouTube on Firefox is really slow; the `about:support`
shows a lot of 'blacklisted' and no media support, suggesting that the 3d drivers
need some work. However, Chromium plays YouTube videos without any issues and doesn't max out
CPU, suggesting that there's some kind of GPU decoding.

Is RPI5 good for some kind of NAS+MediaStation? I don't think so - Ubuntu has too many issues
to be usable; RPI OS generally work but video issues in Firefox suggest that the
GPU drivers need more work.

As of 2025, a small x86 machine is probably a better bet for NAS+MediaStation.

## Performance

RPI5 uses the [BCM2712](https://www.raspberrypi.com/documentation/computers/processors.html#bcm2712)
chipset and the `Quad-core Arm Cortex-A76 @ 2.4GHz` CPU.

According to the [cpubenchmark.net](https://www.cpubenchmark.net),
[ARM Cortex-A76 4 core 2400 MHz](https://www.cpubenchmark.net/cpu_lookup.php?cpu=ARM+Cortex-A76+4+Core+2400+MHz&id=5743)
has the score of 2151. For comparison, [Intel Celeron J3455 @ 1,5 GHz](https://www.cpubenchmark.net/cpu_lookup.php?cpu=Intel+Celeron+J3455+%40+1.50GHz&id=2875)
(present in Intel NUC) has the score of 2253 and should be therefore faster.

According to my highly unscientific Java compilation test, running `./gradlew` on [karibu-testing](https://www.github.com/mvysny/karibu-testing)
on openjdk-17 took 219 seconds on RPI5 (with active cooling fan), while it took 310 seconds on the J3455 (passively cooled, no fan),
which makes RPI5 30% faster (!).

