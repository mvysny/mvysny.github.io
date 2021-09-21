---
layout: post
title: Install System Monitor Extension To Ubuntu Gnome
---

Previous article mentioned four of the most important yet most basic resources to monitor for the health of your JVM, but also
of your system:

* CPU - high CPU usage affects your notebook by killing your battery. You need to hunt down that rogue browser tab or app that's using most of your CPU, and kill it.
  It might be as ridiculous as [Chrome animating a 16x16 gif](https://bugs.chromium.org/p/chromium/issues/detail?id=165750)
* disk - high disk usage affects speed with which your apps start or respond.
* memory - high memory usage increases swapping and may lead to apps being killed or your desktop grinding to halt.
* network - if apt or snap or something else suddenly decides to download 2GB worth of stuff while you're on roaming/metered connection.

To easily monitor those in your Ubuntu desktop, you can install the System Monitor Extension which would then show itself permanently in the Gnome Shell Tray.

You can install install the extension via the browser, but I really hate browser installing stuff onto my machine, so I'll use the old-fashioned `apt` command:

```bash
sudo apt install gnome-shell-extension-system-monitor
```

Log out, log in, the extension should auto-activate itself. If not, follow on.

## Ubuntu 21.10+

The extension currently doesn't work with GNOME 40+, see+vote on [Issue 704](https://github.com/paradoxxxzero/gnome-shell-system-monitor-applet/issues/704).

If the extension doesn't activate itself, install the [org.gnome.Extensions flatpak](https://flathub.org/apps/details/org.gnome.Extensions).
Follow these guides to [install flatpak on Ubuntu](https://flatpak.org/setup/Ubuntu/) - it's really easy.

Run the app via

```bash
flatpak run org.gnome.Extensions
```
then make sure the `system-monitor` extension is enabled.

> Note that `gnome-tweaks` no longer manages gnome extensions starting from Ubuntu 21.10.

## Ubuntu 21.04 and older

Simply install the Gnome Tweaks:

```bash
sudo apt install gnome-tweaks
```

Then launch it, go to the Extensions tab and make sure that the System-monitor extension is activated.

### Reporting Bugs

Since this extension literally breaks on every Ubuntu upgrade, it's worth knowing how to report bugs.

1. type `ubuntu-bug gnome-shell-extension-system-monitor` into terminal, to report issues to Ubuntu bug tracker.
2. To see the stacktrace, type `journalctl /usr/bin/gnome-shell -r` and search for something like `JS ERROR: Extension system-monitor@paradoxxx.zero.gmail.com`.
  Paste that information into the bug report.

