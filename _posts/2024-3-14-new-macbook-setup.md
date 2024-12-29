---
layout: post
title: New MacBook Setup
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes.

## Hardware

Ideal:

* [ANSI Keyboard](https://support.apple.com/en-us/102743#ANSI), since the tilde/backtick
  character is below ESC; the small Enter key is acceptable.
* 48 GB of RAM and 2 TB of disk space for VMs

Minimum:

* Make sure to buy MacBook with the [ISO International English](https://support.apple.com/en-us/102743#ISO) (kansainvälinen englanti):
  * It has big "Enter" key when compared to ANSI
  * Don't go for British English: it has GBP character in place of #
* At least 36 GB of RAM and 1 TB of disk space, because of VM

## During installation

Make sure to enable encryption: turn on FileVault during the installation, or afterwards. Also,

* Enable Location services, but only share the location with Home, Maps and Wallet.
* Disable Siri

## Initial setup

Then, make sure both the OS and the apps are up-to-date; turn on everything in Settings / General/ Software Update / Automatic Updates.

System Settings:

* Mouse:
  * turn off Natural scrolling
  * Tracking speed: 2nd fastest
* Trackpad:
  * Scroll & Zoom / Natural scrolling: turn off
  * Tap to click
  * Tracking speed: 4th fastest
* Accessibility / Pointer Control / Trackpad Options / Dragging style: Three-finger Drag
* Keyboard
  * Keyboard Shortcuts / Function keys / Enable "Use F1, F2, etc"
  * Text input / Edit... / All Input Sources:
    * Disable "Correct spelling automatically", "Capitalize words automatically", "Show inline predictive text" and "Add period with double-space"
* Control Center
  * Sound: always show in Menu Bar
  * Battery: Show Percentage
  * Spotlight: Don't Show
* [Enable Desktop & Document folder syncing over iCloud](https://support.apple.com/en-us/109344)
* Desktop & Dock:
  * "Dock" / Minimize windows using: "Scale effect"
  * "Dock" / "Position on screen": "Left"
  * "Desktop & Stage Manager" / Click wallpaper to reveal desktop: set to "Only in Stage Manager"
  * Hot Corners...: disable all hot corners
  * "Tiled windows have margins": turn off
* Battery / Options
  * "Prevent automatic sleeping on power adapter": on
  * "Optimize video streaming": off
* General
  * Storage: "Empty Trash Automatically": enable
* Lock screen
  * "Require password": "After 5 seconds"

Finder / Settings:

* General: Show "Hard disks"
  * Drag'n'drop the "Macintosh HD" from desktop to Finder favourites

Install from the App Store:

* Commander One
* UTM
* Libre Office
* Slack
* Magnet?
* BBEdit
* Infuse
* Magnet (to be able to move windows between monitors)

Install other software:
* Install Firefox from the [Firefox download page](https://www.mozilla.org/en-US/firefox/new/).
* Install [LinearMouse](https://linearmouse.app/) (also copy in my iCloud `Documents/sw/`)

### Mouse

To disable the idiotic accelerated mouse wheel scrolling
(which doesn't work at all in UTM and sucks in Parallels too),
download and run the LinearMouse app; then go to "Scrolling" and set:

* "Scrolling mode" to "By Lines"
* "Distance" to 3

Find more at [UTM #3417](https://github.com/utmapp/UTM/issues/3417).

## Commander One

Go into its Settings > Hotkeys:

* "Go to enclosing folder" : `⌫`
* "Compress file with options": `⌘P`
* "Extract file": `⌘U`
* "Equalize Panels": `⌘=`
* "Go to Home": ` (back tick)
* "Change drive in left panel": `⌘F1`
* "Change drive in right panel": `⌘F2`
* "Search": `⇧⌘F`

Settings / General / Edit Files With: select `BBEdit.app`

Then, enable "Show Hidden files".

## Parallels/UTM

See [Virtual Machines on MacBook](../virtual-machines-macbook/) for steps to setup Parallels/UTM.

## Fixing Keyboard Backtick/Tilde

The ISO English International keyboard has one huge disadvantage: the tilde/backtick key is located above "Option" ⌥ instead of below "Esc".
We'll fix that using [Ukelele](https://software.sil.org/ukelele/):

* Install [Ukelele](https://software.sil.org/ukelele/) and run it
* File / New from current input, and make sure the "English / ABC" keyboard is selected.
  This creates a keyboard bundle which may host multiple keyboards, but we'll only need one. The "ABC Copy" keyboard name is OK.
* Double-click on the +- key below ESC, and type in the backtick character.
* Press shift, then double-click on the +- key below ESC, and type in the tilde character.
* Save the bundle.
* Using Finder, copy the bundle to `/Library/Keyboard Layouts` (for all users), or `~/Library/Keyboard Layouts` (for current user only).

Reboot, and add the "ABC Copy" keyboard.

Uninstall Ukelele.

### Fixing Home/End/PgUp/PgDn keys

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

## Activity Monitor

* View / Dock Icon / Show CPU History
* Press `⌘3` to show CPU history window, `⌘4` to show GPU history
* Switch to "Memory" tab, to see the memory pressure chart.

## Global Keyboard Shortcuts

Open "Settings", "Keyboard", "Keyboard Shortcuts":

* "App Shortcuts" and add:
  * "Zoom" set to `⌘M` (aka Maximize). This kills Minimise but I'm not using that one anyways.
* Modifier Keys
  * `Caps Lock` as `^ Control`
    * This allows Magnet to have 

## Safari

* General
  * Safari opens with: All windows from last session
  * New window open with: Empty page
  * New tabs open with: Empty page
  * Homepage: blank
* Tabs:
  * Always show website titles in tabs
* Search:
  * Search engine: DuckDuckGo
* Advanced
  * Enable "Show full website address"
  * Default encoding: UTF-8
  * Enable "Show features for web developers"

## BBEdit

* "View / Window Appearance / Hide Sidebar"
* Settings
  * Menus & Shortcuts
    * Uncheck: #!, Subversion, Git, Scripts, Clippings

## Magnet

Enable "Synchronize settings via iCloud".

## More

If you want to go all crazy and completely unify Linux+Mac shorcuts, see
[Unifying Mac+Linux keyboard, or making Mac work like Linux](../unifying-mac-linux/).
