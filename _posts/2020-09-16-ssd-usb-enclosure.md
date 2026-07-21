---
layout: post
title: SATA SSD USB Enclosure
---

You need to be careful when picking an USB enclosure for your SATA SSD drive: the problem is that
not every USB enclosure supports the SATA TRIM / USB UNMAP command, which is
a must for keeping your SSD healthy.

When browsing the internet, I've found that the [JMICRON JMS578](https://www.jmicron.com/products/list/12#p_13) chipset
does support TRIM. Therefore I've purchased [cBox T23M USB 3.1](https://www.verkkokauppa.com/fi/product/78951/mrddh/cBox-T23M-USB-3-1-2-5-SATA-kovalevykotelo)
which uses the JMS578 chipset.

Indeed, plugging the enclosure into my computer and running `lsblk` confirmed
that the enclosure supports TRIM:

```bash
$ lsblk --discard
NAME   DISC-ALN DISC-GRAN DISC-MAX DISC-ZERO
sdc           0        4K       4G         0
├─sdc1        0        4K       4G         0
└─sdc2        0        4K       4G         0
```

However, some older enclosures using the JMS578 chipset with older firmware may not
support TRIM. In such case you need to
[upgrade the firmware of your JMS578 chipset](https://wiki.odroid.com/odroid-xu4/software/jms578_fw_update).

Even though JMicron doesn't claim that JMS578 supports UNMAP/TRIM directly, it states
support for [UASP](https://en.wikipedia.org/wiki/USB_Attached_SCSI) specification which
lists the "Enables TRIM (UNMAP in SCSI terminology) operation for SSDs" as one of its goals.
Therefore, when searching for an enclosure, make sure it either:

* Explicitly states TRIM support, or
* Explicitly states UASP support, or
* Uses a chipset which supports UASP or TRIM, such as JMS578.
