---
layout: post
title: Ubuntu VPN via Mullvad
---

I want to avoid installing custom binaries provided by the VPN providers.
I usually tend to use the VPN provider which either uses
wireguard or openvpn:

- wireguard is included in Linux kernel already and it only needs a bunch of client tools to set up
- openvpn is baked in NetworkManager already

I'm quite happy with mullvad.net. Create an account at [Mullvad.net](https://mullvad.net/en/account) and get one month for 5 EUR,
no strings attached.

## wireguard

Run `sudo apt install wireguard` to install client-side wireguard tools. Then, go to your Mullvad account,
select "WireGuard configuration", "Linux", "generate  key", select a country and then download
the file which will be named `something.conf`. Copy the file to `/etc/wireguard/`, then
run:

```bash
$ wg-quick up ./something.conf
```

If wireguard fails with `/usr/bin/wg-quick: line 32: resolvconf: command not found`,
install resolvconf:
```bash
$ sudo apt install resolvconf
```

To stop VPN, run:

```bash
$ wg-quick down ./something.conf
```

## OpenVPN

First, install resolvconf:

```bash
$ sudo apt install resolvconf
```

Then, go to your Mullvad account, select "OpenVPN configuration", "Linux", "Country" and download the zip archive.
Unzip the archive, open Gnome Network Settings, VPN, click "+" and then "Import from file". Select the `.conf`
file.

Now edit the VPN connection: under "Identity" you'll need to fill in the "user name" and "password";
you can find those in the `mullvad_userpass.txt` file:

- first line is the username, a bunch of numbers
- second line is the password, in my case it's just one character
