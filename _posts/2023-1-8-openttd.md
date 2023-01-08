---
layout: post
title: OpenTTD (Transport Tycoon DeLuxe)
---

I love this old DOS/Windows game, and the brilliant [OpenTTD](https://www.openttd.org/) project
allows you to install and run the game easily, in any major OS. It bundles with
a new open music, graphics data and everything, in order for you to run and play the game.

Couple of tips below.

## Rails

Use the stations of length 5 as the bare minimum (10 carriages including the engine).
Remember that the best train engine in the game (Lev4 Chimaera Maglev) occupies two carriage slots, leaving
only 8 carriages for cargo.

[Electrified Rails](https://wiki.openttd.org/en/Manual/Base%20Set/Electrified%20railways) are only available
in the 'Temperate' map type, as per [List of Train engines](https://wiki.openttd.org/en/Manual/Trains#list-of-train-engines-and-carriages).
If you are a newbie, just start with the 'Temperate' map.

> Tip: You can mass-convert to electrified rails easily, by employing Universal Rail Type (below).

It is possible to remove just a part of a station, by using the 'Removal tool'.

### Mass-upgrading

You can mass-upgrade all your trains to a newer train engine easily, via 'All Trains' / 'Manage List' / 'Replace Vehicles'.

### Turn Radius

Turn radius: [Train Mechanics](https://wiki.openttd.org/en/Manual/Game%20Mechanics/#trains)
Try to use the curvature of at least 3. Slowing down longer Maglev from 640 km/h to 264 km/h is a pain to watch :-D
Ideally use curvature of 4 or 5 wagons in the curve.

### Semaphores

In the old TTD there were only block signals. In the newest OpenTTD they're gone and completely replaced
by path signals - that's excellent since they're much better. Read [Signals](https://wiki.openttd.org/en/Manual/Signals)
for the tutorial. Only use the path signals in the game, and use them as follows:

1. 1-rail paths and stations: use the 'Regular' path signal, facing towards the station/path. See "Basic two-way station" in the Signals tutorial.
2. Two-rail paths: use the "One-way path signal" only. Make sure to add a bit of offset after
   a crossing, so that trains are not stopped by the signal and blocking a crossing.
3. To see a visualisation how the trains are 'allocating rails', I highly recommend to enable the "highlight reserved tracks" or
   "show reserved tracks" setting, as shown in the Signals tutorial.
4. I never needed the "Pre-signals" and they're gone from the OpenTTD game anyway.

## Original Music

The new open-source music is awesome! However, if you're a huge fan of the original music,
you can listen to it as follows:

1. obtain the `GM.CAT` file from the DOS version of the game.
2. Copy it to `/usr/share/games/openttd/baseset/`
3. Run the game. The game should automatically activate the new music via the `orig_dos.obm` config file. If not, go to
   'Game Options' and change the 'Base Music Set'.

## Universal Rail Type

[Universal Rail Type](https://wiki.openttd.org/en/Community/NewGRF/Universal%20Rail%20Type)
drastically simplifies rail upgrade to monorail/maglev. You can enable the extension
straight from the game: go to NewGRF Settings, Check Online Content, search for "Universal Rail Type",
download it, and move it to the "Active NewGRF Types".

The conversion tool is able to convert the track to universal, regardless of whether there's a train on it or not.
Also converts depos.

To convert all the rails in the entire map at once to universal:

1. Select the 'convert to universal' tool, located in the 'universal rail' build railway menu.
2. Zoom out, to see the biggest part of the map.
3. Select the uppermost map rectangle.
4. Press and hold the left mouse-button. Press arrow keys to scroll the map, then move the cursor to the lowermost part of the map, then release the left mouse-button.
5. All rails and depos are now universal.

When the monorail locomotive is out, you can simply 'mass-upgrade' all trains to the newer train engine. Once all trains are upgraded,
you can convert all the rails in the entire map to the monorail rail type, using the 'convert to monorail' tool.

### After converting to monorail

The rail engine gets updated by the mass-upgrade, but the wagons will not! To use the new wagons with higher capacity,
you need to manually upgrade them for every train.

1. Send the train to depo
2. Drag the first wagon behind the rail engine to the second 'sell' button. That will sell all wagons.
3. Re-purchase the new monorail wagons.

## Hotkeys

Learn the [Hotkeys](https://wiki.openttd.org/en/Manual/Hotkeys), at least:

* `F1` for pausing. Gives you time to plan new rails; also `F4` map is vital for checking particular industry on a map.
* `A` for railroad building; Ctrl+Click removes tracks.
* `X` to turn transparent buildings on or off. Greatly helps when building rails.
* `L` for landscaping
* `6` for demolish
* `S` to build a signal, `B` to build a bridge, `9` to build a railway station.
* `Alt+Enter` for fullscreen

## Better Graphics

The default graphics pixelates heavily when zoomed in. You can try to search for a NewGRF named '32bpp', 'zbase' or 'abase'.
However, in OpenTTD 12.2 I can not seem to find the `zbase` or `abase` graphics, and I can't seem to pick a `32bpp` one.
Experiment.
