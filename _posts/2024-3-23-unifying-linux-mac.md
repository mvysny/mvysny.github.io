---
layout: post
title: Unifying Linux+Mac keyboard, or making Linux work like Mac
---

I'm working with Linux in VM/Parallels on a daily basis, and it's impossible for me to constantly switch
between two very different layouts. Therefore, I've decided to try and modify Linux to work as much as MacOS.

Status: it works, and it works surprisingly well:

* The cursor keys works exactly as in MacOS
* The app shortcuts are now remarkably close to MacOS
* IDEA keymap is almost identical to the typical MacOS layout employed by all other "native" MacBook apps
* You no longer need the "Numeric Keypad" part of your Magic Keyboard - the notebook keyboard is exactly as usable in this setup.

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

See [Mac-like cursor control in Linux 22.04/Parallels 19](../mac-like-cursor-control-in-linux/) (only the MacOS part for now)
and re-configure the pgup/pgdown keys.

## Linux Ubuntu 22.04 in Parallels

Go back to [Mac-like cursor control in Linux 22.04/Parallels 19](../mac-like-cursor-control-in-linux/) and configure Linux according to the
`Win`/`Alt`/`Ctrl` scenario. Yup - we're going to completely remap the keyboard, making `⌘Command` work as `Ctrl`.
It sounds completely crazy but it has additional advantages:

* `⌘C`, `⌘V`, `⌘Z` would start behaving exactly as in Mac;
* In Firefox, `⌘T` would open a new tab while `⌘W` would close the current one.
* `⌘,` goes into preferences in gnome-text-editor! Let's keep this.

### IDEA

Of course IDEA's keyboard mapping is now completely broken down. I recommend to switch to the MacOS
layout, but that one is also completely malfunctional since it expects `⌘Command` to act as `Meta` (but we mapped it to `Ctrl`).
No worries - the `Meta` key would not work anyways since Gnome filters out all Meta-based shortcuts.

The way is to go through all keybindings and alter them:

* Replace all `Meta` with `Ctrl`
* Fix all caret movements in Editor Actions - you'll have to go through all of them and press the key combination,
  in order for IDEA to "forget" their non-Apple keyboard mappings and learn the Apple mappings.
* All non-caret arrowkey-based shortcuts will stop working and you'll have to find a replacement. Read on.

#### Further tips

* Find -> `Ctrl+F`
* Replace -> `Ctrl+R`
* Find Next / Move to Next Occurrence -> `Ctrl+G` (this one will only activate when in Find/Replace mode, so it won't clash with the "Add Selection for Next Occurrence" below)
* Find Previous / Move to Previous Occurrence -> `Ctrl+Shift+G`
* Select All Occurrences -> `Ctrl+Alt+G`
* Add Selection for Next Occurrence -> `Ctrl+G` (won't conflict with "Find Next" since this is only used when outside of the Find/Replace mode)
* Unselect Occurrence -> `Ctrl+Shift+G`
* Terminal -> `Ctrl+F12` or just `F12`
* Tool windows (e.g. Project) -> Remap them to `Ctrl+1` and mercilessly remove the existing bookmark-related shortcuts.

#### Fixing ArrowKey-based shortcuts

To fix the arrowkey-based shortcuts (such as "Extend/Shrink selection", "Next/Previous Highlighted Usage" and "Clone Caret Above/Below"),
you can use the `⇪CapsLock` remapping trick. In MacOS settings, remap `⇪CapsLock` to `^Control` and it will map to `Ctrl_R` in the Linux VM.
You can now add the following shortcuts:

* "Extend/Shrink selection" to `Ctrl+Up`/`Ctrl+Down` (by pressing `⇪↑` - you'll have to remember to press `⇪↑` to activate this shortcut)
* "Next Highlighted Usage" to `F3` (okay here I'll just copy from what I'm used to - XWin :-D ) and "Previous Highlighted Usage" to `Shift+F3`
* "Clone Caret Above" to `Ctrl+PgUp` (achieved by pressing `⇪⌥↑`) and "Clone Caret Below" to `Ctrl+PgDn` (press `⇪⌥↓`)
