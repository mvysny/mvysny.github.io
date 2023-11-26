---
layout: post
title: Ubuntu Linux VS MacBook
---

I've bought an old 2015 x86 MacBook Air, to get a taste of the Apple experience, and to see
whether it might be my daily driver. Currently, I'm quite happy with Ubuntu, but
I'm always hesitant to suspend the machine - it never worked properly in the past.
Also the Nvidia+Wayland support is just strange; IDEA also had a couple
of GNOME Shell-related issues in the past. I wanted to see whether things work
better on Apple machines.

## The good

I must admit that thing is really easy to use, from the perspective of a common user.
The iCloud is integrated seamlessly into apps provided by default with the machine:
the photos, the reminders, the notes, the document writing, the files drive - everything
just works flawlessly out-of-the-box. Updates to all apps happen automatically
behind the scenes, via one centralized App Store app. The OS also updates automatically
and reliably.

I love Apple AirPlay. It's so easy to "move" my AirPads from iPhone to MacBook and
continue listening to the music from the MacBook. Compared to that, the Bluetooth experience
is a complete disaster - you either have to disable bluetooth on the current device,
or to somehow switch the headphones to the pairing mode, in order to "attach" them
to my notebook.

## The Okay-ish

The support for MacBooks will eventually end at some point. My MacBook Air 2015 is stuck
with MacOS 12 Monterey and can no longer update to newer MacOS. The security updates
are still coming, true, but my iPhone warned me that some kind of setting won't be propagated
to the MacBook because it's too old.

Even the machine is really old and no longer fast enough for Java development,
it is still very well usable for common office tasks.

Coming from Linux which is supported pretty much indefinitely and runs on pretty much
ancient machines, this is a bit of a letdown.

## The bad

The fairytale ends when I want to do something beyond what's provided by Apple.

For example, installing Firefox just feels weird - I have to download a dmg, then mount it,
then drag something somewhere to actually install Firefox. Then I [have to eject Firefox](https://support.mozilla.org/en-US/kb/how-download-and-install-firefox-mac)
for mysterious reasons. Afterwards, Firefox doesn't use AppStore but updates on its own.

Installing UTM works, but UTM never updates. IDEA also installs easily but never updates -
you have to install IDEA via the [Toolbox app](https://www.jetbrains.com/toolbox-app/).

The nightmare starts when I want to install git or java or other dev tools.
I pretty much have to use [HomeBrew](https://brew.sh/), which installs by downloading
a bash script from the internet (!!!) and running it as root (!!!). That is just unheard
of in Linux world - no sensible Linux users will ever do such a thing!

Compared to that, installing software on Ubuntu is a breeze - everything can be installed
either via `apt install` or `snap install` and Ubuntu will then take care of updating
everything. All software comes from a trusted repository maintained by the Ubuntu
guys, and is safe to use.

## Verdict

I just won't run a bash script as root. I simply can't force myself to trust HomeBrew.
So, doing development natively on MacBook is out-of-question. However, usually I have an
Ubuntu-in-Ubuntu VM set up for every customer; this kind of setup of [running Ubuntu in a VM on MacBook](../ubuntu-on-macbook/)
is therefore quite interesting to test out.
