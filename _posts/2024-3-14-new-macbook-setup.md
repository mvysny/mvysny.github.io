---
layout: post
title: Ubuntu in Parallels Apple Silicon
---

I need to setup new machine from time to time, and I always forget all the things that need to be set up.
So, here it goes.

## Hardware

Make sure to buy MacBook with the [ISO International English](https://support.apple.com/en-us/102743#ISO) (kansainvälinen englanti):

* It has big "Enter" key when compared to ANSI
* Don't go for British English: it has GBP character in place of #
* At least 36 GB of RAM and 1 TB of disk space, because of VM

## Initial setup

Make sure to enable encryption: turn on FileVault during the installation, or afterwards.

System Settings:

* Mouse: turn off Natural scrolling
* Trackpad / Scroll & Zoom / Natural scrolling: turn off

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

## Commander One

Go into its settings > Hotkeys:

* "Open file": add a secondary key ⌘→
* "Go to enclosing folder" : ⌘←

## Parallels

In Parallels Desktop Settings:

* Shortcuts / macOS System Shortcuts / Send macOS system shortcuts: Always.
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

The ISO keyboard has one huge disadvantage: the tilde/backtick key is located above "Option" instead of below "Esc".
We'll fix that using [Ukelele](https://software.sil.org/ukelele/):

* Install [Ukelele](https://software.sil.org/ukelele/) and run it
* File / New from current input, and make sure the "English / ABC" keyboard is selected.
  This creates a keyboard bundle which may host multiple keyboards, but we'll only need one. The "ABC Copy" keyboard name is OK.
* Double-click on the +- key below ESC, and type in the backtick character.
* Press shift, then double-click on the +- key below ESC, and type in the tilde character.
* Save the bundle.
* Using Finder, copy the bundle to `/Library/Keyboard Layouts`

Reboot, and add the ABC Copy keyboard.

Uninstall Ukelele.

## Activity Monitor

* View / Dock Icon / Show CPU Usage (need to re-check this after reboot)
* Press ⌘3 to show CPU history window, ⌘4 to show GPU history
* Switch to "Memory" tab, to see the memory pressure chart.
