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
