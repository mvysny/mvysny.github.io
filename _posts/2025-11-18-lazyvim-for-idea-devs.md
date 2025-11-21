---
layout: post
title: LazyVim for Intellij IDEA developers
---

[Intellij IDEA](https://www.jetbrains.com/idea/) is an excellent IDE with an
okay text editor that takes ages to start. [LazyVim](https://www.lazyvim.org/)
is an excellent/completely crazy editor (depends on your point of view) with an
interesting IDE capabilities and starts in milliseconds. I'll teach you the
LazyVim IDE when coming from IDEA so that you feel reasonably at home.

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
    You can now continue typing the shortcut slowly, while the popup shows the shortcut name.
- Here are all [LazyVim Keymaps](https://www.lazyvim.org/keymaps) but let's skip that for now.
- Type `<Space>e` to open the file explorer (tree-like explorer accessible via `Alt+1` in IDEA)

# IDE Keymaps

**Warning**: Most shortcuts only work when you're in Vim Normal mode!

To reopen your recent project, run nvim from anywhere (e.g. from Gnome by
pressing `Super` and typing `nvim<Enter>`), then press `<Space>qS` in LazyVim.
It will show the list of recent sessions (~= projects) and allow you to restore
a session.

## Navigation

Find/open class: in IDEA you either search everywhere, or press `Ctrl+n` to
open class. In LazyVim you can only search for all symbols (class, method
names, fields) by typing `<Space>sS` to "Search / LSP Workspace Symbols". Note
that this only works when LazyVim is able to load LSP for the currently opened
file. [LSP (Language Server
Processor)](https://microsoft.github.io/language-server-protocol/) is a
standard for integrating text editors with programming languages; `lang.java`
plugin is a LSP plugin for example.

> Note: Java plugin uses the Eclipse JDTLS (Java Language Server) which
> supports both Maven and Gradle projects (via Eclipse Buildship). You don't
> have to have Eclipse installed - the necessary bits will be downloaded
> automatically by the LazyVim plugin manager (Mason).

Find/open symbols: `Shift+Ctrl+Alt+n` in IDEA, see above for LazyVim.

Find/open files: `<Space><Space>` or `<Space>ff` in LazyVim, `Ctrl+Shift+n` in IDEA.

Find in files: `Ctrl+Shift+f` in IDEA, `<Space>/` in LazyVim.

Search in current file: `Ctrl+f` in IDEA. In LazyVim you can type in `/foo` to
search for "foo" then hit `n`/`N` to go to next/prev results. However, a faster
way is via `s` (Seek); beware that it only finds stuff visible on screen, not
in the entire file.

To cycle through errors and warnings you press `F2` in IDEA. In LazyVim you
press `[e`/`]e` for prev/next error (red text), `[w`/`]w` for prev/next warning
(yellow text), `[d`/`]d` for prev/next diagnostic (blue text). To find all
errors/warnings/diagnostics in your project, type `<space>sd` (current file
only: `<space>sD`). To find all TODOs in your project, type `<space>sT`. You
can try `<space>ca` to see possible fixes for errors and warnings.

Multi-cursor: Double-press `Ctrl` then arrow-down in IDEA. LazyVim doesn't have
support for multiple cursors yet, but you can record a macro in vim, then run
it multiple times.

Structural selection: `Ctrl+w` in IDEA, `Ctrl+Space` or `Shift+s` in LazyVim.

As you navigate around, you may want to go one step back in navigation history.
In LazyVim: `Ctrl+o`; go forward: `Ctrl+i`.

IDEA's "Go to declaration" `Ctrl+b` is implemented either by `gd` (Go to
Definition) or `gD` (Go to Declaration). Some LSPs may not implement both, for
example Ruby LSP gives me nothing for `gD`.

`Ctrl+b` in IDEA doubles as "Go to Usages", which is mapped in LazyVim to `gr` - Go to References.
Same functionality doubles as IDEA's "Show Usages" `Ctrl+Alt+F7`.

IDEA's "Go to Implementation" `Ctrl+Alt+b` is `gI` in LazyVim. IDEA's type
hierarchy doesn't seem to be implemented in LazyVim though.

IDEA's "File Structure" `Ctrl+F12` (I call it "Show Members") is replicated by
LazyVim's Show LSP Symbols `<Space>ss` - it shows symbols in current file only.

## Windows/Tabs

Quick documentation: `K` (`Shift+k`) in LazyVim (`Ctrl+q` in Intellij). It
shows a quick documentation (which can't be closed via ESC for some reason).
Pressing `K` again focuses inside of the quick doc popup and you can use arrows
to scroll; `q` quits and closes the popup.

Close tab: `<Space>bd`; close other tabs: `<Space>bo`; `[b` and `]b` (or
`Shift+h`/`Shift+l`) to switch between tabs; `<Space>backtick` to switch to the
previous recently edited tab.

Split window: `<Space>-` for horizontal split, `<Space>|` for vertical split.
Close window via `Space>wd`. Note that on the default theme (dark tokyonight)
the window separator is barely visible - look carefully to confirm that a new
window has indeed been opened.

Launch terminal: `Alt+F12` in IDEA, `Ctrl+/` in LazyVim. You can run e.g. tests
or documentation generator from the terminal.

Save file: `:w` or `Ctrl+s`. Save as: `:w newname.txt`. To disable automatic
formatting on save: press `<Space>fc` to edit LazyVim config files, open
`lua/config/options.lua` and add:

```
vim.b.autoformat = false
```

## Refactoring

Rename (`Shift+F6` in IDEA) is `<Space>cr` in LazyVim. You can rename
variables, functions, even classes: the java file gets renamed as well.

To generate getters, setters, `toString()`, override methods, organize imports,
press `<Space>ca`. This is the replacement for IDEA's "Generate"
(`Alt+Insert`).

Extract method and others are hidden behind the `<Space>cx` menu and only work for Java.

### Tips

`gc` comments out code but requires a motion. `gcc` comments out a line. An
excellent way is to pair it up with structural selection: type `gcS`, select a
label and a method is now commented out. Alternatively, press `Shift+v` to go
into line-selecting mode; when lines are selected type in `gc` to comment them
out.

Use `[c` and `]c` to go to prev/next class in the file; `[f` and `]f` to go to
prev/next function/method in the file.

Single `s` starts a search mode where you type in a bunch of characters then
press the "tag" character and LazyVim will take you there. This searches
on-screen (not in-file, so it's not really a file search), but it searches in
all open windows, allowing you to jump windows quickly. It might be handy when
debugging.

# git

In IDEA, I never used the Git window (`Alt+9`) and I rarely used the Commit
window (`Alt+0`), since using command-line git was easier and more
understandable for me (on Linux with good terminal of course - not on Windows).
I eventually picked up [LazyGit](https://github.com/jesseduffield/lazygit)
which is just brilliant: full-screen mode makes much more sense when working
with git, than the IDEA side-panels.

LazyVim has LazyGit baked in, just press `<Space>gg`. Awesome.

# Run/Debug

Handled via a DAP (Debugging Adapter Protocol) plugin: type in `:LazyExtras`
and install `dap.core`. Read
[Debugging](https://lazyvim-ambitious-devs.phillips.codes/course/chapter-17/)
first, to learn how debugging works in LazyVim.

When you install the DAP debug plugin, new options appear in LazyVim:

- "Run with Args" `<space>da` - discovers your main classes and allows you to
run them. You may need to provide a dummy cmdline parameters for this to work.
- "Run/Continue" `<space>dc` - same thing, but without the need to provide
cmdline parameters.

> Note: you need to install the `java-debug-adapter` plugin first, otherwise
> you'll get "Config references missing adapter `java`" when trying "Run with
> Args" `<space>da` or "Run/Continue" `<Space>dc`. You can do that by typing
> `:MasonInstall java-debug-adapter`.

Try "Run with Args" - the app should be running and you should see its stdout
in the lower-right part of LazyVim. You can click the window with your mouse
and type `i` then type something to interact with your app. `Ctrl+C` or
`<Space>dt` will kill the app.

## When nothing else works

As a fallback, run the app via the terminal: press `Ctrl+/` in LazyVim, then
run your app via Maven or Gradle.

## Tests

LazyVim has support for tests. Read [Chapter 18.
Testing](https://lazyvim-ambitious-devs.phillips.codes/course/chapter-18/) on
testing first. You'll need to install the `test.core` extra, then a couple of
goodies appear. Unfortunately, the keyboard shortcuts differ for Java and Ruby.

### Ruby

- `<Space>tt` runs current file as a test suite
- `<Space>tT` runs all tests
- `<Space>tw` - automatically run tests after a file is saved
- If there are failed tests: a Trouble window is open; use `[q` and `]q` to go
to prev/next error.

Only the RSpec tests (`spec/*_spec.rb`) are supported - Minitest tests in
`test/test_*.rb` are not picked up. Workaround is to write RSpec spec files,
but using Minitest-style asserts instead of RSpec expects:

```
RSpec.configure do |config|
  config.expect_with :minitest
end
```

### Java

The testing support is a bit more limited: it's not possible to run all tests
in all test classes:

- `<Space>tt` run all tests, but in the current test class only
- `<Space>tT` allows you to pick which tests to run 
- `<Space>tw` is supposed to rerun tests on any change, but it errors out
instead and doesn't seem to work
- `<Space>tr` runs the test method under the cursor.

Run all tests from the terminal: `Ctrl+/`

## Debugging

Debugging is pure madness. The shortcuts are really chatty, for example
`<Space>dO` to step over function call will get annoying pretty soon. To begin,
read [Chapter 17.
Debugging](https://lazyvim-ambitious-devs.phillips.codes/course/chapter-17/).

Unless the debugging is bound to F5-F8 like in IDEA, I wouldn't bother.

### Ruby

Debugging tests is just not possible. Running any rspec-related launch
configurations via `<Space>da` results in `Couldn't connect to 127.0.0.1:
ECONNREFUSED`. Adding `require 'debug/open'` as suggested in [debugging Ruby
with
Neovim](https://www.reddit.com/r/ruby/comments/1ctwtrd/debugging_ruby_in_neovim/)
just throws some Lua error.

Debugging Ruby scripts on the other side is possible, and works well.
`<Space>dC` runs to cursor, and other menu items from the `<Space>d` menu work
as well. Definitely promising. But the experience quickly gets annoying as you
battle with tedious shortcuts to step over the code.

### Java

Running main method in a Gradle project works - `<Space>da` offers to run the
Main class. However, the debugger won't stop at first line: you may need to add
a breakpoint to the first row via `<Space>db` otherwise the main method may
just complete.

Debugging tests is possible: add a breakpoint and run a test via `<Space>tr`
(run nearest test - under the cursor). However, the debugging experience is
horrible: the shortcuts are tedious to type, the "Thread" window doesn't
respond to clicks and won't navigate to Java sources. It's easy to get lost in
the debugging completely.

TODO maybe there are keyboard shortcuts to control the "Thread" window?

# Updating plugins

Type `<Space>l` or `:Lazy` to open the lazy.nvim plugin window, then press `S` (that's `Shift+s`) to update and sync all plugins.

# UI

UI-related stuff can be found at `<Space>u`; for example theme can be changed via `<Space>uC` and you can `<Space>ub` to
toggle between light and dark theme. `tokyonight` is the default theme.

To reopen notifications, type `<Space>n`.

# Help I'm Bloody Lost All The Time

Yes, going from a 'normal' text editor to a modal one like vim is challenging.
You need to give it a week at least, and slowly and painfully learn the new
keyboard shortcuts from scratch. At the end of the week, you'll know whether
Vim is for you or not.

I still am fighting with too-overly-helpful auto-completion. On the other hand,
LazyVim works on literally a 15 year old machine. Not just that - it works over
ssh, so you can run LazyVim *on your server* and edit stuff there if you need
to. Increasing font size is as easy as pressing `Ctrl+plus`. On the downside,
no mouse hover tips.

