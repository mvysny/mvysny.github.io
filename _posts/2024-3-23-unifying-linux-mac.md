---
layout: post
title: Unifying Linux+Mac keyboard, or making Linux work like Mac
---

I'm working with Linux in VM/Parallels on a daily basis, and it's impossible for me to constantly switch
between two very different layouts. Therefore, I've decided to try and modify Linux to work as much as MacOS.

What doesn't work:

* It's not possible to have one key combo for moving cursor one word left/right:
  * ⌥← and ⌥→ go one word prev/next doesn't work in Linux: `SuperL + Left` and `SuperL + Right` is hijacked by Gnome shell and can not be remapped.
  * trying to reconfigure `^\UF702` (Control+Left) in `DefaultKeyBinding.dict` doesn't do anything.

EXPLORATORY STATE: WORK IN PROGRESS

## MacBook

### Function keys

Ideal scenario would be:

* In MacOS: The F1-F12 keys would be in the "special feature mode" (e.g. pressing F8 acts as play/pause, and you need to press Fn to achieve F8)
* In the VM: F1-F12 keys would act as F1-F12 without you having to press the "Fn" button.

Unfortunately this ideal scenario can not be achieved since MacOS intercepts certain keys, making them unavailable for the VM:

* F1-F4 are intercepted and can not be remapped. You would need to press the "Fn" key along with F1-F4 and we want to avoid the "Fn" key.
* F5-F12 can be remapped, but with limitations. For example, ⌥Option+F12 always opens the sound settings in MacOS as well; F11 and F12 always also
  increase/decrease volume on MacOS.

Therefore, the only way is to go to "System settings", "Keyboard", "Keyboard Shortcuts", "Function Keys"
and enable the "Use F1, F2, etc. keys as standard function keys".

### Arrow Keys/Home/End/PgUp/PgDn

See [Mac-like cursor control in Linux 22.04/Parallels 19](../mac-like-cursor-control-in-linux/).

## Linux Ubuntu 22.04 in Parallels

I tend to remap the keyboard so that ⌥Option acts as Meta/Super in Linux, and ⌘Command acts like Alt in Linux,
so that `Alt+Tab` and Alt+BackTick in Linux is activated by pressing ⌘Tab and/or ⌘` respectively, and acts
exactly the same as in MacOS.

### Fix Ctrl/Super/Alt buttons

Install Input-Remapper:
```bash
sudo apt install input-remapper-daemon input-remapper-gtk
```

Run Remapper, then create a new preset named "ctrl+cmd-switched" and map:
(it will take some time for you to understand the logic of the Remapper UI; don't worry you'll get there).

* `Alt L` to `Super_L`
* `Super L` to `Control_L`
* `Control L` to `Alt_L`

This basically makes Linux `Alt` be activated by pressing `^Control`, `Meta/Super` to be activated by pressing
`⌥Option` and pressing `⌘` works as `Control`. This sounds crazy until you realize that this basically makes
`⌘C` copy, `⌘V` paste, `⌘S` save, even `⌘,` to go into preferences in gnome-text-editor! Let's keep this.

Make sure "Autoload" is on (this way the setting will be activated automatically when you log in). Press the "Apply" button -
the remapping should now be active.

#### Other modifications?

TODO go through Firefox and gnome-text-editor and check that they feel intuitive to MacOS user.

### Fix app switching and other global key shortcuts

To mimic Alt+Tab going through apps (and not windows), open the "Settings" / "Keyboard" / "View and customize Shortcuts" / "Navigation"
and set "Switch Applications" to "Alt+Tab" and "Switch Windows" to "Super+Tab" (or remove the shortcut entirely).

Also go to "Windows" and set "Close Window" to "Alt+Q".

### Intellij IDEA

Unfortunately the "macOS" keymap can not be used since it doesn't work at all in Linux:
the ⌘Command key is activated by Meta key but it's not getting through to Intellij - basically
IDEA never sees any key combination with Meta in it, which effectively disables all essential shortcuts.
On top of that, since I have ⌘Command mapped to Alt and not Meta in Linux, all Meta-based
shortcuts in IDEA would need to be activated by pressing the ⌥Option physical key, which completely messes up
the shortcuts.

I think we need to completely rewrite the "macOS" keymap and modify all shortcuts from Meta to Alt... TODO Explore more
