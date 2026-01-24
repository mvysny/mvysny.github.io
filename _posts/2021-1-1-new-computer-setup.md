---
layout: post
title: New Computer/New Machine Setup with Ubuntu
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes.

## Rhythmbox

* Preferences > Plugins > Disable "Alternative Toolbar", "DAAP Music Sharing", "Last FM", "Portable Players"
* `cd Music && ln -s "../Resilio Sync/muf-music/music" ./`

Install additional Gstreamer plugins:

* `gstreamer1.0-libav` to add support for m4a and mpc
* `gstreamer1.0-plugins-bad` to add support for mod

## Software & Updates

Go to the "Updates" tab and set:
* When there are other updates: Display Immediately
* Notify me of new Ubuntu version: For any new version

Also [Updating Ubuntu Quickly](../updating-ubuntu-quickly/).

## Increase security

[Secure Boot 2](../ubuntu-secure-boot2/)

