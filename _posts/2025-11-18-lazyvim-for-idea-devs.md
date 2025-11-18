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
- Press `<Space>qq` (that's Space followed by the two lower-case `q` letters)

# Getting started

- [LazyVim for Ambitious Developers](https://lazyvim-ambitious-devs.phillips.codes/) is an excellent crash-course,
  maybe read this first.
- Learning Vim Motions is probably a good thing: Vim is different to any other editor you used before.
  But using mouse + arrows is fine too.

Basic keyboard shortcuts:

- Press `<Space>sk` to search in all keymaps (akin to [Search in Actions](https://www.jetbrains.com/help/idea/searching-everywhere.html) via `Ctrl+Shift+A`)
- Here are all [LazyVim Keymaps](https://www.lazyvim.org/keymaps) but let's skip that for now.
- Type `<Space>e` to open the file explorer (tree-like explorer accessible via `Alt+1` in IDEA)

# IDE Keymaps

Find/open class: in IDEA you either search everywhere, or press `Ctrl+N` to open class.
In LazyVim you can only search for all symbols (class, method names, fields) by typing
`<Space>sS` to "Search / LSP Workspace Symbols". Note that this only works when LazyVim is able
to load LSP for the currently opened file. [LSP (Language Server Processor)](https://microsoft.github.io/language-server-protocol/)
is a standard for integrating text editors with programming languages; `lang.java` plugin
is a LSP plugin for example.

Find/open symbols: `Shift+Ctrl+Alt+N` in IDEA, see above for LazyVim.

Find/open files: `<Space><Space>` or `<Space>ff` in LazyVim, `Ctrl+Shift+N` in IDEA.

Quick documentation: `K` in LazyVim (`Ctrl+Q` in Intellij). It shows a quick documentation (which
can't be closed via ESC for some reason). Pressing `K` again focuses inside of the quick doc popup
and you can use arrows to scroll; `q` quits and closes the popup.

TODO more

## git

In IDEA, I never used the Git window (`Alt+9`) and I rarely used the Commit window (`Alt+0`), since
using command-line git was easier and more understandable for me (at least on Linux - Windows is a fucking nightmare
and its terminal is a sick joke). I eventually picked up [LazyGit](https://github.com/jesseduffield/lazygit) which is
just brilliant: full-screen mode makes much more sense when working with git, than the IDEA side-panels.

LazyVim has LazyGit baked in, just press `<Space>gg`. Awesome.

