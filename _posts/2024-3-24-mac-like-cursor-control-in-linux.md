---
layout: post
title: Mac-like cursor control in Linux 22.04/Parallels 19
---

I'm working with Linux in VM/Parallels on a daily basis, and it's impossible for me to constantly switch
between two very different layouts. Therefore, I've decided to try and modify Linux to work as much as MacOS.

We'll keep the MacOS logic and won't really use the Home/End/PgUp/PgDown physical buttons
(since they're only on the extended Magic Keyboard anyway, and not on laptop keyboards). Instead, we'll
implement the following cursor controlling scheme:

* ⌘↑ and ⌘↓ go to the beginning/end of the document
* ⌘← and ⌘→ go to the beginning/end of the line
* ⌥← and ⌥→ go one word prev/next
* ⌥↑ and ⌥↓ go one page up/down

Unfortunately, things aren't 100% smooth - read on.

## Linux Ubuntu 22.04 in Parallels

I tend to remap the keyboard so that `⌥Option` acts as `Meta/Super/Win` in Linux, and `⌘Command` acts like `Alt` in Linux,
so that `Alt+Tab` and `Alt+BackTick` in Linux is activated by pressing `⌘Tab` and/or ⌘` respectively, and acts
exactly the same as in MacOS.

First, install `gnome-tweaks` via apt, and make sure the ⌥Option button works as Meta, and the ⌘Command button
works as Alt: run Tweaks, then "Keyboard & Mouse", "Additional Layout Options", "Alt and Win behavior" and select
"Alt is swapped with Win". Remapper will stack its modifications on top of these ones - these mappings won't fight each other.
But you must log out after you change Tweaks settings, otherwise Remapper will receive strange keyboard shortcuts.
So, logout and login.

## Remapper 2

We need Remapper 2 in order for these advanced key combinations to work. For example, `Super_L + Right` (`⌘→`) would map to `KEY_END`.
The problem is that Remapper 1 (which comes with Ubuntu 22.04) keeps `Super_L` pressed, which effectively maps to `Super_L`+`KEY_END`, which does nothing.

The easiest way is to upgrade Ubuntu to 23.10, simply by running `sudo do-release-upgrade` on the command-line.
However, that's not the best idea since Parallels 19 is not entirely compatible with kernel 6.5.0
and dmesg shows terrifying crashes:

```
- UBSAN: array-index-out-of-bounds in /var/lib/dkms/parallels-tools/19.3.0.54924/build/prl_fs/SharedFolders/Guest/Linux/prl_fs/file.c:244:15
    - [   28.390410] index 1 is out of range for type 'char [1]'
```

Therefore, we'll keep Ubuntu 22.04 and install Remapper 2 into it.

### Installation

Go to [Input Remapper Releases page](https://github.com/sezanzeb/input-remapper/releases) and download the `input-remapper-2.0.1.deb`.
Then, install via `sudo apt install -f ./input-remapper-2.0.1.deb` - this will install the app including all dependencies.

Run the remapper from terminal via `input-remapper-gtk`. The remapper will ask for root password - this is okay.

### Configuration

It will take some time for you to understand the logic of the Remapper UI; don't worry you'll get there.
Just click "Parallels Virtual Keyboard", "new preset" and register the following shortcuts:

* `Alt L + Right` maps to `End`  (this also handles selection with Shift)
* `Alt L + Left` maps to `Home`
* `Alt L + Up` maps to `Control_L + Home`
* `Alt L + Down` maps to `Control_L + End`
* `Control L + Up` maps to `Prior`
* `Control L + Down` maps to `Next`

Make sure "Autoload" is on (this way the setting will be activated automatically when you log in). Press the "Apply" button -
the remapping should now be active.

Unfortunately it's not possible to use the same physical keys for ⌥-based shortcuts:

* `⌥←` and `⌥→` doesn't work in Linux: `SuperL + Left` and `SuperL + Right` is hijacked by Gnome shell and can not be remapped.
* trying to reconfigure `^\UF702` (Control+Left) in `DefaultKeyBinding.dict` doesn't do anything - MacOS
  apparently captures `^Control`+arrows for window switching purposes

So, you'll have to press the `^Control` key instead of `⌥Option` key in Linux. This is the disadvantage of
the `Ctrl`/`Win`/`Alt` setting.

## MacOS implementation of pageup/pagedown

We'll modify the logic of the `⌥↑` and `⌥↓` in MacOS, so that they don't use the vague concept of paragraph but act as `PgUp` and `PgDn`.

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

Unfortunately it's not possible to reconfigure `^←`/`^→` to make cursor skip words: trying to reconfigure
`^\UF702` (Control+Left) in `DefaultKeyBinding.dict` doesn't do anything.

## IDEA

NOTE: only do this if you want to stick to the XWin or Gnome keyboard layout in IDEA. However, I recommend
to switch to MacOS layout and update it accordingly. In the MacOS layout, "Back"/"Forward" is mapped to
`⌘[` and `⌘]`, respectively. But the follow-up text is a good read on how the mapping craziness work.

The `⌘←` shortcut will disable the "Navigation/Back" button which is mapped to Ctrl+Alt+Left. The easiest way
is to redefine "Navigation/Back" to `^<` and "Navigation/Forward" to `^Shift<`.

Even better you can make CapsLock+Left to perform the same functionality.
In your Mac, you can redefine "Caps Lock" to act as "⌘Command" button, in "Settings" / "Keyboard" / "Modifier Keys".
Pressing "Caps Lock" now performs the same thing as if the *right* ⌘Command was pressed. Then:

* In the VM, this acts as if the R_Super was pressed.
* R_Super is replaced by R_Alt by Gnome Tweaks
* The `Alt L + Left` Remapper rule is not triggered since it only targets left alt
* Therefore, the Alt+Left IDEA shortcut is triggered, which performs the "Navigate/Back"

The *right* part is very important: if it would emit the left ⌘Command then it would be captured by
Remapper.

Now all that's left to do is to add Alt+Left to "Navigation/Back" in IDEA.

## Huge change: mapping `⌘Command` to `Ctrl`

To further replicate Mac's keyboard you may wish for `⌘Command` to act as `Ctrl` key. This would have numerous advantages:

* `⌘C`, `⌘V`, `⌘Z` would start behaving exactly as in Mac;
* In Firefox, `⌘T` would open a new tab while `⌘W` would close the current one.

Let's split this into two cases:

* `⌥Option` continues acting as `Super_L`, which makes `^Control` act as `Alt`. That means that `^Control`/`⌥Option`/`⌘Command` maps to `Alt`/`Win`/`Ctrl`
* `⌥Option` changes to `Alt_L`, which makes `^Control` act as `Super_L`. That means that `^Control`/`⌥Option`/`⌘Command` maps to `Win`/`Alt`/`Ctrl`

### `Alt`/`Win`/`Ctrl`

There is no way to swap modifier keys this way in Gnome Tweaks (believe me I tried, but be my guest and try it out for yourself: I'd be happy to be proven wrong).
Therefore, we'll remap everything in the Remapper. Make sure to turn off Alt+Win swapping in Tweaks
(select "Alt and Win behavior" to "Disabled") then *log out* otherwise the setting will stay in effect and you'll
get very strange behavior in the Remapper. Then, fire up Remapper:

* `Control_L` as `Alt_L`
* `Alt_L` as `Super_L`
* `Super_L` as `Control_L`
* `Super_L + Right` as `End`

Hit Apply and test it out in a text editor by pressing `⌘→`. The cursor, instead of moving to the end of the line,
moves to the end of the document! The reason is that two rules got activated in Remapper: both
`Super_L` as `Control_L`, and `Super_L + Right` as `End`, causing the resulting key combination to be
`Ctrl+End` which indeed scrolls to the end of the document. I wonder whether this could be fixed in
Remapper - TODO go through [Remapper Issues](https://github.com/sezanzeb/input-remapper/issues) and try to figure it out.

In other words, it is currently fundamentally impossible to use Remapper both for modifier key changes and for
key combination definition. Therefore, let's switch back to the tried&trusted combo of Tweaks handling modifier key changes,
while Remapper handling key combo mappings.

### `Win`/`Alt`/`Ctrl`

Sounds like remapping both individual modifiers and the key combos is not the right way to go -
a better way is a two-level system where modifiers are remapped in Gnome Tweaks and key-combos further on in the Remapper.
Let's try it out. Open Gnome Tweaks and activate "Additional Layout Options" / "Ctrl position" / "Swap Left Win with Left Ctrl".
LOG OUT and log in again - this is very important otherwise Remapper will output strange key combinations.
Then, add the following mappings to the Remapper:

* `Alt_L + Down` to `Next`
* `Alt_L + Left` to `Control_L + Left`
* `Alt_L + Right` to `Control_L + Right`
* `Alt_L + Up` to `Prior`
* `Control_L + Down` to `Control_L + End`
* `Control_L + Left` to `Home`
* `Control_L + Right` to `End`
* `Control_L + Up` to `Control_L + Home`

And it works! Now the cursor movement mapping is identical to Apple.

Don't forget to go into "Gnome Settings", "Keyboard", "Keyboard Shortcuts", "Navigation"
and modify "Switch Applications" to `Ctrl+Tab` and "Switch windows of an app" to `Ctrl+backtick`.
Also "Windows" / "Close window" set to `Ctrl+Q`.

EDIT: there are strange artifacts and this solution doesn't work 100%: press `↓` two times, then `⌘↓` -
the current line gets selected instead! You need to press `⌘↓` multiple times for it to take effect.
But this only occurs in IDEA for some reason... maybe it's some kind of Remapper+Java+XWayland incompatibility.
It's not that bad.
