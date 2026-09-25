---
layout: post
title: "VS Code on a headless coding VM, via code-server and an SSH tunnel"
date: 2026-09-25 17:40:00 +0300
---

I do my coding on a headless VM. The machine in front of me is just a remote
terminal: I ssh into the VM and do everything there, in tmux, with Claude Code
and [LazyVim](../lazyvim-for-idea-devs/). That works great for code, and it has
one big weak spot: **reading Markdown**. Claude produces a lot of Markdown
(plans, design docs, READMEs, `AGENTS.md`), and reading it as raw text in a
terminal is a pain. Tables come out as ASCII soup, there are no images, and I
can't click links.

I tried a few remote Markdown viewers. Then it dawned on me: VS Code has a
perfectly good Markdown preview, and while I'm at it, VS Code is also a
full-blown IDE. [code-server](https://github.com/coder/code-server) runs VS Code
on the VM and serves it to a browser. All I need is a browser on the terminal
machine and an SSH tunnel.

# The setup in one picture

```
 terminal machine                          headless VM
 ┌────────────────────────┐  ssh -L 5000  ┌──────────────────────────────┐
 │ browser                │ ════════════▶ │ code-server                  │
 │ http://localhost:5000  │               │ listening on 127.0.0.1:5000  │
 └────────────────────────┘               └──────────────────────────────┘
```

code-server listens only on the VM's loopback, so nothing on the network can
reach it. The SSH tunnel is the only way in. That's why it doesn't need a
password.

# Install code-server on the VM

I followed the [Debian/Ubuntu
instructions](https://coder.com/docs/code-server/install#debian-ubuntu): grab
the `.deb` from the GitHub releases, install it, and enable the systemd unit
the package ships:

```bash
VERSION=4.137.0
curl -fOL https://github.com/coder/code-server/releases/download/v$VERSION/code-server_${VERSION}_amd64.deb
sudo dpkg -i code-server_${VERSION}_amd64.deb
sudo systemctl enable --now code-server@$USER
```

`code-server@.service` is a template unit, so `code-server@mavi` runs
code-server as the user `mavi`, starts it at boot and restarts it if it dies.
One thing to know: the `.deb` doesn't add an apt repository, so
`apt upgrade` won't update it. To upgrade, install a newer `.deb` the same way.

# Configure it: localhost only, no password

The config file is `~/.config/code-server/config.yaml`. On first start
code-server generates one with a random password. Mine looks like this:

```yaml
bind-addr: 127.0.0.1:5000
auth: none
cert: false
```

- `bind-addr: 127.0.0.1:5000` binds to loopback only, so the VM's network
  interfaces don't expose it at all.
- `auth: none` turns off the password page. The only way to reach the port is
  through SSH, and SSH already authenticated me. A second password adds
  nothing. (This assumes the VM is single-user: any other local user or process
  on the VM can also reach the port.)
- `cert: false` means plain HTTP. There's no need for TLS, because the tunnel
  already encrypts the traffic.

Restart it after editing the config:

```bash
sudo systemctl restart code-server@$USER
```

# Tunnel it to the terminal machine

On the terminal machine:

```bash
ssh vm -L 5000:localhost:5000
```

Then open **http://localhost:5000** in the browser. That's the whole trick: the
full VS Code, with the VM's filesystem, terminals, git and language servers,
in a browser tab.

I don't pass `-N`, so the same ssh session also gives me a shell. My
tmux+Claude workflow stays where it was, and VS Code sits next to it. To make
the tunnel automatic, add it to `~/.ssh/config` on the terminal machine:

```
Host vm
    LocalForward 5000 localhost:5000
```

## Why it has to be `localhost`

Don't be tempted to skip the tunnel and open `http://<vm-ip>:5000` directly
(with `bind-addr: 0.0.0.0`). Some browser features only work in a **secure
context**, which means either HTTPS or `localhost`/`127.0.0.1`. Plain HTTP to
an IP address is not a secure context, so the browser disables things like:

- **Clipboard access.** Copy/paste between VS Code and the rest of your
  desktop stops working properly.
- **Service workers.** VS Code *webviews* depend on them, and per the
  [code-server FAQ](https://coder.com/docs/code-server/FAQ), webviews break
  without a secure context. The Markdown preview is a webview, so you'd lose
  exactly the feature I came here for.

Through the tunnel the browser sees `localhost`, which counts as secure, so
everything works without dealing with certificates.

# Make it feel like LazyVim

My muscle memory is LazyVim's, so I made VS Code follow it. Install the
[VSCodeVim](https://open-vsx.org/extension/vscodevim/vim) extension. Note that
code-server uses the [Open VSX](https://open-vsx.org/) gallery, not
Microsoft's marketplace. Most popular extensions are there, including Claude
Code, Red Hat's Java support and Ruby LSP; the closed-source Microsoft ones,
like Live Share and the Remote-* family, are not.

Then map the LazyVim keys onto VS Code commands in the user settings. In
code-server those live at `~/.local/share/code-server/User/settings.json` on the
VM, not in `~/.config/Code`. Download [my
settings.json](/files/code-server-headless-vm/settings.json) and save it there.
It maps `<Space>` as leader, `<Space><Space>` / `<Space>ff` for file search,
`<Space>/` for grep, `H`/`L` to cycle editors, `<Space>c*` for code actions,
`]d`/`[d` for diagnostics, `]h`/`[h` for git hunks, and so on. Here's a taste:

```jsonc
{
  "vim.leader": "<space>",
  "vim.normalModeKeyBindingsNonRecursive": [
    { "before": ["<leader>", "<leader>"], "commands": ["workbench.action.quickOpen"] },
    { "before": ["<leader>", "/"], "commands": ["workbench.action.findInFiles"] },
    { "before": ["<S-h>"], "commands": ["workbench.action.previousEditor"] },
    { "before": ["<S-l>"], "commands": ["workbench.action.nextEditor"] },
    { "before": ["<leader>", "c", "a"], "commands": ["editor.action.quickFix"] },
    { "before": ["]", "h"], "commands": ["workbench.action.editor.nextChange"] },
    // ...and about 40 more
  ]
}
```

A few notes:

- `vim.handleKeys` hands `Ctrl+B`, `Ctrl+P` and `Ctrl+C` back to VS Code, so the
  sidebar toggle, quick open and copy keep working.
- VS Code has no real flash.vim, so `s` falls back to VSCodeVim's built-in
  easymotion search.
- VSCodeVim can't do exactly what LazyVim does when a mapping is a prefix of a
  longer one (`<leader>w` vs `<leader>wd`, `<leader>c` vs `<leader>cf` in
  visual mode). It waits briefly for the next key, and that's good enough for
  me.

# Result

Nothing about the VM changed. It's still headless, and tmux, Claude and
LazyVim are still there for when I want them. I just gained a browser tab with
a full IDE on the same files: rendered Markdown, a proper diff viewer, a
debugger, and LazyVim-ish keybindings so my fingers don't notice the switch.
The terminal machine still needs nothing but ssh and a browser.
