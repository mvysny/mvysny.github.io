---
layout: post
title: Apple Rant
---

The way Apple is sold, it's like the second coming of Jesus, yet it's riddled with
bugs which would make Linux feel embarrassed.

Disclaimer: I'm still using MacOS despite its shortcomings. This is just for me to
vent, and maybe you'll agree with some of this stuff. I know Linux has many shortcomings, but
this vent made me realize that Linux did many things right,
and Apple should copy those things.

Disclaimer 2: I'm coming from Linux, and I'm NOT a Windows guy by any means.
Personally I think that [Windows is a bloated spyware](../windows/),
unsuitable for anything but games.

# MacOS

## UX

There are so many UX issues with MacOS it's not even funny. Sometimes the bug is so basic, it feels like a kid school project instead of
a serious OS.

When I quit VM in Parallels or close Slack, there's like 5% probability that those apps crash & freeze, and with that, the entire fucking macOS UI - da fuq?
This points to a huge fundamental flaw of the underlying system design: everything in MacOS goes through one event loop, and if an app freezes, the event loop blocks, and with it, every other app.
This is Mac only - this doesn't happen on Windows nor on Linux. For entertainment, [check out this video](https://youtu.be/tZueJx-ndnI?si=9mEZGv1rOjZspC-b&t=961).
I thought, as a profession, we moved away from the MS-DOS times, where an app could overwrite entire memory and pretty much kill your PC.
The only thing that works is to right-click the app icon and select "Kill" - the option doesn't show by default and feels like the kill switch is hacked on top of MacOS Dock bar.

Opening an unresponsive page in Safari freezes not just Safari, but the entire operating system -
I thought the times of cooperative multitasking were behind us. This is just unacceptable and feels
like a project from a first-grader.

### Window Resizing Sucks

The "Window > Move & Resize" menu.
It's great when it works, but it doesn't work on BBEdit, and that's because BBEdit removes the "Move & Resize"
menu item from the "Window" menu. It's true that BBEdit should not do that, but BBEdit
shouldn't be allowed to do that in the first place! Also, when I press the key combo to tile windows to left,
I want The Mighty Window Manager to tile the bloody window to the left, end of story. It shouldn't be the responsibility
of the app itself to capture the shortcut, then maybe moving its window to the left (or not). What the fuck? The Window Manager needs to handle that, not the app itself!

On top of that, there are two maximize functions now: `Zoom` and `Fill`. `Zoom` has no keyboard shortcut assigned and
for some apps it maximizes the app only vertically, but not horizontally, which is useless for me: I use apps that take advantage of all screen real estate.
`Fill` is `⌃🌐F` and doesn't work anyway on some apps:

* On Slack it does nothing and BBEdit it does nothing
* On Safari it does nothing if a web page is open, with an input field focused.
* UTM window is made too tall and falls out of the screen - what the fuck

So, again: `Zoom` is useless and `Fill` works half of the time. I have to use the `Magnet` app. Again, feels like kids school project instead of something professional.

### All Apple Window Managers Suck

There are three window managers, and all of them are terrible. The Stage Manager is - I have no fucking idea how I am supposed to use that.
As a programmer, I want my apps occupying the entire screen, otherwise I just wasted my money on a big monitor and I could have gone with the smaller one.
Stage Manager just wastes a bit of screen for the folded windows which is just a horrible idea: you can't see the window contents nor icons nor titles, so it's just wasted space.

The Mission Control is based on the idea that you can identify a window from its thumbnail.
Let me tell you a secret: all windows are black text on white background, and they all look the same, except for very specific cases, say there is a video playing, or you're editing a photo.
The only way to differentiate between them is the icon and the title.
But I guess if you arrange the windows by some order (e.g. the order in which I opened them, or maybe if I can rearrange them)
then it could work. Which brings me to the next point: Mission Control always rearranges the windows randomly, which makes it completely useless.

