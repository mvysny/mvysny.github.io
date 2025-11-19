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
- Type in `/lang.java` to search for the Java plugin
- Enter the Insert mode by typing `i`, then type in `x` character into the `()` field to install Java support.
- Restart nvim: press `q` couple of times.

Quitting nvim:
- Press `<Space>qq` (that's Space followed by the two lower-case `q` letters)

# Getting started

- [LazyVim for Ambitious Developers](https://lazyvim-ambitious-devs.phillips.codes/) is an excellent crash-course,
  maybe read this first.
- Learning Vim Motions is probably a good thing: Vim is different to any other editor you used before.
  But using mouse + arrows is fine too for now.
  - [Baby Steps with Vim](https://www.barbarianmeetscoding.com/boost-your-coding-fu-with-vscode-and-vim/baby-steps-in-vim/) is
    a very good introduction to Vim - read this if you're hopelessly lost in Vim.
  - [Practical Vim](https://pragprog.com/titles/dnvim2/practical-vim-second-edition/) is for advanced Vim users, skip this for now.

Basic keyboard shortcuts:

- Press `<Space>sk` to search in all keymaps (akin to [Search in Actions](https://www.jetbrains.com/help/idea/searching-everywhere.html) via `Ctrl+Shift+a`)
  - If you press `<Space>` and wait, a popup with follow-up keyboard shortcuts will open - very nice.
- Here are all [LazyVim Keymaps](https://www.lazyvim.org/keymaps) but let's skip that for now.
- Type `<Space>e` to open the file explorer (tree-like explorer accessible via `Alt+1` in IDEA)

# IDE Keymaps

**Warning**: Most shortcuts only work when you're in Vim Normal mode!

To reopen your recent project, run nvim from anywhere (e.g. from Gnome by pressing `Super` and typing `nvim<Enter>`),
then press `<Space>qS` in LazyVim. It will show the list of recent sessions (~= projects) and allow you
to restore a session.

## Navigation

Find/open class: in IDEA you either search everywhere, or press `Ctrl+n` to open class.
In LazyVim you can only search for all symbols (class, method names, fields) by typing
`<Space>sS` to "Search / LSP Workspace Symbols". Note that this only works when LazyVim is able
to load LSP for the currently opened file. [LSP (Language Server Processor)](https://microsoft.github.io/language-server-protocol/)
is a standard for integrating text editors with programming languages; `lang.java` plugin
is a LSP plugin for example.

Find/open symbols: `Shift+Ctrl+Alt+n` in IDEA, see above for LazyVim.

Find/open files: `<Space><Space>` or `<Space>ff` in LazyVim, `Ctrl+Shift+n` in IDEA.

Find in files: `Ctrl+Shift+f` in IDEA, `<Space>/` in LazyVim.

Search in current file: `Ctrl+f` in IDEA. In LazyVim you can type in `/foo` to search for "foo" then hit `n`/`N`
to go to next/prev results. However, a faster way is via `s` (Seek); beware that it only finds stuff
visible on screen, not in the entire file.

To cycle through errors and warnings you press `F2` in IDEA. In LazyVim you press `[e`/`]e` for prev/next error (red text),
`[w`/`]w` for prev/next warning (yellow text), `[d`/`]d` for prev/next diagnostic (blue text).
To find all errors/warnings/diagnostics in your project, type `<space>sd` (current file only: `<space>sD`).
To find all TODOs in your project, type `<space>sT`. You can try `<space>ca` to see possible
fixes for errors and warnings.

Multi-cursor: Double-press `Ctrl` then arrow-down in IDEA. LazyVim doesn't have support for multiple cursors
yet, but you can record a macro in vim, then run it multiple times.

Structural selection: `Ctrl+w` in IDEA, `Ctrl+Space` in LazyVim.

As you navigate around, you may want to go one step back in navigation history. In LazyVim: `Ctrl+o`; go forward: `Ctrl+i`.

IDEA's "Go to declaration" `Ctrl+b` is implemented either by `gd` (Go to Definition) or `gD` (Go to Declaration).
Some LSPs may not implement both, for example Ruby LSP gives me nothing for `gD`.

`Ctrl+b` in IDEA doubles as "Go to Usages", which is mapped in LazyVim to `gr` - Go to References.
Same functionality doubles as IDEA's "Show Usages" `Ctrl+Alt+F7`.

IDEA's "Go to Implementation" `Ctrl+Alt+b` is `gI` in LazyVim. IDEA's type hierarchy doesn't seem to be implemented in LazyVim though.

IDEA's "File Structure" `Ctrl+F12` (I call it "Show Members") is replicated by LazyVim's Show LSP Symbols `<Space>ss` -
it shows symbols in current file only.

## Windows/Tabs

Quick documentation: `K` (`Shift+k`) in LazyVim (`Ctrl+q` in Intellij). It shows a quick documentation (which
can't be closed via ESC for some reason). Pressing `K` again focuses inside of the quick doc popup
and you can use arrows to scroll; `q` quits and closes the popup.

Close tab: `<Space>bd`; close other tabs: `<Space>bo`; `[b` and `]b` (or `Shift+h`/`Shift+l`) to switch between tabs;
`<Space>backtick` to switch to the previous recently edited tab.

Split window: `<Space>-` for horizontal split, `<Space>|` for vertical split. Close window via `Space>wd`.
Note that on the default theme (dark tokyonight) the window separator is barely visible - look carefully
to confirm that a new window has indeed been opened.

Launch terminal: `Alt+F12` in IDEA, `Ctrl+/` in LazyVim. You can run e.g. tests or documentation generator from the
terminal; I don't think LazyVim has support for running tests.

Save file: `:w` or `Ctrl+s`. Save as: `:w newname.txt`. To disable automatic formatting on save:
press `<Space>fc` to edit LazyVim config files, open `lua/config/options.lua` and add:
```
vim.b.autoformat = false
```

## Refactoring

Rename (`Shift+F6` in IDEA) is `<Space>cr` in LazyVim. You can rename variables, functions, even classes:
the java file gets renamed as well.

To generate getters, setters, `toString()`, override methods, organize imports, press `<Space>ca`.
This is the replacement for IDEA's "Generate" (`Alt+Insert`).

# git

In IDEA, I never used the Git window (`Alt+9`) and I rarely used the Commit window (`Alt+0`), since
using command-line git was easier and more understandable for me (on Linux with good terminal of course - not on Windows). I eventually picked up [LazyGit](https://github.com/jesseduffield/lazygit) which is
just brilliant: full-screen mode makes much more sense when working with git, than the IDEA side-panels.

LazyVim has LazyGit baked in, just press `<Space>gg`. Awesome.

# Debugging

Handled via a DAP (Debugging Adapter Protocol) plugin: type in `:LazyExtras` and install `dap.core`.
Read [Debugging](https://lazyvim-ambitious-devs.phillips.codes/course/chapter-17/) first, to learn how debugging works in LazyVim.

TODO more

# Updating plugins

Type `<Space>l` or `:Lazy` to open the lazy.nvim plugin window, then press `S` (that's `Shift+s`) to update and sync all plugins.

# UI

UI-related stuff can be found at `<Space>u`; for example theme can be changed via `<Space>uC` and you can `<Space>ub` to
toggle between light and dark theme. `tokyonight` is the default theme.

