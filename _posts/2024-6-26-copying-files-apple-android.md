---
layout: post
title: Copying files between Apple and Android devices
---

I have an Android Tablet for kids, with VLC and a bunch of movies installed.
Recently I needed to copy over some new movies from MacBook, and it just wouldn't work.

## Android devices

Android devices copy files over the MTP protocol. Usually when you connect
the device to a laptop, Android asks whether you only wish to charge or whether you
want to copy files (over MTP). Choose MTP, and then you have full access to the filesystem.

The easiest way is to connect the Android device to a Linux laptop. Things will just work.

Connecting Android device via USB cable to MacBook is when shit hits the fan. MacBook doesn't support
MTP and you need to use a specialized program such as Commander One, to copy files.
Unfortunately, my tablet just won't work:

1. It won't show the USB dialog allowing me to choose MTP
2. The [Commander One Troubleshooting](https://ftp-mac.com/faq/mtp-device-troubleshooting/) doesn't work -
  enabling USB debugging nor dev mode helped.

The easiest way is to fuck the cable, install the `WiFi FTP Server` Android app, and then
connect to the FTP. Note that fucking MacBook Finder only supports read-only FTP, so you need to use
Commander One. However, don't use "Connect to Server" from Commander One, since that goes through
Finder and you'll end up with a read-only mount. Use CommanderOne-specific "Connection Manager"
which allows rw access over FTP.

## iPhone

iPhone supports MTP, but it never exposes full filesystem over MTP. By default, there's no
place to store the videos and music to. The easiest way is
to install VLC on iPhone, which creates an VLC folder in MTP, and you can then copy the music there.

To copy files via a cable, the easiest way is to connect iPhone to a Linux laptop,
and just copy files over MTP.

You can also connect iPhone to a MacBook, but that opens a Finder window which is
completely useless - you can only copy to iPhone's VLC folder via drag'n'drop, but you can't move files
around, delete them or do any other file ops. Just ridiculous.

iPhone VLC supports copying files over http though: go to Network and enable "Sharing via WI-FI".
You can now point your browser on your MacBook to the address VLC tells you, and you can perform
some basic file ops.

## Conclusion

MacBook's support for copying files over MTP to Android devices or iPhone is a complete
disaster. If you can, use Linux. If you can't, use some workarounds above; the easiest
workaround is to go via FTP over WiFi.