So, the Dock + Alt+Tab. Works well, [as long as you don't have many windows](https://youtu.be/tZueJx-ndnI?si=vtHqlK3fCGyZqyGU&t=320),
or if [you're not using more than two monitors](https://www.youtube.com/watch?v=cxNaz3G66_I).
Which brings me to the conclusion: Mac Window Managers are either bad, or they only work with handful
of windows only. Luckily, this works for me since I'm using UTM most of the time,
but it just feels retarded that Apple, the king of UX, can't come up with a usable Window Manager.

### Random other UX issues

Macbook's "Now playing" control center icon is broken by design. It tries to be too helpful
and includes both Apple Music and Safari; when I hit the "Pause" button in hopes to stop Apple Music playback,
it instead activates the Teams Safari tab and starts playing the "ringing call" sound.
What the fuck? Who at Apple thought this to be a good idea?
[Sure, instead of pausing the music, let's hear a random sound from random Safari tab instead!](https://discussions.apple.com/thread/255881132?sortBy=rank).

Apple Music is confusing as hell - I don't really care for Home, New or Radio: I just want to mark a bunch of stuff favourite and listen
to those. Opening a favourite artist only shows favourite albums, leading me to believe that other albums are
not on Apple Music. I need to click on the artist name *again* (it shows as plain text, giving no impression that it's a clickable element!!), to see all albums.
Apple, please fucking fire all Apple Music UX designers and design that shit from scratch.

## Keyboard Rant

The tilde key. With Linux, it doesn't matter what symbol is on the keyboard key;
you can activate the US layout which puts the tilde character under ESC, regardless of what the physical button on the keyboard reads.
Not with Apple. If you don't get the Mac with the US physical layout, the tilde key is moved downwards next to the left shift,
and no matter which keyboard layout I select in the settings, I can not remap the key elsewhere. I actually had to download
some [crazy software](https://software.sil.org/ukelele/) written by some third-party dude, to create my own keyboard layout,
only to move the Tilde key to where I'm used to. WTF? Sure, get a Mac with the US keyboard you might say,
but in the US layout, the ENTER key occupies only one row of keys and that annoys me to no end.
AARGH I'll have to get used to the small ENTER key since the tilde position is pretty much hardwired
in my brain already.

Shortcuts in MacOS make zero sense. There are 4 modifier keys (Cmd/Option/Control/Fn!!!)
and none of those act as a global "system" modifier for invoking system-wide action
(like the "Win" key does in Windows or Linux).
Or, rather, all of them do. `⌃` is generally treated as such (as a kind of system key),
but also the `🌐` (Fn) key is treated as such, e.g. `🌐E` shows the emoji keyboard. On top of that,
screen capture is a clusterfuck of wild key combinations that make zero sense.
Take `⇧⌘4` as an example, to capture part of the screen:

- Doesn't use `⌃` nor `Fn` even though those keys are supposed to be "system-wide"
- The `4` key is completely arbitrary and makes no sense
- Always captures a rectangular screenshot: say if you want a video capture, tough luck - you need to remember another crazy keyboard combo.
- No UI option to copy the screenshot to clipboard instead of saving to desktop - you need to press `⌃⇧⌘4` (dafuk???) for that
- Why is suddenly `⌃` involved when `⌥` would make more sense for this - since we're slightly modifying the behavior of screen capture?
- `⇧⌘4SpaceBar` captures current window - Why `SpaceBar`??? Also, Apple, have you realized it's not easy to press 4 keys at the same time when 2 of them are non-modifiers?

In Linux/Gnome, this is solved in a much better way:
- Press PrintScreen
- A dialog appears where you select what you want to do - e.g. capture the entire screen, or just part of the screen, or a video.
- The screenshot is stored into `~/Pictures/Screenshots` and also into clipboard.
- Okay okay, you can press `⇧⌘5` to get the same window - noted.

Solution which covers all of my needs:
- Map "Screenshot and recording options" to `F13` - this opens the screenshot dialog where I can select everything I need;
- Map "Copy picture of selected area to the clipboard" to `⌥F13`
- Map "Save picture of selected area as a file" to `⌘F13`
- (When I'm away from the numpad): `⌘Space` then type "Screenshot"

I know there are historic reasons since `🌐` was added later on, but still.

### Home/End move the viewport, not the cursor

No. Just no. I edit text and move the cursor first and foremost; I'm not paid me to scroll shit around.

## Other Stuff

The programming environment on MacBook sucks balls. In order to install stuff, you need to
install HomeBrew: *you download a bash script from the internet and run it as root*. **NO FUCKING WAY**.
[Linux-in-VM saves the day](../ubuntu-in-parallels/).

MTP (transfer files to Android devices) support is [virtually non-existent](../copying-files-apple-android/) - another huge WTF.

# iOS

The way iOS does app settings is a complete UX disaster too: in order to configure the app,
I have to go to Settings, find the app and set it up. WHY? I was in the fucking app in the first place but okay I guess!

The iPhone on-screen keyboard: it is so broken it's not even funny. The autocorrection sucks for anything else than English, the
UX for correcting autocorrection is horrible and I find myself fighting the UX to correct
the autocorrection suggestions; most importantly, the support for auto-switching between
three languages is non-existent which is a huge deal-breaker for anyone that needs to type in more than one language.
Apple, please take a hard long look at Google's keyboard,
and then copy it.

# Conclusion

I mean, many things are done in the right way, but there are some huge gaping bloody obvious usability issues,
Jobs must be rotating in his grave like a turbine.

Will I abandon Apple? No. They do many things right, most importantly the privacy.
Also, once the Magic Keyboard is remapped, it's extremely pleasant to type on.
The touchpad is amazing too. Now that I got things working the way I want it, the setup is pretty solid.
Also, the working suspend and the entire don't-shut-off-computer-for-a-year is highly addictive too.
I'm pretty happy with my Linux-in-VM setup - Linux provides excellent programming environment,
Apple provides excellent hardware and a thin OS on top of that, and I even get to play games on a Windows-in-VM.
I love the M3 Max - finally ARM replaced the x86 garbage. The whole MacBook hardware is amazing - the
quietness, the CPU efficiency, excellent sound quality, possibility to use iPad as second screen - brilliant.

Also, the Apple Cloud, Photos, Reminders, Notes, Passwords and the way it's synced across iPads, TVs and iPhones,
it's a tiny miracle - love it.
