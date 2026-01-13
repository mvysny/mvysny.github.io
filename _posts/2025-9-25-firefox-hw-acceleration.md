---
layout: post
title: Enabling Hardware Acceleration in Firefox
---

As of 2025, Firefox finally supports hardware acceleration,
both for layouting, webgl, and for hardware video decoding.
On AMD Radeon and Intel GPUs, things just work out-of-the-box.
On Nvidia proprietary driver, nothing works as usual;
[nouveu stopped working for me](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2125584) so I can't test that.

# Wayland

Go to the `about:support` page: the "Window Protocol"
setting should read "wayland" instead of "xwayland". If it says "xwayland",
add `MOZ_ENABLE_WAYLAND=1` to `/etc/environment` to force Firefox to run on `wayland`
instead of `xwayland`, then reboot.

# Layouting

Go to `about:support` and search for `Compositing`.
If 3d acceleration is enabled, it should say "WebRender" and you're all good.
If it's using slower software-based layouting it will say "WebRender (Software)".

You can check `HW_COMPOSITING` and/or `OPENGL_COMPOSITING`; it will
probably say "Acceleration blocked by platform" on Nvidia proprietary drivers.
Good thing is that you can go to `about:config` and force hardware compositing:

* Set `layers.acceleration.force-enabled` to true

But it seem to have no effect on Nvidia.

# webgl

Search for WEBRENDER: if it says "available" then it's enabled.
You can test it out at [WebGL Aquarium](https://webglsamples.org/aquarium/aquarium.html):

* If webgl is working, you'll get 60+ FPS with 10000 fish, with no CPU usage
* If webgl is not working, you'll get software rendering and ~13 FPS with 10000 fish

You can try to go to `about:config` and set `gfx.webrender.all` to true and test again;
on Nvidia Proprietary drivers this might do nothing.

Search for `GPU #1`: if it says "Description: llvmpipe" then it's using software 3d renderer.

## Nvidia Proprietary

When running Firefox from command-line, I noticed `libEGL warning: egl: failed to create dri2 screen`.
I ran `eglinfo` and all looked good, so I have no idea what's wrong. Also running
`eglgears_wayland` worked well. Running `eglinfo -B` shown something interesting:

```
Device #1:

Platform Device platform:
libEGL warning: pci id for fd 26: 10de:28e0, driver (null)

pci id for fd 30: 10de:28e0, driver (null)
pci id for fd 31: 10de:28e0, driver (null)
libEGL warning: egl: failed to create dri2 screen
libEGL warning: pci id for fd 26: 10de:28e0, driver (null)

pci id for fd 30: 10de:28e0, driver (null)
pci id for fd 31: 10de:28e0, driver (null)
libEGL warning: egl: failed to create dri2 screen
libEGL warning: pci id for fd 26: 10de:28e0, driver (null)

eglinfo: eglInitialize failed
```
Asking Grok, he told me that: Nvidia proprietary drivers do not support or expose the DRI2 interface because:

* DRI2 is part of the open-source ecosystem and relies on kernel modules like drm (Direct Rendering Manager) in a way that's tightly coupled to Mesa.
* NVIDIA's drivers use their own proprietary kernel module (nvidia.ko) and user-space components, bypassing DRI entirely. They handle rendering directly via NVIDIA's GLX/EGL extensions.

It also mentions that "DRI2 is an X11 extension", which is puzzling since I'm running Wayland/GNOME and
Firefox is running in Wayland mode too. I guess that Firefox just goes through all offered devices and falls back
to Device #2 which is llvmpipe software rendering.

# Hardware Video Decoding

Go to `about:support` and search for "Codec Support Information".
If it says "Hardware Decoding": unsupported, read on.

Firefox uses VA-API do decode video. To check whether VA-API works,
run `vainfo` in terminal (you'll need `sudo apt install vainfo`).
If this shows error, you'll need to install:

* `sudo apt install mesa-va-drivers` for AMD Radeon (works on Ubuntu 25.10+ only)
* `sudo apt install nvidia-vaapi-driver` for Nvidia proprietary driver

Restart Firefox and re-check. On Radeon this might be enough; on Nvidia Proprietary
the decoding might be blacklisted. Try going to `about:config` and set
`media.ffmpeg.vaapi.enabled` to true and restart Firefox. On Nvidia Proprietary this
still didn't help, so I gave up.

If hardware video acceleration is blocked with error code
`FEATURE_HARDWARE_VIDEO_DECODING_DISABLE` or `FEATURE_FAILURE_VIDEO_DECODING_TEST_FAILED` in `about:support`,
you can override it with `media.hardware-video-decoding.force-enabled=true` and `media.hardware-video-encoding.force-enabled=true`.

# Conclusion

I failed to enable any sensible acceleration for Firefox+Nvidia: Don't use Nvidia with Linux.

Also see [Enable Hardware Video Acceleration (VA-API) For Firefox in Ubuntu 20.04 / 18.04 & Higher](https://ubuntuhandbook.org/index.php/2021/08/enable-hardware-video-acceleration-va-api-for-firefox-in-ubuntu-20-04-18-04-higher/).

