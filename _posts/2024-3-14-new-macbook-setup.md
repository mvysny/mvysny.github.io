---
layout: post
title: New MacBook Setup
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes.

## Hardware

Make sure to buy MacBook with the [ISO International English](https://support.apple.com/en-us/102743#ISO) (kansainvälinen englanti):

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

* Mouse: turn off Natural scrolling
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
* Battery / Options
  * "Prevent automatic sleeping on power adapter": on
  * "Wake for network access": "Never"
  * "Optimize video streaming": off
* General
  * Storage: "Empty Trash Automatically": enable
* Lock screen
  * "Require password": "After 5 seconds"

Finder / Settings:

* General: Show "Hard disks"
  * Drag'n'drop the "Macintosh HD" from desktop to Finder favourites

Install from the App Store:

* Parallels (+activate)
  * Note that when installing Parallels from App Store (so-called Parallels Desktop App Store version),
    it's not possible to install guest MacOS. But I don't really mind.
  * Alternative download of [Parallels Desktop 18 for Mac](https://www.parallels.com/products/desktop/download/).
* Commander One
* UTM
* Libre Office
* Slack

Install Firefox from the Firefox download page.

### Mouse

To disable the idiotic accelerated mouse wheel scrolling (which doesn't work at all in UTM and sucks in Parallels too),
download and run the [LinearMouse](https://linearmouse.app/) app; then go to "Scrolling" and set:

* "Scrolling mode" to "By Lines"
* "Distance" to 3

Find more at [UTM #3417](https://github.com/utmapp/UTM/issues/3417).

## Commander One

Go into its settings > Hotkeys:

* "Go to enclosing folder" : `Backspace`
* "Compress file with options": `⌘P`
* "Extract file": `⌘U`
* "Equalize Panels": `⌘=`
* "Go to Home": ` (back tick)
* "Change drive in left panel": `⌘F1`
* "Change drive in right panel": `⌘F2`
* "Search": `⇧⌘F`

Then, enable "Show all files".

## Parallels

In Parallels Desktop Settings:

* Shortcuts
  * macOS System Shortcuts / Send macOS system shortcuts: Always.
    * This not only enables Alt+Tab to work properly in your VM, but also enables Ctrl+Left/Right arrow to
      properly skip words in IDEA.
  * To stop Parallels interfering with IDEA shortcuts, go to Application Shortcuts and disable shortcuts for:
    * Preferences
    * Toggle Coherence
    * Toggle Full Screen
    * Toggle Modality
* Devices: set to 'Connect it to my Mac' to stop interfering with common work

Additional keyboard shortcuts I [found for Parallels but work for UTM too](https://forum.parallels.com/threads/keyboard-shortcut-for-home-end.208263/):

* Home = `Fn+ArrowLeft`
* End = `Fn+ArrowRight`
* PgUp = `Fn+ArrowUp`
* PgDown = `Fn+ArrowDown`
* Delete = `Fn+Backspace`
* Insert - couldn't find any Fn combination for this. Press `I` to insert in vim.

Even better: get the [Magic keyboard with Numeric Keypad](https://www.apple.com/shop/product/MMMR3B/A/magic-keyboard-with-touch-id-and-numeric-keypad-for-mac-models-with-apple-silicon-british-english-black-keys);
don't forget the "International English ISO" layout.

To make sure that Alt+Insert works with IDEA: go to Parallels Desktop Preferences / Shortcuts / Virtual machines, select any linux box
to edit the "Linux profile" and add the following mapping:

* Cmd+Backspace -> Win+Insert (remember that we swapped Win with Alt in Gnome).

### Linux VM settings

* Options
  * Sharing: disable everything except "Share custom Mac folders". Then Manage Folders
    and select one specific folder to share.
* Hardware
  * CPU & Memory: Advanced and check "Adaptive Hypervisor"
  * Mouse & Keyboard: Don't optimize for games
  * Shared printers: turn off
  * Sound & Camera: disable everything

## Fixing Keyboard Backtick/Tilde

The ISO English International keyboard has one huge disadvantage: the tilde/backtick key is located above "Option" ⌥ instead of below "Esc".
We'll fix that using [Ukelele](https://software.sil.org/ukelele/):

* Install [Ukelele](https://software.sil.org/ukelele/) and run it
* File / New from current input, and make sure the "English / ABC" keyboard is selected.
  This creates a keyboard bundle which may host multiple keyboards, but we'll only need one. The "ABC Copy" keyboard name is OK.
* Double-click on the +- key below ESC, and type in the backtick character.
* Press shift, then double-click on the +- key below ESC, and type in the tilde character.
* Save the bundle.
* Using Finder, copy the bundle to `/Library/Keyboard Layouts`

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
* Press ⌘3 to show CPU history window, ⌘4 to show GPU history
* Switch to "Memory" tab, to see the memory pressure chart.

## Global Keyboard Shortcuts

Open "Settings", "Keyboard", "Keyboard Shortcuts":

* "App Shortcuts" and add:
  * "Show Help menu" set to `⌥⌘/` (can't use `⇧⌘/` since some apps launch help with `⌘?`)
  * "Zoom" set to `⌘M` (aka Maximize). This kills Minimise but I'm not using that one anyways.
* Modifier Keys
  * `Caps Lock` as `^ Control`

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

## More

If you want to go all crazy and completely unify Linux+Mac shorcuts, see
[Unifying Mac+Linux keyboard, or making Mac work like Linux](../unifying-mac-linux/).
