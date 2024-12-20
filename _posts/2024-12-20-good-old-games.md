---
layout: post
title: Good Old Games
---

I love the Good Old Games - they weren't designed to hook you to the screen,
induce addiction and make you spend money on virtual axes. You bought the game
once, and you enjoyed it, no subscriptions needed; it was also easy to play.
The graphics wasn't that advanced (that's good - no perception overload) but they're highly
entertaining still. The emulators for C64, Amiga 500 and DOS may not be easy
to set up on Linux, so I added this manual. All the emulators below support ARM64 as well.

You can get the old games for example from the [myabandonware.com](https://www.myabandonware.com).

## C64

Commodore 64 was insanely popular back in the 80's. To have it running on your Linux,
run
```
$ sudo apt install vice
```
Then you need the machine ROM which you can purchase or download from the internet
if you search for e.g. "Commodore 64 romset". Then, create a folder
in your home folder named `~/.local/share/vice/C64/` and make sure it has contents like the following:
```
basic-901226-01.bin    chargen-906143-02.bin  kernal-390852-01.bin  kernal-901227-02.bin  kernal-901246-01.bin
chargen-901225-01.bin  kernal-251104-04.bin   kernal-901227-01.bin  kernal-901227-03.bin  kernal-906145-02.bin
```
Now you can run the emulator:
```
$ x64sc
```
The emulator will start in C64 mode by default.

The games are usually available as `.d64` Floppy Disk images which you can mount
to the diskette drive "8" via Vice's UI. Then, type in `LOAD "*",8,1` and enjoy the game!

## Amiga 500

You can get the emulator by installing
```
$ sudo apt install fs-uae
```
Run it once:
```
$ fs-uae
```
It will create the directories in `~/Documents/FS-UAE`; you need to place ROMs into
`~/Documents/FS-UAE/Kickstarts/`, they will be named such as:
```
kick100.rom  kick110.rom  kick120.rom  kick130.rom  Kick13.rom  kick204.rom  kick310.rom
```
The games are available as `.adf` floppy disk images which you pass in via command line:
```bash
$ fs-uae --floppy-drive-0=Lemmings.adf
```
The game is started right away. If not, press `F12` and select the image in the floppy drive.
See the [FS-UAE getting started](https://fs-uae.net/docs/getting-started) on how to add multiple floppies.

## DOSBOX

DOSBOX is a DOS emulator. It already comes with a Free DOS preinstalled, so no need to
download ROMs. Simply run DOSBOX:
```bash
$ dosbox -fullscreen -scaler super2xsai
```
This will start DOSBOX in full screen and capture the mouse so that it can be used by the games.
You can select a different [DOSBOX scaler](https://www.dosbox.com/wiki/Scaler).
To run the game, mount the directory where the game is:
```
mount c ~/games
c:
cd lemmings
lemmings
```
