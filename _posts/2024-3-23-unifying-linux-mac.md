---
layout: post
title: Unifying Linux+Mac keyboard, or making Linux work like Mac
---

I'm working with Linux in VM/Parallels on a daily basis, and it's impossible for me to constantly switch
between two very different layouts. Therefore, I've decided to try and modify Linux to work as much as MacOS.

EXPLORATORY STATE: WORK IN PROGRESS

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

### Arrow Keys/Home/End/PgUp/PgDn

We'll keep the MacOS logic and won't really use the Home/End/PgUp/PgDown physical buttons (since they're on the extended Magic Keyboard anyway):

* ⌘↑ and ⌘↓ go to the beginning/end of the document
* ⌘← and ⌘→ go to the beginning/end of the line
* ⌥← and ⌥→ go one word prev/next

We'll modify the logic of the ⌥↑ and ⌥↓ though, so that they don't use the vague concept of paragraph but act as PgUp and PgDn.

Create the file `~/Library/KeyBindings/DefaultKeyBinding.dict` with the following content:
```
{
    // Option+uparrow moves 30 lines up, emulating pgup
    "~\UF700"  = (moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:, moveUp:);
    // Option+downarrow moves 30 lines down, emulating pgdown
    "~\UF701"  = (moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:,moveDown:); // page down - move down 30 lines.
    // The same, but with selection
    "~$\UF700"  = (moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:,moveUpAndModifySelection:);
    "~$\UF701"  = (moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:,moveDownAndModifySelection:);
}
```
You'll need to restart individual apps for them to pick up the new configuration.

Links:
* List of keyboard key codes: [osx keybinding](http://xahlee.info/kbd/osx_keybinding_key_syntax.html)
* [Supported commands](https://developer.apple.com/documentation/appkit/nsstandardkeybindingresponding)
* [Tips for DefaultKeyBinding.dict](https://apple.stackexchange.com/questions/127023/how-do-i-know-what-to-put-in-defaultkeybinding-dict)

## Linux Ubuntu 22.04 in Parallels

### Fix Ctrl/Super/Alt buttons

Install Input-Remapper:
```bash
sudo apt install input-remapper-daemon input-remapper-gtk
```
Run Remapper, then create a new preset named "ctrl+cmd-switched" and map:

* `Alt L` to `Super_L`
* `Super L` to `Alt_L`

(it will take some time for you to understand the logic of the UI; don't worry you'll get there).

Make sure "Autoload" is on (this way the setting will be activated automatically when you log in). Press the "Apply" button -
the remapping should now be active.

#### Cursor movement

TODO we're screwed. On Ubuntu 22.04, this doesn't work in Remapper: `Super_L + Right` (`⌘→`) would map to `KEY_END`.
The problem is that Remapper keeps `Super_L` pressed, which effectively maps to `Super_L`+`KEY_END`, which does nothing.

TODO test on Ubuntu 24.04

### Fix app switching

To mimic Alt+Tab going through apps (and not windows), open the "Settings" / "Keyboard" / "View and customize Shortcuts" / "Navigation"
and set "Switch Applications" to "Alt+Tab" and "Switch Windows" to "Super+Tab" (or remove the shortcut entirely).

### Intellij IDEA

Unfortunately the "macOS" keymap can not be used since it doesn't work at all in Linux:
the ⌘Command key is activated by Meta key but it's not getting through to Intellij - basically
IDEA never sees any key combination with Meta in it, which effectively disables all essential shortcuts.
On top of that, I tend to remap the keyboard so that ⌥Option acts as Meta/Super in Linux, and ⌘Command acts like Alt in Linux,
so that `Alt+Tab` and Alt+BackTick in Linux is activated by pressing ⌘Tab and/or ⌘` respectively, and acts
exactly the same.

TODO Explore more


TODO TODO




That means that, for example, Ctrl+Q closes app (and not ⌘Q), Ctrl+Home moves the cursor to the top. I've also avoided installing
all third-party apps on Mac, and only using [Input Remapper](https://github.com/sezanzeb/input-remapper)
which is available in official Ubuntu repository for both Ubuntu 22.04 and 24.04, so this method
is future-proof.

WARNING: WORK IN PROGRESS. There are still outstanding issues, for example:

* Mac: App switching now works via ^Tab instead of ⌘Tab
* Mac: Whenever learning a new keyboard shortcut: You have to mentally juggle the fact that ⌘ is now the rightmost-bottom key.
* Linux: App switching now works via Ctrl+Tab instead of Alt+Tab
* Mac: Home/End stops scrolling the viewport (e.g. the page in Safari)

### Reverting ^ and ⌘

Go to "System settings", "Keyboard", "Keyboard Shortcuts", "Modifier Keys", and configure

* "Control ^ key" to work as: ⌘ Command
* "Command (⌘) key" to work as: ^ Control

Also go to:
* "Keyboard" and change "Move focus to next window" to ⌘` (Remember to press Ctrl to get ⌘ :-).
* "Spotlight" and change "Show Spotlight Search" to ^Space

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
