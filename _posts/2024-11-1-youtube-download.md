---
layout: post
title: Youtube Download
---

A quick tips on how to download stuff from Youtube, using [yt-dlp](https://github.com/yt-dlp/yt-dlp).

Setup: run `sudo snap install yt-dlp` to get the downloader.

To download audio, run `yt-dlp --extract-audio "URL"`.

Alternatively, run `yt-dlp -f bestaudio -x "URL"`:
* `-f bestaudio` picks the highest quality audio format
* `-x` drops video
* Not using `--audio-format` to avoid lossy-to-lossy re-encoding, keeping
  the original quality.

To list all available formats:
```bash
$ yt-dlp --list-formats "URL"
```

More documentation:

* [yt-dlp homepage](https://github.com/yt-dlp/yt-dlp)
* `yt-dlp -h`
* Additional tips: [How to use yt-dlp](https://commandmasters.com/commands/yt-dlp-common/)

