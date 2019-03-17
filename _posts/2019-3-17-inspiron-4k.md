---
layout: post
title: Dell Inspiron 13-5379, Ubuntu and 4K monitor
---

The problem with this machine is that it only outputs 1920p to a 4K monitor with Ubuntu,
which is pretty annoying. According to the [Dell Inspiron 13-5379 spec](https://www.dell.com/ae/p/inspiron-13-5379-2-in-1-laptop/pd)
the connector is HDMI 1.4a, which [should support 4K](https://denon.custhelp.com/app/answers/detail/a_id/192/~/differences-between-hdmi-versions-1.1%2C-1.2%2C-1.3a%2C-1.4-and-2.0%3F).
However, only HDMI 2.0 supports 4K with 60FPS, HDMI 1.4a only supports 4K with 25 or 30 FPS.
My Inspiron employs Intel i7-8550U which [should support 4K at 60FPS](https://ark.intel.com/content/www/us/en/ark/products/122589/intel-core-i7-8550u-processor-8m-cache-up-to-4-00-ghz.html).

In order to add support for 4k resolution, a new modeline needs to be added. I've found
this awesome [modeline generator](https://arachnoid.com/modelines/). The modeline
generated for 30 FPS didn't work, but the 25 FPS worked. In order to add the
modeline and switch to it, run the following in the terminal:

```bash
xrandr --newmode "3840x2160_25.00" 278.70 3840 4056 4464 5088 2160 2161 2164 2191 -HSync +Vsync
xrandr --addmode HDMI-1 "3840x2160_25.00"
xrandr --output HDMI-1 --mode "3840x2160_25.00"
```

Note that the above only works when Ubuntu is running on Xorg. Trying the above while running on Wayland, on the `XWAYLAND1` output fails in the last step:

```bash
$ xrandr --output XWAYLAND1 --mode "3840x2160_25.00"
xrandr: Configure crtc 0 failed
```

The controls are rather tiny with the default scale of 100%. You can open the Gnome "Displays" configuration and selecting the 200% upscale, to restore the proper sizes.
The general problem with 4K resolutions is that Gnome loses its speed and the entire desktop starts behaving "choppy" which is quite annoying.

