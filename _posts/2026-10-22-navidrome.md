---
layout: post
title: "Navidrome: your music collection on your iPhone, over Tailscale"
date: 2026-10-22 18:59:37 +0300
---

I have my music as plain files in `~/Music` on a Linux box at home. I'd like to
listen to it on my iPhone too, at home and away, without uploading anything to
a cloud and without paying for a streaming service. It turns out that's one
container and one iPhone app.

The setup in one picture:

```
 iPhone (Amperfy / substreamer) ──── Tailscale ────▶ my-server:4533
                                                     Navidrome (Podman)
                                                     reads ~/Music
```

[Navidrome](https://www.navidrome.org/) is a self-hosted music server. It
scans your music folder, reads the tags, and serves the library over the web
UI and over the **Subsonic API**. Subsonic is an old, well-established protocol
with plenty of client apps, iPhone ones included. You don't have to convert
or move your files; Navidrome only reads them.

# Prerequisites: Tailscale

The iPhone has to reach the box also when you're away from home. Follow my
[Tailscale](../tailscale/) post: install Tailscale on the Linux box, then
install the Tailscale app from the App Store on the iPhone and log in to the
same tailnet. With MagicDNS on, the box is reachable from the iPhone by its
short name, e.g. `my-server`.

No port forwarding, no public IP, no dynamic DNS. The music server is only
visible to your own devices.

# Install Podman

I run Navidrome in [Podman](../podman/): rootless, no daemon, no root. On
Ubuntu:

```bash
sudo apt install podman podman-compose
```

# Navidrome

Create a folder for Navidrome, plus `data/` for its database and cache:

```bash
mkdir -p ~/local/navidrome/data
```

Don't skip `data/`: unlike Docker, Podman doesn't create a missing bind-mount
directory for you, it refuses to start the container:

```
Error: statfs /home/mavi/local/navidrome/data: no such file or directory
```

Then create `~/local/navidrome/docker-compose.yml`:

```yaml
services:
  navidrome:
    image: docker.io/deluan/navidrome:latest
    ports:
      - "4533:4533"
    restart: unless-stopped
    environment:
      ND_ENABLEINSIGHTSCOLLECTOR: "false"
    volumes:
      - "/home/mavi/local/navidrome/data:/data"
      - "/home/mavi/Music:/music:ro"
```

Replace `mavi` with your username. A few notes:

- The image name is fully-qualified (`docker.io/...`). Podman refuses short
  names that aren't in its alias table, see the [Podman](../podman/) post.
- `/music` is mounted read-only (`:ro`). Navidrome never needs to modify your
  music files, so it doesn't get the chance to.
- `ND_ENABLEINSIGHTSCOLLECTOR: "false"` turns off the anonymous usage
  statistics that Navidrome sends home by default.
- Navidrome's docs suggest adding `user: 1000:1000`. Don't, with rootless
  Podman. The container runs as root by default, and container root is *you*
  on the host, so Navidrome can write into `data/` and read `~/Music` as-is.
  With `user: 1000:1000` it would run as one of your subordinate UIDs instead,
  which can't write into `data/`.
- I'll explain `restart: unless-stopped` below.

I start Navidrome in [tmux](https://github.com/tmux/tmux), so that it keeps
running after I close the terminal or log out of ssh:

```bash
tmux new -s navidrome
cd ~/local/navidrome
podman compose up
```

`podman compose up` runs in the foreground and shows Navidrome's log, so you
can watch it scan your library. Detach with `Ctrl+b d`; Navidrome keeps
running. `tmux attach -t navidrome` takes you back to the log, and `Ctrl+C`
there stops Navidrome.

`podman compose` is only a wrapper: it runs an external compose provider and
prints which one, e.g.
`>>>> Executing external compose provider "/usr/bin/podman-compose"`. If you
have Docker's compose plugin installed as well, it may run Docker's
`docker-compose` instead. In that case call `podman-compose up` directly.

# Create the user

Open [http://localhost:4533](http://localhost:4533) on the box (or
`http://my-server:4533` from any machine in your tailnet). On first launch,
Navidrome asks you to create the admin user: pick a username and a password.
That's also the login your iPhone app will use.

The web UI is a perfectly usable music player too, also in the iPhone's Safari.
But for listening on the go you want a proper app.

# iPhone apps

Any Subsonic client works. These are the two I use:

- [Amperfy](https://github.com/BLeeEZ/amperfy): open source, and it can
  **cache** songs on the phone, so you can listen offline, e.g. on a plane.
  In my experiments it can't play some of my files, though.
- [substreamer](https://apps.apple.com/app/substreamer/id1012991665): free and
  open source too. It plays everything I've thrown at it, but it can't cache,
  so it only works when you're online.

I simply have both installed. In either app, add a server:

- URL: `http://my-server:4533`
- username and password: the Navidrome user you created above.

Make sure the Tailscale app on the iPhone is connected, and that's it. Plain
`http` is fine here: the traffic goes through Tailscale's WireGuard tunnel,
which is encrypted end to end.

# Restarts and reboots

Podman has no daemon, but it does honor the restart policy: if Navidrome
crashes, Podman starts it again. `Ctrl+C` in tmux counts as stopping it
yourself, so with `unless-stopped` it stays stopped.

What Podman doesn't do is start Navidrome when the box boots. There's no daemon
to remember it. After a reboot I simply open the tmux session again and run
`podman compose up`. My box rarely reboots, so that's fine with me.

If you'd rather have it start on boot, Podman ships a systemd user unit,
`podman-restart.service`, which you'd enable together with lingering
(`sudo loginctl enable-linger $USER`). Note that this unit only starts
containers whose policy is `restart: always`, not `unless-stopped`.

# Updating

In the tmux session, stop Navidrome with `Ctrl+C`, then:

```bash
podman compose pull
podman compose up
```

`pull` fetches the newest `latest` image, and `up` recreates the container
from it. Your library, users and playlists live in `data/`, so they survive.

# Stay secure

`"4533:4533"` publishes the port on all interfaces, so Navidrome is reachable
from your home LAN as well as from your tailnet. It's protected by your
Navidrome password, so pick a good one. See the "Stay secure" section of the
[Tailscale](../tailscale/) post for auditing what else is listening on your box.
