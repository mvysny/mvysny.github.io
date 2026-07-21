---
layout: post
title: Debugging GWT superdevmode remotely from your Android Phone
---

You have your superdevmode development environment up and running. All is peachy
and world is unicorns until you figure out that some pesky bug is only reproducible
on a cell phone. Bam. What now?

No worries! The totally awesome thing about PC Chrome is how easy it is to access
the phone's Chrome browser log, modify DOM, everything. All this from the comfort
of your PC. Just follow this tutorial and prepare for a major wow effect:
[Crhome-DevTools Remote Debugging](https://developers.google.com/web/tools/chrome-devtools/remote-debugging/).
Simply by clicking that *Inspect* button you will be able to use the full power
of Chrome Dev Tools on your PC, of a page displayed and running in Android's Chrome.

Usually both the PC and Android are connected to the same wifi, and thus Android
will see the PC. I'm going to assume here that your PC's IP is `192.168.100.17`.
Naturally you will type in [http://192.168.100.17:8080?superdevmode](http://192.168.100.17:8080?superdevmode)
into Android's Chrome and naturally it won't work.

The usual approach is to add tons of configuration options as stated below.
**TL;DR**: skip them and use the port forwarding solution below which is way easier
and less error-prone.

## The old and traditional solution which you'll want to avoid unless port forwarding is not an option for you for some reason

We need to configure stuff first.

1. First we need to open up the codeserver so that it accepts connections from
   all over the world, not just from localhost. Open your `mvn vaadin:run-codeserver`
   launch configuration in intellij, and set *Command line* to `vaadin:run-codeserver -Dgwt.bindAddress=0.0.0.0`
2. To force the Android Chrome browser to connect to the proper codeserver one
   needs to set it in the URL. Just make the Android Chrome Browser to open [http://192.168.100.17:8080?superdevmode=192.168.100.17](http://192.168.100.17:8080?superdevmode=192.168.100.17)
3. To avoid this pesky message *"Ignoring non-whitelisted Dev Mode URL:"* in your
   Android's Chrome (some security precaution introduced in GWT 2.6) you need to
   bootstrap from a slightly modified `widgetset.gwt.xml`. Just follow
   [StackOverflow SuperDevMode in GWT](http://stackoverflow.com/questions/18330001/super-dev-mode-in-gwt)
   and add the following into your `widgetset.gwt.xml` and recompile, so that
   you will bootstrap with proper settings:
```xml
<set-configuration-property name="devModeUrlWhitelistRegexp" value=".*" />
```

Now what to do if you don't have your own widgetset but instead you are just using the precompiled one from `vaadin-client-compiled.jar`? Obviously you will bootstrap off the default unmodified `DefaultWidgetSet.gwt.xml` from `vaadin-client-compiled.jar`. You could do `mvn clean install` of modified Framework `client/src/main/resources/com/vaadin/DefaultWidgetSet.gwt.xml` but we can be smarter and use port forwarding.

## Port Forwarding

Instead of twiddling with countless configuration options we will pretend that
your phone is the one who is actually running the server. By doing that we can
just type in [http://localhost:8080?superdevmode](http://localhost:8080?superdevmode)
into Android's browser and thus bypass those pesky security precautions.
This can be done by somehow listening on TCP ports 8080 and 9876 on your phone;
when someone connects, just send all data to the PC. This technique is called *port forwarding*.

Make sure you have Android SDK installed. You can download that for free here:
[https://developer.android.com/studio/index.html](https://developer.android.com/studio/index.html)
- you can either download the full-blown Android Studio which comes with the
SDK itself, or just scroll down to the end of the page and install the `sdk-tools`,
the choice is yours. We will only need the `adb` binary anyway.

Now open up your console and type in the following:
```bash
$ adb reverse tcp:9876 tcp:9876
$ adb reverse tcp:8080 tcp:8080
$ adb reverse --list
(reverse) tcp:9876 tcp:9876
(reverse) tcp:8080 tcp:8080
```

If `adb` complains that `error: no devices/emulators found` just close your
PC's Chrome, so that it will close its connections to Android and will thus
allow `adb` to connect.

Now fire up Chrome, Remote, and just type [http://localhost:8080?superdevmode](http://localhost:8080?superdevmode)
into your Android Chrome and you should be good to go.

## FAQ

### Q: The widgetset compiles but my changes aren't applied
A: Simply use the port forwarding solution. Else make sure there is no
*"Ignoring non-whitelisted Dev Mode URL:"* message in the browser's console.
If there is, you will need to bootstrap off a modified `widgetset.gwt.xml`.

### Q: The widgetset recompilation fails
A: Simply use the port forwarding solution. Else make sure the codeserver listens
on all interfaces (`netstat -tnlp|grep 9876` will give you `:::9876` instead of
`127.0.0.1:9876`). Also make sure you're using `?superdevmode=192.168.100.17`
in the Android Chrome's URL.

### Q: `adb list` won't show my phone and/or complains with `error: no devices/emulators found`
A: Make sure that your PC's Chrome is not connected to Android. Close all Chrome
Remote windows; close all the "Remote Devices" tabs in PC Chrome. Or simply close
Chrome while we configure port forwarding.
