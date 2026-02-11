---
layout: post
title: Tmux Startup
---

On my servers, I like to have two things:

* `~/README.md` which documents everything that's installed on the server machine; its purpose, paths, commands, etc etc
* A Tmux startup script which runs all programs, supposed to be running on the server, in tmux

First, install tmux via `sudo apt install tmux`. Then,
let's create a script which will:

- create a tmux session named `startup` (it's just a name, you can use `foo` equally well)
- create windows and run commands in that session
- connect to it

Create a script named `~/startup` with the following contents:

```bash
#!/usr/bin/env bash
SESSION="startup"

# If session already exists → just attach
tmux has-session -t "$SESSION" 2>/dev/null && {
  tmux attach-session -t "$SESSION"
  exit
}

# Otherwise create it from scratch (detached)
tmux new-session -s "$SESSION" -d -n window1 -d
tmux send-keys -t "$SESSION:window1" "cd work && ls -la" C-m
tmux new-window -t "$SESSION" -n window2 -d
tmux send-keys -t "$SESSION:window2" "cd Documents && ls -la" C-m
tmux attach-session -t "$SESSION"
```

The tmux scripting is horrible, so I'll explain:

* `new-session -n stats` creates a new session and ALSO a new window named `stats`.
  The window will run your shell automatically.
* `send-keys ./stats Enter` will run the `~/stats` script in the shell, without terminating the shell.
* `new-window -n growatt` creates a new window named `growatt`.
* `send-keys ./growatt Enter` runs the `~/growatt` script in the shell.

I simply run this script manually after the server boots up, from a ssh session.

# Configuration

To change the color scheme and to change the hot key to `c-A`,
create `~/.tmux.conf`:
```
# Set the prefix to Ctrl+a
set -g prefix C-a

# Remove the old prefix
unbind C-b

# Send Ctrl+a to applications by pressing it twice
bind C-a send-prefix

set -g status-bg cyan
set -g window-status-style bg=yellow
set -g window-status-current-style bg=red,fg=white
```

# Hotkeys

* `c-a ?` shows keyboard help
* `c-a d` detaches from tmux
* To reattach to a running session, just run `./startup`
* `c-a c` for new window
* `c-a n`/`c-a p` for next/prev window
* `c-A` then `[` to scroll; `hjkl` and `c-D`/`c-U` works with cursor movements

