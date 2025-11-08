---
layout: post
title: Ubuntu with netplan and no NetworkManager
---

To disable NetworkManager and control your network configuration from command-line only, even
on Ubuntu Desktop, use [netplan](https://netplan.io/), edit files in `/etc/netplan/`
and change the `renderer` from `NetworkManager` to `networkd`.

## Wifi

[Using netplan with ubuntu](https://linuxconfig.org/ubuntu-20-04-connect-to-wifi-from-command-line)
works for me well: when configured properly, Raspberry PI will automatically connect
to wifi on boot and you can simply ssh to it.

I have the following file `/etc/netplan/00-wifi.yaml`:

```yaml
network:
  wifis:
    wlan0:
      dhcp4: true
      optional: true
      access-points:
        "<YOUR_AP_NAME>":
          password: "<YOUR_AP_PASSWORD>"
  version: 2
  renderer: networkd
```

Make sure you have the `netplan.io` package installed. Then, run `sudo netplan --debug apply`
and your wifi should be up - you can verify that by running `ifconfig -a`.

## Ethernet

This is an example of a fixed-IP configuration: the machine will have the IP of `192.168.1.222`
on a network with netmask `255.255.255.0`, with gateway of `192.168.1.1` and two DNS
servers, `8.8.8.8` and `8.8.4.4` (the Google ones):

```yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      addresses: [192.168.1.222/24]
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]
      routes:
        - to: default
          via: 192.168.1.1
```

Again, run `sudo netplan --debug apply` and verify that by running `ifconfig -a`.

Origin: [Example with netplan fixed IP address](https://linuxconfig.org/how-to-configure-static-ip-address-on-ubuntu-18-04-bionic-beaver-linux):

## Checking The Stack

To check whether the DNS work, try running `host -v google.com`. Verify your network stack with
```bash
$ resolvectl status
```

More info/fixes at [Linux DNS](../linux-dns/).
