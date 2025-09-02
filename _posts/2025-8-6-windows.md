---
layout: post
title: Windows Rant
---

Personally I think that Windows is a bloated spyware, unsuitable for anything but games.
Even though the DLL hell is largely a thing of the past, there are still myriad ways
of getting and updating things. I don't trust Microsoft to come up with any usable feature, and
I don't trust Microsoft with my privacy at all.

# Microsoft Online Account

The Windows installation now requires you to have Microsoft online account.
That is a huge red flag right there - I'm not trusting Microsoft with my privacy at all,
in the same way I don't trust Google, Facebook nor other businesses designed to sell
your data as a product. Even Apple allows you to bypass login - and even if this would be
required, it is acceptable for me since Apple's privacy policy is acceptable.

Luckily the MS online account can be bypassed: the `Shift+F10` and `OOBE\BYPASSNRO` worked for me.

Unfortunately, Windows Defender seem not to be working without the Microsoft Online Account -
or maybe it does, I'm not quite sure. I personally don't really care - I only use Windows
for gaming with Steam and Battle.net, and (hopefully) there are no viruses there.

# Bloatware

Windows comes with shitload of bloatware. It's not as bad as Samsung Android phones
where you have multiple app stores and shitload of bloatware apps which you can't uninstall because they're marked "system" -
I'll NEVER EVER get a Samsung phone.
At least, on Windows, you can uninstall the bloatware that comes with Windows: the Office 365,
the McAffee Antivirus bloat (!!!) and shitload of other crap I don't even remember.
As I said, at least you can uninstall that shit.

Windows feels like an outlet for marketing spam - it constantly tries
to make me click on headlines or sell me subscription to One Drive or Office 365.
I don't even know what Office 365 is, and I don't want to know. But this tactics doesn't
strike me as trustworthy. I don't feel this protects my privacy first and foremost, far from it:
Windows feels like something I got for free, and it instantly tries to monetize me.

Also see [M4 Macbook Air vs Surface Laptop Video](https://www.youtube.com/watch?v=4RQ6pek3JoM)
and [After MacOS I tried Windows again](https://www.youtube.com/watch?v=4wrJE3SBTBU). The 'virus'
comment is spot on.

# Programming

The default `cmd.exe` is a joke; maybe PowerShell is better but I'll never know.
If I have to use Windows, I'd set up Linux Subsystem and work there. And I'll take
a performance penalty, see below. What a joke.

# Updates

Updates in Windows is the same clusterfuck as it used to be, even though things
are getting better as apps are moving to AppStore. Still, in order to update stuff:

1. Windows Update
2. Nvidia updates via its own app
3. Firefox and many others update via AppStore
4. Rest of the apps update via their own built-in updaters
5. At some point you'll install Chocolatey which has its own updater
6. You download installers from the internet and you have to have antivirus software.

Compare that to Linux or Mac:

1. On Linux, you install and update everything via `apt` and/or `snap`. No risk of downloading virus accidentally.
2. On MacOS, you update system and all drivers via System Update, you update software via App Store.

# WSL2

WSL2 boots Linux in a very thin VM, however on Windows 11 Home the VM is slow as hell.
Building Karibu-Testing on AMD Ryzen 7 7435HS takes 73s on WSL2 Linux, while it only takes
53s on a Linux running natively, which means that WSL2 incurs 30% overhead, which is just
laughable.

# Family Admin

[A Journey from Windows to Mac](https://www.youtube.com/watch?v=1FmfbajY5bE) has bunch
of good points: I don't have to become an administrator for PCs in my family. I save
time, energy and my mind is at peace.

# Conclusion

Windows may be built on a decent kernel, but the bloatware, the cheap selling practices, the ridiculous
update procedure and lack of support for programming
make it unsuitable for anything but games for me.
Hopefully Steam+Proton will enable gaming on Linux boxes so that I can get rid of Windows entirely.

I don't generally trust that Windows is built on solid foundation,
and this is the difference between Windows and Linux. For example I don't trust Windows Drivers to be developed properly,
since they're not coming from Microsoft. Windows is a decent UI built on flaky foundation,
while Linux is a bad-ish UI built on a solid foundation.
