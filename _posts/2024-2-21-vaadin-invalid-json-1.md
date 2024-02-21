---
layout: post
title: Vaadin Push Invalid JSON from Server 1 X
---

If Vaadin is failing with "Invalid JSON from server: 1|X", read on.
Atmosphere sends data in the format of `length|message`, which means that
this is an Atmosphere message "X" of length 1. It's a
[HeartbeatInterceptor](https://github.com/Atmosphere/atmosphere/blob/24a1456c137e36dfe7c7a6b180ebe299713fb457/modules/cpr/src/main/java/org/atmosphere/interceptor/HeartbeatInterceptor.java#L81)
message which should be part of the internal Atmosphere heartbeat mechanism and should
be filtered out by Atmosphere and thus ignored by Vaadin.

This kind of message is sent every 60 seconds by default by Atmosphere in all Vaadin apps using Push over WebSockets.
You can see this message in your browser's Network tab: it's marked with the HTTP Status 101.

Workaround is to disable Atmosphere heartbeat mechanism, relying on Vaadin's
heartbeat mechanism only. Increase `atmosphere.websocket.maxIdleTime` to some absurdly high value.

TODO needs further investigation
