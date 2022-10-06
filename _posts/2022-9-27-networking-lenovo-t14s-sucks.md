---
layout: post
title: Networking in Lenovo T14s sucks
---

Networking in Lenovo ThinkPad T14s is a complete piece of garbage with
Linux kernel 5.15.0-48.
Which is a pity since T14s is otherwise a great laptop. However, the networking stack
is just completely broken, simple and plain.

## Wired eth

The wired eth via docking station will stop working randomly with these error messages.

```
[ 1235.442771] r8152 5-1.1:1.0 enx482ae3a2a6f0: Tx status -71
[ 1236.206773] r8152 5-1.1:1.0 enx482ae3a2a6f0: Tx status -71
[ 1236.462773] r8152 5-1.1:1.0 enx482ae3a2a6f0: Tx status -71
[ 1237.230771] r8152 5-1.1:1.0 enx482ae3a2a6f0: Tx status -71
[ 1238.877272] r8152 5-1.1:1.0 enx482ae3a2a6f0: Tx status -71
[ 1239.890773] r8152 5-1.1:1.0 enx482ae3a2a6f0: Tx status -71
[ 1240.910774] r8152 5-1.1:1.0 enx482ae3a2a6f0: Tx status -71
[ 1244.686793] r8152 5-1.1:1.0 enx482ae3a2a6f0: Tx status -71
```

Reported as [bug 1922651](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1922651) which is marked as fixed,
but unfortunately the bug still persists with Linux kernel 5.15.0-48. The only way
is to unplug the machine from the docking station, then plug it back, or just disable the cable networking.

