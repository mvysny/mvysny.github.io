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

## Ubuntu 21.10+

The `gnome-shell-extension-system-monitor` package doesn't work with GNOME 40+ yet (as of version `38+git20200414-32cc79e-1`),
see+vote on [Issue 704](https://github.com/paradoxxxzero/gnome-shell-system-monitor-applet/issues/704).
However, it does work when ran via `chrome-gnome-shell`:

1. Uninstall the extension deb package: `sudo apt autoremove --purge gnome-shell-extension-system-monitor`.
   Don't worry, your settings will be preserved.
2. `sudo apt install chrome-gnome-shell` - this will allow to install and update extensions
   from your browser (yeah I don't really like browser installing stuff into my system, but what can you do.)
3. Visit [gnome-shell-system-monitor-applet](https://github.com/paradoxxxzero/gnome-shell-system-monitor-applet) and install
   all the necessary system packages as described by the page.
4. Visit [https://extensions.gnome.org/extension/120/system-monitor/](https://extensions.gnome.org/extension/120/system-monitor/)
   and install the system-monitor gnome extension via Firefox.
   A Firefox extension is needed in order to install gnome extensions, the page will prompt you to install the plugin. You do
   not need to log in into the extensions.gnome.org website.
5. Download and enable the extension. The system monitor will be shown but the Preferences
   will fail to start, see+vote on [Issue 704](https://github.com/paradoxxxzero/gnome-shell-system-monitor-applet/issues/704).
6. If the system monitor will fail to start and the [local extensions](https://extensions.gnome.org/local) page
   will show an ERROR next to the system-monitor add-on, simply logout and login again,
   or reboot your machine.

Warning: Firefox installed via snap (the default for Ubuntu 21.10) doesn't support
connections to 'native host connector' (`chrome-gnome-shell`), see+vote for
[Ubuntu bug #1741074](https://bugs.launchpad.net/ubuntu/+source/chromium-browser/+bug/1741074).
The only known workaround is to uninstall the
Firefox snap and install the Firefox deb via:

1. `sudo snap remove --purge firefox`
2. `sudo apt install firefox`
3. `sudo apt autoremove --purge lynx`

then repeat the process above.

### Going with the package

`gnome-tweaks` no longer manages gnome extensions starting from Ubuntu 21.10. Therefore,
you have to install a flatpak which manages gnome extensions as mentioned below.

Run

```bash
sudo apt install gnome-shell-extension-system-monitor
```

If the extension doesn't activate itself, install the [org.gnome.Extensions flatpak](https://flathub.org/apps/details/org.gnome.Extensions).
Follow these guides to [install flatpak on Ubuntu](https://flatpak.org/setup/Ubuntu/) - it's really easy.

Run the app via

```bash
flatpak run org.gnome.Extensions
```
then make sure the `system-monitor` extension is enabled.

> NOTE: This approach doesn't work at the moment; the extension will not start and
> will show an exception instead.

## Ubuntu 21.04 and older

You can install install the extension via the browser, but I really hate browser installing stuff onto my machine,
so I'll use the old-fashioned `apt` command:

```bash
sudo apt install gnome-shell-extension-system-monitor
```

Log out, log in, the extension should auto-activate itself. If not, follow on.

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

