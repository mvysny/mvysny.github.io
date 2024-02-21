---
layout: post
title: Vaadin Push Invalid JSON from Server 1 X
---

If Vaadin is failing with "Invalid JSON from server: 1|X", read on.
The problem is that Vaadin expects an UIDL JSON message over the websocket pipe and can't parse `1|X`. Where did `1|X` came from?

Atmosphere sends data in the format of `length|message`, which means that
`1|X` is an Atmosphere message "X" of length 1. It's a
[HeartbeatInterceptor](https://github.com/Atmosphere/atmosphere/blob/24a1456c137e36dfe7c7a6b180ebe299713fb457/modules/cpr/src/main/java/org/atmosphere/interceptor/HeartbeatInterceptor.java#L81)
message which should be part of the internal Atmosphere heartbeat mechanism and should
be filtered out by Atmosphere and thus ignored by Vaadin.

This kind of message is sent every 60 seconds by default by Atmosphere in all Vaadin apps using Push over WebSockets.
You can see this message in your browser's Network tab: it's marked with the HTTP Status 101.
101 is http code for upgrade to websocket, that's OK to see.

Workaround is to disable Atmosphere heartbeat mechanism, relying on Vaadin's
heartbeat mechanism only. Increase `org.atmosphere.interceptor.HeartbeatInterceptor.heartbeatFrequencyInSeconds` to some absurdly high value,
see `ApplicationConfig.HEARTBEAT_INTERVAL_IN_SECONDS` in Atmosphere for more details.

The heartbeat character is reconfigurable on server-side
via `ApplicationConfig.HEARTBEAT_PADDING_CHAR` - the javadoc says it's `' '` (space) but in reality it's
'X' as seen in `HeartbeatInterceptor.paddingBytes`. You use the `org.atmosphere.interceptor.HeartbeatInterceptor.paddingChar`
configuration option to reconfigure the character: place a breakpoint into `HeartbeatInterceptor.configure()` to
learn the effective value.

On the client side, you can check for the effective value of the padding character as follows:
the first message sent over Vaadin Push looks like this: `41|52a917c0-9c19-455a-a0d4-b155f46a3ed3|0|X|`. Pay attention
to the end of the message: the `0|X` configures the heartbeat padding to the `X` character.
Vaadin then configures Atmosphere to the 'X' padding character, causing Atmosphere to automatically ignore `1|X` messages.
It could be that your server sends a different padding character, e.g. `A` but then proceeds to send `1|X` heartbeat
messages, which then get passed to Vaadin, which then fails since Vaadin expects the UIDL JSON document.

## Double-wrapped messages

If you're receiving `3|1|X` then that's wrong - it should be `1|X`. Looks like there's "another" Atmosphere
which wraps the message "1|X" (the message 'X' of size 1) to "3|1|X" (the message '1|X' of size 3).

TODO how to solve this.

## TODO

TODO needs further investigation