The wired eth via an ethernet dongle ([Lenovo ThinkPad Ethernet Extension Cable Gen 2](https://www.verkkokauppa.com/fi/product/468930/Lenovo-ThinkPad-Ethernet-Extension-Cable-Gen-2))
will randomly stop working with the same error messages. Avoid like the pague!

### Workaround

Workaround: don't buy the ethernet dongle from Lenovo, buy [TP-LINK UE306](https://www.verkkokauppa.com/fi/product/743296/TP-LINK-UE306-USB-3-0-Gigabit-Ethernet-verkkokortti)
instead and plug it into your docking station. It has been working flawlessly for me so far.
It uses the `ax88179_178a` kernel module and reports like this in dmesg:
```
[   18.054458] ax88179_178a 5-1.2:1.0 enx7cc2c642aedf: ax88179 - Link status is: 1
```

## Wireless

The wireless will frequently and randomly stop working with the following messages, with an occasional kernel segfault on top:

```
[  592.333309] iwlwifi 0000:03:00.0: Queue 5 is stuck 225 43
[  592.334207] iwlwifi 0000:03:00.0: Microcode SW error detected. Restarting 0x0.
[  592.334615] iwlwifi 0000:03:00.0: Start IWL Error Log Dump:
[  592.334619] iwlwifi 0000:03:00.0: Transport status: 0x0000004A, valid: 6
[  592.334624] iwlwifi 0000:03:00.0: Loaded firmware version: 66.f1c864e0.0 cc-a0-66.ucode
[  592.334629] iwlwifi 0000:03:00.0: 0x00000084 | NMI_INTERRUPT_UNKNOWN       
[  592.334633] iwlwifi 0000:03:00.0: 0x008026F4 | trm_hw_status0
[  592.334637] iwlwifi 0000:03:00.0: 0x00000000 | trm_hw_status1
[  592.334640] iwlwifi 0000:03:00.0: 0x004FAA46 | branchlink2
[  592.334643] iwlwifi 0000:03:00.0: 0x004F13DE | interruptlink1
[  592.334646] iwlwifi 0000:03:00.0: 0x004F13DE | interruptlink2
[  592.334648] iwlwifi 0000:03:00.0: 0x00007D34 | data1
[  592.334652] iwlwifi 0000:03:00.0: 0x01000000 | data2
[  592.334654] iwlwifi 0000:03:00.0: 0x00000000 | data3
[  592.334657] iwlwifi 0000:03:00.0: 0x19407180 | beacon time
[  592.334660] iwlwifi 0000:03:00.0: 0x17866E48 | tsf low
[  592.334663] iwlwifi 0000:03:00.0: 0x0000003B | tsf hi
[  592.334666] iwlwifi 0000:03:00.0: 0x00000000 | time gp1
[  592.334669] iwlwifi 0000:03:00.0: 0x2016E44C | time gp2
[  592.334672] iwlwifi 0000:03:00.0: 0x00000001 | uCode revision type
[  592.334675] iwlwifi 0000:03:00.0: 0x00000042 | uCode version major
[  592.334678] iwlwifi 0000:03:00.0: 0xF1C864E0 | uCode version minor
[  592.334681] iwlwifi 0000:03:00.0: 0x00000340 | hw version
[  592.334684] iwlwifi 0000:03:00.0: 0x00489000 | board version
[  592.334686] iwlwifi 0000:03:00.0: 0x05E1001C | hcmd
[  592.334689] iwlwifi 0000:03:00.0: 0x80020000 | isr0
[  592.334692] iwlwifi 0000:03:00.0: 0x01400000 | isr1
[  592.334695] iwlwifi 0000:03:00.0: 0x08F00002 | isr2
[  592.334698] iwlwifi 0000:03:00.0: 0x00C3428C | isr3
[  592.334700] iwlwifi 0000:03:00.0: 0x00000000 | isr4
[  592.334703] iwlwifi 0000:03:00.0: 0x00BD019C | last cmd Id
[  592.334706] iwlwifi 0000:03:00.0: 0x00007D34 | wait_event
[  592.334709] iwlwifi 0000:03:00.0: 0x00000080 | l2p_control
[  592.334712] iwlwifi 0000:03:00.0: 0x00002020 | l2p_duration
[  592.334715] iwlwifi 0000:03:00.0: 0x0000003F | l2p_mhvalid
[  592.334717] iwlwifi 0000:03:00.0: 0x000000CE | l2p_addr_match
[  592.334720] iwlwifi 0000:03:00.0: 0x00000009 | lmpm_pmg_sel
[  592.334723] iwlwifi 0000:03:00.0: 0x00000000 | timestamp
[  592.334726] iwlwifi 0000:03:00.0: 0x0000C828 | flow_handler
[  592.335029] iwlwifi 0000:03:00.0: Start IWL Error Log Dump:
[  592.335031] iwlwifi 0000:03:00.0: Transport status: 0x0000004A, valid: 7
[  592.335035] iwlwifi 0000:03:00.0: 0x20000066 | NMI_INTERRUPT_HOST
[  592.335038] iwlwifi 0000:03:00.0: 0x00000000 | umac branchlink1
[  592.335041] iwlwifi 0000:03:00.0: 0x80455A96 | umac branchlink2
[  592.335044] iwlwifi 0000:03:00.0: 0x80473F9A | umac interruptlink1
[  592.335047] iwlwifi 0000:03:00.0: 0x80473F9A | umac interruptlink2
[  592.335050] iwlwifi 0000:03:00.0: 0x01000000 | umac data1
[  592.335052] iwlwifi 0000:03:00.0: 0x80473F9A | umac data2
[  592.335055] iwlwifi 0000:03:00.0: 0x00000000 | umac data3
[  592.335058] iwlwifi 0000:03:00.0: 0x00000042 | umac major
[  592.335061] iwlwifi 0000:03:00.0: 0xF1C864E0 | umac minor
[  592.335064] iwlwifi 0000:03:00.0: 0x2016E449 | frame pointer
[  592.335066] iwlwifi 0000:03:00.0: 0xC0886260 | stack pointer
[  592.335069] iwlwifi 0000:03:00.0: 0x00BD019C | last host cmd
[  592.335072] iwlwifi 0000:03:00.0: 0x00000000 | isr status reg
[  592.335349] iwlwifi 0000:03:00.0: IML/ROM dump:
[  592.335351] iwlwifi 0000:03:00.0: 0x00000003 | IML/ROM error/state
[  592.335447] iwlwifi 0000:03:00.0: 0x00006710 | IML/ROM data1
[  592.335547] iwlwifi 0000:03:00.0: 0x00000080 | IML/ROM WFPM_AUTH_KEY_0
[  592.335642] iwlwifi 0000:03:00.0: Fseq Registers:
[  592.335690] iwlwifi 0000:03:00.0: 0x60000041 | FSEQ_ERROR_CODE
[  592.335738] iwlwifi 0000:03:00.0: 0x00290021 | FSEQ_TOP_INIT_VERSION
[  592.335785] iwlwifi 0000:03:00.0: 0x00050008 | FSEQ_CNVIO_INIT_VERSION
[  592.335832] iwlwifi 0000:03:00.0: 0x0000A503 | FSEQ_OTP_VERSION
[  592.335879] iwlwifi 0000:03:00.0: 0x80000003 | FSEQ_TOP_CONTENT_VERSION
[  592.335927] iwlwifi 0000:03:00.0: 0x4552414E | FSEQ_ALIVE_TOKEN
[  592.335975] iwlwifi 0000:03:00.0: 0x00100530 | FSEQ_CNVI_ID
[  592.336022] iwlwifi 0000:03:00.0: 0x00000532 | FSEQ_CNVR_ID
[  592.336069] iwlwifi 0000:03:00.0: 0x00100530 | CNVI_AUX_MISC_CHIP
[  592.336119] iwlwifi 0000:03:00.0: 0x00000532 | CNVR_AUX_MISC_CHIP
[  592.336169] iwlwifi 0000:03:00.0: 0x05B0905B | CNVR_SCU_SD_REGS_SD_REG_DIG_DCDC_VTRIM
[  592.336219] iwlwifi 0000:03:00.0: 0x0000025B | CNVR_SCU_SD_REGS_SD_REG_ACTIVE_VDIG_MIRROR
[  592.336478] iwlwifi 0000:03:00.0: WRT: Collecting data: ini trigger 4 fired (delay=0ms).
[  592.336488] ieee80211 phy0: Hardware restart was requested
```

Workaround is to upgrade your access point. This only happens when I create an access point
on my phone, with WiFi 5 or lower. Enable Wifi 6 in your phone.

## Conclusion

It's so fucking irritating, piece of crap, avoid.
