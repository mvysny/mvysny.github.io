---
layout: post
title: Updating Ubuntu Quickly
---

The best way is to have a script in your home called `update` which will take care of updating everything.
To invoke it, simply open a terminal with `Win+T` and run `~./update` - easy and fast.

Create the following scripts:

`~/shutdown`:

```bash
#!/bin/bash
set -e -o pipefail
sudo shutdown -h now
```

`~/reboot`:

```bash
#!/bin/bash
set -e -o pipefail
sudo reboot
```

`~/update`:
```bash
#!/bin/bash
set -e -o pipefail
sudo apt update
sudo apt -V dist-upgrade
sudo apt autoremove --purge
sudo snap refresh
# clean residual config
sudo apt purge $(dpkg -l | grep '^rc' | awk '{print $2}')
```

To run these scripts without needing to type in root password, run `sudo visudo` and add this line:
```sudoers
mavi ALL=(ALL) NOPASSWD:/usr/bin/apt *, /usr/bin/snap refresh, /usr/sbin/shutdown -h now, /usr/sbin/reboot
```

Also make the scripts executable: `chmod a+x shutdown reboot update`
