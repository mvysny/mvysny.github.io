---
layout: post
title: Dual-Pane Commander setup
---

I never got used to the Explorer/Nautilus way of managing files -
I'm simply a dual-pane commander guy. I used [Krusader](https://krusader.org/) at first,
then I switched to [Double Commander](https://doublecmd.sourceforge.io/) (since it was more light-weight),
and now I'm back to Krusader.

## Preparation/KDE integration with GNOME

Install `qgnomeplatform-qt5` to enable proper window borders around doublecmd/krusader. Then, edit
`/etc/environment` and add `QT_QPA_PLATFORMTHEME='gnome'`. The borders will be applied after reboot.

## Krusader

Install: `sudo apt install krusader`. Don't omit recommended dependencies otherwise fish (ssh)
support and icons will be missing. Then, open configuration:

- Panel
  - General > Navigator bar: check "Edit Mode by default"
  - View > View font: Ubuntu, 11
  - Buttons > Check "Equal", uncheck "Up" and "Root" buttons
- Colors
  - Uncheck "Use the default KDE colors"
  - Folder foreground: Dark Blue
  - Executable foreground: Dark Green
  - Symbolic link fg: Dark Cyan
  - Invalid symlink: Dark Red
  - Current background: Light Gray
- General
  - General > Terminal: `gnome-terminal`
  - Viewer/Editor > Editor: `gnome-text-editor -n`

Configure Keyboard Shortcuts:

- Rename: `F9`
- Term: `F2`
- Multi-rename: `Shift-F9`

Sort by extension.

## Double Commander

`sudo apt install doublecmd-qt`

*Note:* install `doublecmd-qt` rather than `doublecmd-gtk` since [GTK version doesn't support wayland](https://github.com/doublecmd/doublecmd/issues/927).

Go to Configuration:

* Colors / File Panels / Text Color: black
* Colors / File types:
  * category name: `executable`, mask: `*`, attributes: `-*x*`, color: `Green`
  * `dir`, `*`, `d*`, `Navy`
  * `symlink`, `*`, `l*`, `Teal`
* Files views / Files views extra / Show system and hidden files
* Folder tabs / "Show tab header also when there is only one tab" - uncheck
* Fonts:
  * Main Font: Ubuntu 11 Regular
  * Viewer font: Ubuntu Mono 13
* Icons / File panel: 16x16
* Keys: "Ctrl+Alt+Letters": None
* Keys / Hot Keys:
  * cm_RunTerm: `F2`
  * cm_PackFiles: `Alt+P` (or `⌘P` when in Mac mode)
  * cm_ExtractFiles: `Alt+U` (or `⌘U` when in Mac mode)
  * cm_TargetEqualSource: `Alt+=` (or `⌘=` when in Mac mode)
  * cm_ChangeDirToHome: ` (grave accent)
  * cm_RenameOnly: `F9`
  * cm_Search: `Shift+Alt+F`
* Tools / Editor:
  * Use External Program;
  * executable: `gnome-text-editor`
  * additional parameters: `-n`

Sort by extension.

