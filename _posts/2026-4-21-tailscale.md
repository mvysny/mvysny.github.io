---
layout: post
title: Tailscale - home LAN from anywhere
---

[Tailscale](https://tailscale.com) is the easiest way I know of to reach a
machine remotely on your home LAN from the internet, without port-forwarding,
without a public IP, and without poking holes in your router. WireGuard-based; client is fully open-source; installable via snap.

# How it works

Tailscale builds a **mesh VPN** on top of [WireGuard](https://www.wireguard.com/).
Every machine you install Tailscale on gets its own private IP in the
`100.64.0.0/10` range and can talk directly to every other machine in your
"tailnet" over an encrypted WireGuard tunnel.

The clever bit is the **coordination server** (Tailscale's SaaS control plane):

* You log in on each machine via SSO (Google, GitHub, Microsoft, ...).
  No passwords, no keys to copy around.
* The coordination server exchanges WireGuard public keys between your machines
  and tells them each other's current public IP+port.
* Machines then attempt direct peer-to-peer connections using
  **NAT traversal** (UDP hole-punching, STUN-style). This works even when both
  peers are behind NAT - no port forwarding needed.
* If NAT traversal fails (symmetric NAT, CGNAT, strict firewalls), traffic falls
  back to Tailscale's **DERP** relays - encrypted, but slower. Tailscale can't
  read the traffic either way: the WireGuard keys never leave your devices.

Tailscale itself is not fully open source - the coordination server is
proprietary, but the clients are. The free plan covers up to 100 devices and
3 users, which is plenty for personal use. If you want a fully OSS setup,
[Headscale](https://github.com/juanfont/headscale) is a drop-in replacement
for the coordinator, but honestly - for home use the free plan is just fine.

# Connecting two Ubuntu machines

On **both** machines (say, your home server and your laptop):

```bash
sudo snap install tailscale
sudo tailscale up
```

The `tailscale up` command prints a URL - open it in a browser and log in with
your SSO account of choice. Both machines must log in to the **same tailnet**
(same account).

That's it. Check assigned IPs:

```bash
tailscale ip -4      # your machine's tailnet IP
tailscale status     # all peers in your tailnet
```

From now on, you can `ssh user@100.x.y.z` from your laptop to your home
server from anywhere on the internet, as if they were on the same LAN.

# Useful extras

* **MagicDNS**: enable it in the admin console, then you can `ssh user@homeserver`
  using the machine's hostname instead of its tailnet IP.
* **Subnet router**: if you want to reach *other* devices on your home LAN
  (printer, NAS, router admin) without installing Tailscale on each one,
  run `sudo tailscale up --advertise-routes=192.168.1.0/24` on your home
  server and approve the route in the admin console. Your laptop can then
  reach `192.168.1.x` directly through the server.
* **Exit node**: `sudo tailscale up --advertise-exit-node` turns a machine
  into a VPN gateway - route all your laptop's traffic through your home
  connection when on untrusted Wi-Fi.
* **Tailscale SSH**: `sudo tailscale up --ssh` replaces sshd key management
  with tailnet identity. Nice, but optional.

No port forwarding, no dynamic DNS, no fail2ban tuning. It just works.
