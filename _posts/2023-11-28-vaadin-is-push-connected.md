---
layout: post
title: Vaadin - Is Push WebSocket connected?
---

You can call `UI.getCurrent().getInternals().getPushConnection().isConnected()`
to figure out whether Atmosphere websocket pipe is connected.

However, it's trickier than that. WebSocket [runs over TCP/IP](https://stackoverflow.com/a/9204009/377320)
and never runs over UDP. While TCP/IP guarantees that the packets are not reordered,
the [actual delivery is not guaranteed](https://stackoverflow.com/questions/36055098/is-websocket-connection-reliable).
This is a [fundamental limitation of TCP/IP](../tcp-ip-sucks/).

The only way to know the state of a TCP/IP connection (and, by extension, the WebSocket pipe),
is to send a "ping" request and wait for a reply. Vaadin performs this automatically:
the client-side Vaadin javascript sends heartbeats to the server periodically, as described
in [Application Lifecycle: UI Expiration](https://vaadin.com/docs/latest/advanced/application-lifecycle#application.lifecycle.ui-expiration).

Therefore, to increase the probability of knowing accurately whether websocket pipe is actually alive,
you can increase the heartbeat frequency to 1 heartbeat every minute, then checking
the value of `ui.getInternals().getLastHeartbeatTimestamp()`: if the difference between
the current timestamp is less than a minute, the websocket pipe can be considered "up".

You can never be 100% sure, but with the heartbeat frequency of 1 minute, you can
be reasonably sure.
