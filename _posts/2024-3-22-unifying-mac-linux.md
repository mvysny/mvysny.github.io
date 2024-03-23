---
layout: post
title: Unifying Mac+Linux keyboard, or making Mac work like Linux
---

The general advice is to bite the bullet and learn Mac keyboard shortcuts. That doesn't help in my case though:
I'm working with Linux in VM/Parallels on a daily basis, and it's impossible for me to constantly switch
between two very different layouts. Therefore, I've decided to try and modify Mac to work as much as Linux.
That means that, for example, Ctrl+Q closes app (and not ⌘Q), Ctrl+Home moves the cursor to the top. I've also avoided installing
all third-party apps on Mac, and only using [Input Remapper](https://github.com/sezanzeb/input-remapper)
which is available in official Ubuntu repository for both Ubuntu 22.04 and 24.04, so this method
is future-proof.

WARNING: WORK IN PROGRESS. There are still outstanding issues, for example:

* Mac: App switching now works via ^Tab instead of ⌘Tab
* Mac: Whenever learning a new keyboard shortcut: You have to mentally juggle the fact that ⌘ is now the rightmost-bottom key.
* Linux: App switching now works via Ctrl+Tab instead of Alt+Tab

## MacBook

### Function keys

Ideal scenario would be:

* In MacOS: The F1-F12 keys would be in the "special feature mode" (e.g. pressing F8 acts as play/pause, and you need to press Fn to achieve F8)
* In the VM: F1-F12 keys would act as F1-F12 without you having to press the "Fn" button.

Unfortunately this ideal scenario can not be achieved since MacOS intercepts certain keys, making them unavailable for the VM:

* F1-F4 are intercepted and can not be remapped. You would need to press the "Fn" key along with F1-F4 and we want to avoid the "Fn" key.
* F5-F12 can be remapped, but with limitations. For example, Option+F12 always opens the sound settings in MacOS as well; F11 and F12 always also
  increase/decrease volume on MacOS.

Therefore, the only way is to go to "System settings", "Keyboard", "Keyboard Shortcuts", "Function Keys"
and enable the "Use F1, F2, etc. keys as standard function keys".

### Reverting ^ and ⌘

Go to "System settings", "Keyboard", "Keyboard Shortcuts", "Modifier Keys", and configure

* "Control ^ key" to work as: ⌘ Command
* "Command (⌘) key" to work as: ^ Control

Also go to:
* "Keyboard" and change "Move focus to next window" to ⌘` (Remember to press Ctrl to get ⌘ :-).
* "Spotlight" and change "Show Spotlight Search" to ^Space

### Fixing Home/End/PgUp/PgDn keys

Create the file `~/Library/KeyBindings/DefaultKeyBinding.dict` with the following content:
```
{
    "@$\UF702" = moveWordBackwardAndModifySelection:;  // ctrl+left arrow
    "@$\UF703" = moveWordForwardAndModifySelection:;  // ctrl+right arrow
    "@\UF702" = moveWordBackward:;  // ctrl+left arrow - doesn't work for some reason?
    "@\UF703" = moveWordForward:;  // ctrl+right arrow - doesn't work for some reason?
    "\UF729"  = moveToBeginningOfLine:; // home
    "\UF72B"  = moveToEndOfLine:; // end
    "@\UF729"  = moveToBeginningOfDocument:; // ctrl+home
    "@\UF72B"  = moveToEndOfDocument:; // ctrl+end
    "@$\UF729"  = moveToBeginningOfDocumentAndModifySelection:; // ctrl+shift+home
    "@$\UF72B"  = moveToEndOfDocumentAndModifySelection:; // ctrl+shift+end
    "$\UF729" = moveToBeginningOfLineAndModifySelection:; // shift-home
    "$\UF72B" = moveToEndOfLineAndModifySelection:; // shift-end
    "\UF72C"  = (moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:); // page up - move up 30 lines.
    "\UF72D"  = (moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:); // page down - move down 30 lines.
    "$\UF72C"  = (moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:); // shift+page up - move up 30 lines.
    "$\UF72D"  = (moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:); // page down - shift+move down 30 lines.
}
```
You'll need to restart individual apps for them to pick up the new configuration.

Links:
* List of keyboard key codes: [osx keybinding](http://xahlee.info/kbd/osx_keybinding_key_syntax.html)
* [Supported commands](https://developer.apple.com/documentation/appkit/nsstandardkeybindingresponding)
* [Tips for DefaultKeyBinding.dict](https://apple.stackexchange.com/questions/127023/how-do-i-know-what-to-put-in-defaultkeybinding-dict)

## Parallels

Go to "Parallels Desktop", "Preferences, "Shortcuts", "Application Shortcuts" and turn off everything except for the last one, "Release Focus".

Then, go below to "Virtual Machines", click one of the machine, then select the "Linux" profile
and make sure all ⌘X, ⌘C etc keyboard mappings are turned off.
For IDEA: Add ^Backspace mapped to Ctrl+Insert.

## Linux Ubuntu 22.04 in Parallels

### Fix Ctrl/Super/Alt buttons

Install Input-Remapper:
```bash
sudo apt install input-remapper-daemon input-remapper-gtk
```
Run Remapper, then create a new preset named "ctrl+cmd-switched" and map:

* `Super L` to `Control_L`
* `Alt L` to `Super_L`
* `Control L` to `Alt_L`

(it will take some time for you to understand the logic of the UI; don't worry you'll get there).

Make sure "Autoload" is on (this way the setting will be activated automatically when you log in). Press the "Apply" button -
the remapping should now be active.

### Fix app switching

Alt+Tab won't work unfortunately, and it can't even be assigned to a shortcut: the combo simply appears completely dead.
We'll therefore map app switching to Ctrl+Tab. Go to "Settings", "Keyboard", "Keyboard Shortcuts", "View and customize",
"Navigation" and set:

* "Switch Windows" to "Ctrl+Tab".
* "Switch Windows of an application" to Ctrl+` (backtick)
