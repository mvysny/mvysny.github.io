---
layout: post
title: "Private git repos at home: just git over ssh"
date: 2026-10-22 14:58:14 +0300
---

I work on the same projects from several computers: a desktop, a laptop, a
headless VM. Some of those projects are private and I'd rather not put them on
GitHub. I don't need a git hosting platform for that. A Linux box at home with
`ssh` and `git` installed is enough. No web UI, no database, no daemon, no extra
user. Git has supported ssh remotes since the beginning.

The setup in one picture:

```
 laptop ──┐
          │  ssh (over Tailscale)    my-server
 desktop ─┼────────────────────────▶ ~/git/foo.git   (bare repo)
          │                          ~/git/bar.git
 VM ──────┘
```

Every client has a full clone, with the whole history. The server is just the
agreed meeting point where all the clones push to and pull from.

# Prerequisites: Tailscale and ssh

The home server has to be reachable from all your machines, also when you're
away from home. Follow my [Tailscale](../tailscale/) post: install Tailscale on
the server and on every client, set up key-based ssh, and turn off password
login.

With **MagicDNS** enabled (it's on by default for new tailnets; check the
*DNS* page in the Tailscale admin console), every machine is reachable by its
short name, e.g. `my-server`. The name is the machine's hostname, and you can
rename it in the admin console. Check that this works from every client:

```bash
ssh my-server
```

It should log you in without asking for a password. That's the only "auth"
this setup needs: whoever can ssh into your account on `my-server` can push and
pull. In this case that's you, from the computers you own.

# Install git on the server

Ubuntu 26.04 Server usually has git already, but just to be sure:

```bash
sudo apt install git openssh-server
```

That's all the server needs. When you push or pull, the client ssh's into the
server and runs `git-receive-pack` or `git-upload-pack` there. Those are plain
git binaries, nothing runs in the background.

## Why not a dedicated `git` user?

Most tutorials create a `git` user with `git-shell` as its login shell. That's
useful when you hand out access to other people or to less trusted machines
(CI runners, deploy keys), and want those keys limited to git only. Here it's
just me, with the same keys that already give me a full shell on `my-server`.
A `git` user wouldn't add any protection. I'd only get a second
`authorized_keys` to keep in sync, so I reuse my own account.

If ssh says `Permission denied` and the username on `my-server` differs from the
one on your client, tell ssh which user to use in `~/.ssh/config` on the client:

```
Host my-server
    User martin
```

# Creating a repo

On the server, repos live in `~/git/` as **bare** repos: just the git database,
no working directory. You never edit files in a bare repo, you only push to it
and pull from it.
The `.git` suffix is a convention for bare repos.

Git won't create a repo on push, so create it first. You don't even have to log
in. Run this from any client:

```bash
ssh my-server git init --bare -b master git/foo.git
```

`git init` creates `~/git/` too if needed. `-b master` sets the default branch;
use `main` if that's what you prefer. It just has to match the branch you'll
push.

# Pushing an existing project

In the project on your client:

```bash
git remote add origin my-server:git/foo.git
git push -u origin master
```

`my-server:git/foo.git` is the scp-like ssh syntax: host, a colon, and a path.
A path without a leading `/` is relative to your home dir on the server. If the
project already has an `origin` (say, GitHub), give this remote a different
name, e.g. `home`.

# Cloning on another computer

```bash
git clone my-server:git/foo.git
```

That's it. `origin` and the upstream branch are set up already.

To see which repos you have:

```bash
ssh my-server ls git
```

## Working on the server itself

`my-server` can be one of your work machines too. Clone the bare repo there as
well, straight from the local path, no ssh needed:

```bash
git clone ~/git/xyz.git ~/work/my/xyz
```

`~/work/my/xyz` is now an ordinary working copy, with `origin` pointing to
`~/git/xyz.git`. Pull and push as on any other machine. The clients see your
pushes as usual, because they all pull from the same bare repo.

# Day-to-day

It's plain git, the same as with GitHub. Pull before you start working on a
machine, and push when you're done:

```bash
git pull
# ...hack, commit...
git push
```

If you forget to pull and another computer pushed in the meantime, `git push`
gets rejected. That's fine: `git pull` (merge or rebase, as you like), then push
again. Nothing gets lost.

# What about backups?

I don't bother. Every clone has the full history, so as long as I push and pull
regularly, any of my computers has an up-to-date copy. If `my-server` dies, I
create a fresh bare repo somewhere else and push to it from any clone.

# What you don't get

A web UI, pull requests, issues, CI. For a solo developer working on their own
projects, I don't miss any of it. For browsing history, diffs and branches I
use [lazygit](https://github.com/jesseduffield/lazygit), a terminal UI for git
that's packaged in Ubuntu:

```bash
sudo apt install lazygit
```

It's worth an alias, since you'll type it a lot. Add this to `~/.bashrc`:

```bash
alias lg=lazygit
```

(In fish: `alias --save lg lazygit`.)

If you want a web UI and the rest anyway, Forgejo is a lightweight self-hosted
option. I'll cover that in a follow-up post.
