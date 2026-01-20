---
layout: post
title: New Machine - Ubuntu in Parallels/UTM Apple Silicon/virt-manager
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes. I won't setup any encryption since I expect MacBook disk itself to be already encrypted.

## Post-installation

# Software & Updates

Go to the "Updates" tab and set:
* When there are other updates: Display Immediately
* Notify me of new Ubuntu version: For LTS only

LTS: the reason is that Parallels only supports Ubuntu 22.04; it shows scary segfaults on Ubuntu 23.10+.
Before upgrading to Ubuntu 24.04, I need to test that it's rock-solid; also this may require Parallels 20+.

