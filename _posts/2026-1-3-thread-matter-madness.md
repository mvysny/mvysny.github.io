---
layout: post
title: Thread Matter Madness
---

The smart home world is moving from Zigbee to Matter/Thread. Is it a good thing,
when you use Apple Home and/or Home Assistant (or attempting to use both)? I have
a bunch of IKEA Zigbee devices, the Dirigera Hub, and I'm trying to understand
how the mesh works.

# Zigbee

All devices are ultimately connected to a hub (also called Coordinator). This forms a
single-point-of-failure: if it goes down,
all devices go down with it. In practice that rarely happens though.
Zigbee mesh also supports routing, e.g. IKEA TRETAKT plugs act as routers as well.
That means that you can use TRETAKT plugs to increase the coverage of your house.

Device OTA is questionable: IKEA has a great record of OTA but other vendors vary.

Visualizing: no idea. Possibly via Home Assistant, but with gotchas. If HA has a
Zigbee radio with devices connected to it, then it's apparently easy (never tried it myself though):
Go to Settings → Devices & Services → Integrations → ZHA → three dots (...) → Configure → Visualization tab.
However, if all devices are hooked to Dirigera, does it work? The recommended way to
connect from HA to Dirigera is by enabling Dirigera Matter Controller (possible
also with older Zigbee devices such as TRETAKT, they will be exposed by Dirigera) and then
adding Dirigera Hub to Home Assistant via Matter, via Matter setup code obtained from
the IKEA Home Smart app. However, I have no idea whether the visualization works
as well as with Zigbee.

## Easy To Understand

Zigbee is easy to understand: all devices connect to exactly one coordinator and
form a mesh automatically. If you need better coverage, add more router devices such as
IKEA bulbs or plugs.

To figure out which device is connected to which hub/coordinator, just examine the device
(either in Apple Home or in IKEA Home Smart App) and you'll learn the hub quickly.
That way, you can easily check how far the device is from the hub, and whether it would
benefit from additional router devices or not.

Adding a Zigbee IKEA device via IKEA App automatically adds it to Apple Home.
The only disadvantage is that you need IKEA Home Smart App to be installed on your phone.

However, adding Zigbee device from one manufacturer to other manufacturer Zigbee hub
can yield varying success - it may work or it may not work.

# Matter/Thread

Matter/Thread was designed to solve the device interop: any Matter+Thread device should
work with any Matter+Thread hub. Matter is a protocol allowing for the devices to speak to
controller; thread is the underlying network designed to connect Matter devices.
The communication goes as follows:
```
[Your Phone] → [Matter Controller] → [Thread Border Router] → [Thread Mesh] → [Matter-over-Thread Bulb]
```

Looks good on paper - you have a bunch of Thread Border Routers such as HomePod or Dirigera,
a bunch of thread routers such as IKEA light bulb, and a bunch of end devices like switches,
and Thread will make sure everything stays connected to the nearest border router or router, right?
Wrong.

## Fucking Complicated

You first need the Border Routers to all belong to the same Thread network (they share the same
thread credentials, or same Extended PAN ID which is a unique 64-bit hexadecimal value that all devices/border routers on the same mesh share).
What's completely ridiculous is that Apple Home doesn't show the Thread Network identifier in any shape
or form, so you have no fucking idea what it's supposed to look like and how to check whether
Dirigera finally joined the fucking thread network with Apple Home or not!

You see, by default, every
Border Router forms its own independent Thread network, including Dirigera. This
goes to ridiculous extremes: in my case, I enabled Matter
on Dirigera, integrated it with Apple Home (allowing me to control IKEA Zigbee devices from Apple Home),
and Dirigera still had its own Thread network - it shown some IKEA's own Thread network ID).
Which means that Matter devices hooked to Apple Home won't use Dirigera as the border router
even though it may be the closest one!

It gets even better: you add IKEA device straight to Apple Home, it doesn't show in IKEA app.
You add IKEA Matter device to IKEA app, it won't show in Apple Home unless you add it also
to Apple Home - so you need to add the device two times, both to IKEA and to Apple Home -
what the fuck? Wasn't Matter/Thread supposed to be an improvement over Zigbee?

This hilariously (probably - no fucking way of checking) finally forces Dirigera to join with Apple Home:
after I added IKEA Matter device to IKEA app first and then shared it from IKEA app
to Apple Home, DIRIGERA Thread network now shows MyHome982174339 or similar. I still have no
proof that Matter devices will now use both Dirigera and HomePod (whichever is closer)
as a border router, because it's not possible to confirm that they share one Thread network,
because **it's not fucking possible to visualize the god-damn thread network mesh!**

Dirigera joining Apple Home thread network is no simple process under the hood: you need IKEA app
to fetch Apple Thread credentials from iOS Keychain and use something called multi-admin
sharing which requires Thread 1.4+ which supports mesh merging... I'm sorry
in which fucking way is this simpler than Zigbee? I mean sure, it's a bunch of clicks in IKEA/Apple Home app,
and then you can't verify that the networks are joined anyway, fucking awesome.

I'm sorry but at this point I completely lost any interest in Matter/Thread. Too bad
this shit is the future now.

## No Way To Visualize

Of course Apple Home iPhone app doesn't show shit since it's dumbed down as much as possible; IKEA doesn't show
shit either and neither does "Eve for Matter & HomeKit". I was hoping
to hook Home Assistant into this madness to shed some light, but this is where things fall apart completely:
apparently you need to hook into Thread diagnostic mechanisms to obtain the thread routing tables
and to see how the mesh looks like, but you can't do that from ethernet (because of security) -
you need to connect to Thread via radio (that's how nRF Thread Topology Monitor does it).

On top of that, Home Assistant integration to Apple Home is limited:

- you can expose Home Assistant devices via HomeKit Bridge - but I have no HA devices
- You can try HomeKit Controller in attempt to control devices hooked to Apple Home, but
  that doesn't work because HomeKit accessories can only be paired to one controller at a time (this is an Apple HomeKit restriction).
- or, you enable something called "OpenThread Border Router" as HA Add-on, buy a Thread radio device,
  connect it to existing Apple Home Thread network (via HA Companion app which should be able to extract
  the Thread IDs), but this is just so fucking complicated and the outcome is so uncertain - fuck this shit.

## But Hey, At Least OTA Works!

True - if you add IKEA Matter device straight to Apple Home via Home iOS App, the OTA updates will work.

# Conclusion

To make sure your devices don't waste battery life by connecting to some remote router:

- on Matter, you either buy some radio thingy and fiddle with it, in hopes to see the mesh,
or you just pray that Dirigera somehow joins Apple Thread network and that hopefully enables
the devices to connect to the closer Border Router. But hope is not a strategy.
  - Alternatively you use Apple HomeKits as Border Routers only, expanding the mesh via Matter-enabled
    IKEA plugs/bulbs.
- Or you just get one Zigbee hub, a bunch of IKEA bulbs and plugs, and let the mesh form itself. Easy.

It gets even better: Zigbee routers don't talk to Thread routers (duh) so you can't
upgrade the mesh gradually. Brilliant!

