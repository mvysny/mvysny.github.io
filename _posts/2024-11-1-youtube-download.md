---
layout: post
title: Youtube Download
---

A quick tips on how to download stuff from Youtube, using [yt-dlp](https://github.com/yt-dlp/yt-dlp).

Setup: run `sudo snap install yt-dlp` to get the downloader.

To download audio, run `yt-dlp -f bestaudio -x "URL"`:
* `-f bestaudio` picks the highest quality audio format
* `-x` drops video
* Not using `--audio-format` to avoid lossy-to-lossy re-encoding, keeping
  the original quality.

More documentation:

* [yt-dlp homepage](https://github.com/yt-dlp/yt-dlp)
* `ytdlp -h`
