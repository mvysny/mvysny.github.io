---
layout: post
title: Extend WiFi range with multiple Access Points
---

Covering large area with a reliable WiFi signal may be tricky. The idea is to simply add more access points
to different parts of your house, essentially creating a network which together covers the entire house.
All of the APs (acronym for Access Point) share the same SSID; the client (your laptop or mobile phone)
then knows that it can connect to any of those APs to obtain the access to the internet. As you move
the device within your house, the device will eventually lose connection to the original AP and needs to reconnect
to a different AP. The promise here is that the device is free
to reconnect (this is called "Roaming") to any other AP without having to obtain a new IP or reconfigure its networking much - this way
the device can keep the TCP/IP connections open and continue communication. In order to keep this promise, all APs
must be connected to the same LAN network, sharing
the same netmask and gateway.

There are two ways to connect the access points together:

1. via a cable - the APs are connected to the LAN via a cable.
2. via radio - the APs communicate with each other via WiFi/radio signal, no cable required.

The disadvantage of 1 is obviously that you need the cables to connect the APs.
The disadvantage of 2 is that the APs themselves need to form the LAN network - there must be no AP isolated from all others.
Also, the communication between the APs will essentially double or triple the radio comms in your house as they relay comms
towards the router and back; this will also cause the APs to use part of its bandwidth just for this comms.
Therefore, I am sticking to physical wiring; you can read more about the option 2 in the
[WiFi Boosters, Repeaters and Extenders](https://www.waveform.com/pages/wifi-booster-repeater-extender-differences) article.

> Note: if having ethernet cables around the house is not an option for you, you can try
> ethernet-over-powerline. Simply google for "ethernet over powerline" for more details and
> for a list of devices to purchase; also read [Powerline networking may be what you need](https://www.digitaltrends.com/computing/everything-you-need-to-know-about-powerline-networking/).

I urge you to read the excellent [Multi-AP Roaming Network Background](https://superuser.com/a/122508/750976) which summarizes
this topic in excellent way.

Couple of tips from the article above:
* Use 5Ghz WiFi only, to avoid interference from bluetooth and your microwave oven
* If you have devices that only use 2,4Ghz band, make sure your APs do not interfere with each other, by configuring them to
  explicitly use channel 1, 6 and 11 (in case of three APs).
* Buy identical AP devices, or configure all APs to offer the same speed. If not, the client may prefer faster AP even though
  the signal is weaker, which could cause the client to reconnect between APs frequently with no obvious sense.

You need to search for WiFi routers which support configuring themselves in the AP mode; luckily
almost all of them do. Then, simply setup the router via a wizard and configure it to run in the AP
mode; then plug the ethernet cable into your main router and then into the WLAN socket of your AP. 

## Linux and The Network Manager

There are clients with generally good roaming algorithm (essentially all Android phones), and then there are
poorly engineered clients out there with poor roaming algorithms or thresholds,
and that is the [Network Manager](https://help.ubuntu.com/community/NetworkManager)
used by default by Ubuntu. Some clients with poor roaming algorithms tend to stick to one AP; Network Manager on the other
hand tends to reconnect between APs like crazy, for no obvious reason, causing the connections to drop frequently -
an infuriating experience.
You can find more at [How can I force Network Manager to associate to a specific access point?](https://askubuntu.com/questions/40038/how-can-i-force-network-manager-to-associate-to-a-specific-access-point).
So, if your Linux box drops connections like crazy, read on.

To confirm that the connection dropping is caused by Network Manager, open the terminal and run `dmesg -w`. If you see
an output like this frequently, then it's the Network Manager changing APs like crazy:

```
[ 3419.800554] wlp3s0: authenticate with xx:yy:zz:xx:yy:zz
[ 3419.811875] wlp3s0: send auth to xx:yy:zz:xx:yy:zz (try 1/3)
[ 3419.848189] wlp3s0: authenticated
[ 3419.851657] wlp3s0: associate with xx:yy:zz:xx:yy:zz (try 1/3)
[ 3419.959704] wlp3s0: associate with xx:yy:zz:xx:yy:zz (try 2/3)
[ 3420.023481] iwlwifi 0000:03:00.0: Unhandled alg: 0x3f0707
[ 3420.026283] wlp3s0: RX ReassocResp from xx:yy:zz:xx:yy:zz (capab=0x1411 status=0 aid=3)
[ 3420.037463] wlp3s0: associated
[ 4069.259671] wlp3s0: deauthenticating from xx:yy:zz:xx:yy:zz by local choice (Reason: 3=DEAUTH_LEAVING)
[ 4076.806725] wlp3s0: authenticate with aa:bb:cc:dd:ee:ff
[ 4076.815106] wlp3s0: send auth to aa:bb:cc:dd:ee:ff (try 1/3)
[ 4076.845155] wlp3s0: authenticated
[ 4076.851687] wlp3s0: associate with aa:bb:cc:dd:ee:ff (try 1/3)
[ 4076.862826] wlp3s0: RX AssocResp from aa:bb:cc:dd:ee:ff (capab=0x411 status=0 aid=1)
[ 4076.887382] wlp3s0: associated
[ 4076.992917] IPv6: ADDRCONF(NETDEV_CHANGE): wlp3s0: link becomes ready
```

For me, the Network Manager tends to switch to an AP with a much lower signal quality,
for absolutely no apparent reason. I consider this a glaring, ridiculous bug in the Network Manager.
There is an [old Ubuntu bug 111502: network-manager unreliable with multiple APs](https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/111502),
which is unfortunately closed as invalid; let me know if you find a newer bug report
(or please open a new one).

The solutions are outlined in the [How can I stop my wifi roaming?](https://ubuntuforums.org/showthread.php?t=1437212)
thread:
1. Don't use multiple APs (haha too late I suppose :)
2. Use `wicd` - unfortunately I can't find wicd packages for Ubuntu 21.04.
3. Force Network Manager to stay with one AP. This is the best workaround I could find so far.
4. All of the above plus open a bug report and complain loudly.

In order to use the last workaround, simply follow the [How do I ban a wifi network in Network Manager?](https://askubuntu.com/questions/11990/how-do-i-ban-a-wifi-network-in-network-manager) -
open the WiFi connection properties in Network Manager, go to Identity > BSSID and input the MAC address
of the AP you want to stay connected to. The MAC address is in the form of `aa:bb:cc:dd:ee:ff`. Finding the MAC address
is easy - it's present in the dmesg log above, but you can also run `sudo iwlist wlp3s0 scan`
to see all available APs, then pick the one with the highest quality. Also read
[How to list all available WIFI access points with Linux.](https://securitronlinux.com/debian-testing/how-to-list-all-available-wifi-access-points-with-linux/)
for more details.

> Note: the `wlp3s0` is a wifi network interface name on my system; use the `iwconfig` command
> to discover the network interface name on your system.

The Network Manager won't use the new settings automatically, you'll need to
disable and enable wifi on your system, or reboot your machine, or connect to another wifi and back, or similar.
In my case, Network Manager actually creates a new WiFi configuration setting with the same name (facepalm)
but with the BSSID being fixed. When you start running around your house with your device, remember to
switch to the other WiFi profile, otherwise your machine will stay fixated on one AP, eventually
losing connection and rendering the whole multi-AP solution useless.
