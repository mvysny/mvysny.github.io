---
layout: post
title: LazyVim for Intellij IDEA developers
---

[Intellij IDEA](https://www.jetbrains.com/idea/) is an excellent IDE with a mediocre text editor
that takes ages to start. [LazyVim](https://www.lazyvim.org/) is an excellent/completely crazy
editor (depends on your point of view) with an interesting IDE
capabilities and starts in milliseconds. I'll teach you the LazyVim
IDE when coming from IDEA so that you feel reasonably at home.

# Installation

- If you're on Ubuntu, [LazyVim Ubuntu Installer](https://github.com/mvysny/lazyvim-ubuntu) may help.
- Or try [Omarchy](https://omarchy.org/) - it has LazyVim baked in
- Or [install manually](https://www.lazyvim.org/installation)

You most probably want to [enable Java support in LazyVim](https://www.lazyvim.org/extras/lang/java):
- from LazyVim home screen: Open `Lazy Extras` by pressing `x`, OR
- from anywhere in LazyVim: type in `:LazyExtras`
- Press `/` then search for `lang.java`
- Type in `x` character into the `()` field to install Java support.
- Restart nvim: press `q` couple of times.

Quitting nvim:
- Press `<Space> q q`

# Getting started

- [LazyVim for Ambitious Developers](https://lazyvim-ambitious-devs.phillips.codes/) is an excellent crash-course,
  maybe read this first.
- Learning Vim Motions is probably a good thing: Vim is different to any other editor you used before.
  But using mouse + arrows is fine too.

Basic keyboard shortcuts:

- Press `<Space> s k` to search in all keymaps (akin to [Search in Actions](https://www.jetbrains.com/help/idea/searching-everywhere.html))
- Here are all [LazyVim Keymaps](https://www.lazyvim.org/keymaps) but let's skip that for now.
- Press `<Space>e` to open the file explorer (tree-like explorer accessible via `Alt+1` in IDEA)

# IDE Keymaps

Find/open class: in IDEA you either search everywhere, or press `Ctrl+N` to open class.
In LazyVim you can only search for all symbols (class, method names, fields) by typing
`<Space>sS` to "Search / LSP Workspace Symbols". [LSP (Language Server Processor)](https://microsoft.github.io/language-server-protocol/)
is a standard for integrating text editors with programming languages; `lang.java` plugin
is a LSP plugin.

Find/open symbols: `Ctrl+Alt+N` in IDEA, see above for LazyVim.

Find/open files: `<Space><Space>` or `<Space>ff`.

TODO more

