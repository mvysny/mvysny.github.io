---
layout: post
title: "virt-manager: the VM screen is black and frozen"
date: 2026-11-11 15:58:24 +0200
---

I run an Ubuntu 26.04 guest in [virt-manager](../virt-manager/) on an Ubuntu
26.10 host, with the Virtio video card, 3D acceleration enabled, and the SPICE
display with OpenGL turned on. I mostly work in the VM over ssh, but it has a
head, and every now and then I want to click something in it. And almost every
time I opened the VM window, the screen was black and frozen. Mouse, keyboard,
nothing helped. The only time the display reliably worked was right after the
VM booted. This has been plaguing me for at least a year, back when the host
was still Ubuntu 26.04, so it's nothing new in 26.10.

It drove me nuts, and I was ready to turn the 3D acceleration off. Turns out
that's not necessary: the fix is a two-line config change in the guest.

# What's going on

I didn't have to guess, since I could ssh into the guest and look. The first
surprise: nobody was logged in on the VM's screen at all. Only the GDM login
screen was showing; my ssh sessions don't count, they're not on the
screen.

The second surprise: the guest had turned its (virtual) monitor off:

```bash
$ cat /sys/class/drm/card1-Virtual-1/dpms
Off
```

The card number may differ on your machine; `ls /sys/class/drm/` shows the
connectors. The logs were clean: no GPU errors, no `gnome-shell` crash. Nothing
was broken. The guest simply blanked the screen, the way it would on any
laptop.

That's because the GDM login screen has its own settings, separate from
yours, and it uses GNOME's defaults: blank the screen after 5 minutes of
inactivity (`idle-delay=300`), and suspend the machine after 20 minutes. What
counts as activity is keyboard and mouse input on the VM's own screen. All the
work I do over ssh doesn't count, so the guest decided it was idle and blanked
the screen 5 minutes after every boot. Hence "it only works right after boot".

Normally, moving the mouse wakes the screen up again. With SPICE + OpenGL
(virgl) it often doesn't: the display stays black. I haven't dug into which
side drops the ball, the guest or the viewer, and I don't need to: if the
guest never blanks the screen, there's nothing to wake up.

# Quick fix: restart GDM

To get the screen back right now, run this in the guest over ssh:

```bash
sudo systemctl restart gdm
```

GDM starts a fresh login screen, and the display comes back immediately.

Careful: this kills any graphical session on the VM, with all its windows.
In my case, nobody was logged in on the screen, so there was nothing to
lose; check `loginctl list-sessions` first. Sessions that have a `seat0`
belong to the screen, while your ssh sessions show no seat.

The screen goes black again 5 minutes later, though. On to the real fix.

# The fix: stop the login screen from blanking

The login screen's settings come from `/etc/gdm3/greeter.dconf-defaults`. Every
time GDM starts, it compiles that file into its settings database, so editing
it and restarting GDM is all it takes. Open it with:

```bash
sudoedit /etc/gdm3/greeter.dconf-defaults
```

In the existing `[org/gnome/settings-daemon/plugins/power]` section, there's a
commented-out `# sleep-inactive-ac-type='suspend'` line. Uncomment it and change
it to `nothing`, so that the login screen never suspends the VM:

```
[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
```

Then add a new section at the end of the file, to stop the screen from
blanking:

```
[org/gnome/desktop/session]
idle-delay=uint32 0
```

If you'd rather not open an editor, these two commands do the same on
Ubuntu's stock file. Only run them once, since the second one appends:

```bash
sudo sed -i "s/^# sleep-inactive-ac-type='suspend'/sleep-inactive-ac-type='nothing'/" /etc/gdm3/greeter.dconf-defaults
printf '\n[org/gnome/desktop/session]\nidle-delay=uint32 0\n' | sudo tee -a /etc/gdm3/greeter.dconf-defaults
```

Then restart GDM to apply it:

```bash
sudo systemctl restart gdm
```

To check that it worked, leave the VM window alone for more than 5 minutes,
then look at the monitor's state again:

```bash
$ cat /sys/class/drm/card1-Virtual-1/dpms
On
```

The screen has been on ever since.

# Your own session

The same applies once you log in on the VM's screen: your own GNOME session
has the same defaults, and they're per-user, so you set them for your user,
without `sudo`:

```bash
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
```

The first one is the same as Settings → Power → Screen Blank → Never. I had
set that one ages ago, so my own session never blanked the screen; I just
never noticed that the login screen has settings of its own.

# Plan B: turn the 3D acceleration off

If the screen still goes black, you can turn the acceleration off. This is a
host-side setting, so it can't be done from inside the guest. In virt-manager,
open the VM's details and:

- under "Display Spice", uncheck "OpenGL";
- under "Video Virtio", uncheck "3D acceleration".

Or with `sudo virsh edit <vm>`: `<gl enable='no'/>` inside `<graphics>`, and
`<acceleration accel3d='no'/>` inside `<video><model>`.

Then shut the VM down completely and start it again. A reboot from inside the
guest doesn't pick up the new settings, since QEMU keeps running. GNOME then
renders in software, which is noticeably slower, but OK for the occasional click.

I didn't need plan B: with the blanking gone, I'm keeping the smooth 3D
acceleration.
