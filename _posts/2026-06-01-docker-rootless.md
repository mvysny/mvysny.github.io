---
layout: post
title: The docker group is root - run Docker rootless instead
---

Here's something that took me far too long to internalize: **being in the
`docker` group is equivalent to having passwordless root.** This is not a bug,
it's not a misconfiguration, and Docker even
[documents it](https://docs.docker.com/engine/install/linux-postinstall/). It's
just a consequence of how the daemon works - and most Linux users who run Docker
never realize they've quietly handed out the keys to the whole machine.

# Why the docker group is root

The Docker daemon runs as root and listens on a Unix socket
(`/var/run/docker.sock`). Anyone who can talk to that socket can ask the daemon
to do root things on their behalf. Membership in the `docker` group grants
exactly that access. So this command - which any program running as *you* can
issue, no `sudo` required - is game over:

```bash
docker run --rm -v /:/host -it ubuntu chroot /host
```

You just mounted the host's entire root filesystem into a container and
`chroot`ed into it as root. From there you can read `/root`, read every user's
SSH private keys, rewrite `/etc/shadow`, drop a setuid binary, edit
`/etc/sudoers` - anything. The `-v /:/host` bind mount is the whole trick: the
daemon is root, so the files it mounts are owned and writable as root.

The scary part isn't *you* typing that command. It's that **any process running
under your account can do it** - a malicious npm package, a compromised browser
extension, a curl-to-bash installer you ran without reading. None of them need a
privilege-escalation exploit. They just need to find the `docker` binary on your
`PATH`. Being in the `docker` group converts "this app can mess with my home
directory" into "this app owns my computer".

# Rootless Docker fixes this

[Rootless mode](https://docs.docker.com/engine/security/rootless/) runs the
daemon and the containers inside a **user namespace**, as your unprivileged
user. Root inside a container maps to your UID on the host (or to a range of
subordinate UIDs), not to real root. The socket lives under
`/run/user/$UID/docker.sock`, owned by you. Now the worst that the `-v /:/host`
trick can do is give a container the same access *you* already have - which is
the access the malicious process had anyway. The privilege escalation is gone.

There are trade-offs (no binding to ports below 1024 without extra setup, some
storage-driver and networking limitations, slightly more overhead), but for a
personal workstation they almost never matter. The security win is worth it.

# Setting it up on Ubuntu 26.04

This assumes you installed Docker from Ubuntu's own repos
(`sudo apt install docker.io`), which is what ships the rootless helper scripts
under `/usr/share/docker.io/contrib`.

**1. Remove yourself from the `docker` group** - this is the whole point, so
don't skip it. The group membership only clears on a new login session, so
reboot afterwards:

```bash
sudo deluser $USER docker
sudo reboot
```

**2. Disable the system-wide (rootful) daemon.** You don't want the root daemon
running anymore:

```bash
sudo systemctl disable --now docker.service docker.socket
```

**3. Put the rootless helper scripts on your `PATH`.** Ubuntu's package drops
them in `/usr/share/docker.io/contrib` rather than `/usr/bin`:

```bash
cd /usr/share/docker.io/contrib
export PATH="$PATH:$(pwd)"
```

**4. Check the prerequisites:**

```bash
dockerd-rootless-setuptool.sh check
```

It should print `[INFO] Requirements are satisfied`. If it complains about a
missing dependency, the most common one is:

**5. Install `rootlesskit`** (the user-namespace plumbing rootless mode relies
on):

```bash
sudo apt install rootlesskit
```

**6. Install the rootless daemon.** This sets up a *user-level* systemd service
(`docker.service` in your `--user` scope) and starts it:

```bash
dockerd-rootless-setuptool.sh install
```

> **Note:** in my run, the script set everything up correctly but then failed at
> the very end while trying to *verify* the install (it couldn't reach the
> daemon yet, because `DOCKER_HOST` wasn't exported in that shell). That final
> verification error is harmless - the service is installed and running. The
> next step fixes the connectivity.

**7. Point the client at your rootless socket.** The `docker` *daemon* already
knows where its socket is - this step is purely about telling the `docker`
*client* (the CLI) to talk to the rootless socket instead of the old rootful
`/var/run/docker.sock`. There are two ways to do it; pick one.

*Option A - the `DOCKER_HOST` environment variable:*

```bash
export DOCKER_HOST=unix:///run/user/1000/docker.sock
```

`1000` is the UID of the first regular user on Ubuntu - check yours with `id -u`
if you're unsure. But note this only lasts for the current shell - it's **gone
on the next login or reboot**. To make it permanent, add the line to your
`~/.bashrc` (or `~/.zshrc`).

*Option B - a Docker CLI context (survives reboots, no env var needed):*

A context stores the socket location in `~/.docker/` and persists across shells
and reboots on its own. Some installers create a `rootless` context for you, but
Ubuntu's packaged helper does not, so create it yourself:

```bash
docker context create rootless --docker host=unix:///run/user/1000/docker.sock
docker context use rootless
```

The one catch: **`DOCKER_HOST` always overrides the active context.** So if you
go with Option B, make sure you have *not* also exported `DOCKER_HOST` (remove it
from `~/.bashrc` and `unset DOCKER_HOST` in your current shell) - otherwise the
env var wins and `docker context use` silently has no effect. Don't set both.

**8. Verify it actually works:**

```bash
docker run --rm hello-world
```

You should see the familiar **`Hello from Docker!`** banner. That's it - you're
now running containers without the root daemon, and the `docker` group on this
machine no longer grants anyone root.

# Keeping the daemon alive after logout

By default a user systemd service stops when your last session ends. If you want
your rootless Docker to keep running in the background (e.g. for long-running
containers on a server), enable **lingering** for your user:

```bash
sudo loginctl enable-linger $USER
systemctl --user enable docker
```

# Uninstalling

Say you're moving on (to [Podman](../podman/), for example).
`sudo apt purge docker.io` is **not enough**. The setup tool wrote your
user-level `~/.config/systemd/user/docker.service` and its auto-start symlink,
and dpkg doesn't own either file, so apt never touches them. After the purge,
`systemctl --user status docker` still shows the service, which now fails to
start because its script is gone. Your images in `~/.local/share/docker` and the
`rootless` context in `~/.docker` stay behind too.

Do it in this order, because step 1 needs tools that ship in `docker.io`:

**1. Undo the rootless setup while Docker is still installed.** `uninstall`
stops and disables the user service, deletes its unit file, removes the
`rootless` CLI context and switches the CLI back to `default`:

```bash
/usr/share/docker.io/contrib/dockerd-rootless-setuptool.sh uninstall
rootlesskit rm -rf ~/.local/share/docker
rm -rf ~/.docker
```

The images and containers in `~/.local/share/docker` belong to your
*subordinate* UIDs, not to you, so a plain `rm -rf` fails with
`Permission denied`. `rootlesskit rm` runs inside the same user namespace as the
daemon, where those files are yours. Also remove the `DOCKER_HOST` line from
`~/.bashrc` if you went with Option A, and run `sudo loginctl disable-linger $USER`
if you enabled lingering and nothing else needs it.

**2. Remove the packages:**

```bash
sudo apt purge docker.io docker-buildx docker-compose-v2 containerd rootlesskit
sudo apt autoremove --purge
```

Leave `runc` and `slirp4netns` installed if you use Podman, because it depends
on both.

**3. Remove what's left of the old rootful setup:**

```bash
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker
sudo groupdel docker
```

**Already purged the package and the service is still there?** The setup tool
went away with the package, so do step 1 by hand:

```bash
systemctl --user disable --now docker
rm ~/.config/systemd/user/docker.service
systemctl --user daemon-reload
systemctl --user reset-failed
podman unshare rm -rf ~/.local/share/docker
```

Without `rootlesskit`, `podman unshare` does the same job: it enters a user
namespace with the same `/etc/subuid` mapping. If Podman isn't installed either,
`sudo rm -rf ~/.local/share/docker` works too.

# Was it worth it?

For me, yes - without hesitation. The `docker` group is one of those defaults
that's convenient right up until you think about what it actually means. On a
multi-purpose workstation where I run other people's code all day, "any process
I run can become root" is not a risk I want sitting there silently. Rootless
mode closes that door with about ten minutes of one-time setup, and day to day I
don't notice the difference.
