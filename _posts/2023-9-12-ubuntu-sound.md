---
layout: post
title: Ubuntu Sound
---

Since Ubuntu 22.10, [PipeWire](https://wiki.archlinux.org/title/PipeWire) replaced
PulseAudio as the default sound server.

## PipeWire

* Use `wpctl status` from the command-line to show the status of all devices, sinks etc.
* Use `wpctl inspect` to show detailed information about a device or a stream.
* Read [pipewire.conf](https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Config-PipeWire#configuration-file-pipewireconf)
  on how to configure the pipewire daemon.

## PulseAudio

* You can use `pavucontrol` to precisely control PulseAudio streams and output devices from your GUI.
* Use `pactl info` from command-line to show the precise status of the audio pipeline.
* Edit `/etc/pulse/server.conf` to change the PulseAudio server configuration (e.g. samplerate and the number of bits)
