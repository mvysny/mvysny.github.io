---
layout: post
title: Android ADB Debugging on Ubuntu 22.10 and OnePlus 8
---

These steps are so annoying and error-prone, I am creating a documentation for myself, should I
have to deal with this piece of shit ever again.

## Enable Developer Mode

Go to *Settings / About Device / Version* and tap *Build number* 10 times.

Go to *Settings / System Settings / Developer options* and make sure *USB debugging* is turned on.

## Plugging your phone in

Plug in your phone. MAKE SURE TO SELECT *USB FILE TRANSFER / ANDROID AUTO* and not just "USB charging",
otherwise the developer tools won't connect.

A popup should appear, select "always accept".

Run this from your terminal:

```bash
$ adb devices
List of devices attached
47d81c93  device
```

## Running your app from Android Studio

Now the "OnePlus IN2023" device should appear in the list of *Running Devices* in your Android Studio.
You should be able to run your app now.

## Workarounds

Previously there was a need to specify proper udev permissions in order for adb to access your device.
That should no longer be necessary. Still, if adb is saying `no permissions`, make sure that:

* Your user is in the `plugdev` group, by running `groups` in terminal
* Locate your phone via `lsusb`, then create an udev rule:

```bash
$ sudo vi /etc/udev/rules.d/51-android.rules
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", ATTR{idProduct}=="2e81", MODE="0666", GROUP="plugdev"

$ sudo udevadm control --reload-rules
```

Also see [adb devices => no permissions](https://stackoverflow.com/questions/53887322/adb-devices-no-permissions-user-in-plugdev-group-are-your-udev-rules-wrong)
