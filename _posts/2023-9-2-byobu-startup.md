---
layout: post
title: Byobu Startup
---

On my servers, I like to have two things:

* `~/README.md` which documents everything that's installed on the server machine; its purpose, paths, commands, etc etc
* A Byobu startup script which runs all programs, supposed to be running on the server, in byobu

I'll use the Byobu Tmux integration. Tmux scripting sucks hard (any problem in the script is silently ignored),
but it kinda works so we'll use that. First, install byobu via `sudo apt install byobu`. Then,
let's create a Byobu profile named `startup` (it's just a name, you can use `foo` equally well).
Create a file named `~/.byobu/windows.tmux.startup` with the following contents:

```byobu
new-session -n stats ;
send-keys ./stats Enter ;
new-window -n growatt ;
send-keys ./growatt Enter ;
new-window -n syntak ;
send-keys cd Space local Enter ;
send-keys ./syntak Enter ;
new-window -n rslsync ;
send-keys ./rslsync Enter ;
new-window -n apt ;
```

The tmux scripting is horrible, so I'll explain:

* `new-session -n stats` creates a new session and ALSO a new window named `stats`.
  The window will run your shell automatically.
* `send-keys ./stats Enter` will run the `~/stats` script in the shell, without terminating the shell.
  Note the `Enter` constant which sends the Enter key, to run the `./stats` script.
* `new-window -n growatt` creates a new window named `growatt`.
* `send-keys ./growatt Enter` runs the `~/growatt` script in the shell.
* `send-keys cd Space local Enter` will run `cd local` (note the `Space` which inserts space -- wtf) and keeps the shell running.

etc etc. To run Byobu and open all windows and run the script above, run:

```bash
$ BYOBU_WINDOWS=startup byobu
```

I like to have a `~/startup` script which runs the command above. I simply run manually after the server boots up, from a ssh session.

```bash
#!/bin/bash
set -e -o pipefail
BYOBU_WINDOWS=startup byobu
```
