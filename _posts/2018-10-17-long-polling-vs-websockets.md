---
layout: post
title: Long Polling vs WebSockets
---

When you need to use Push with your Vaadin app, you generally have two choices: Long Polling and Web Sockets. Which one to use?

## Long Polling

So what's a Long Polling? Imagine that the server needs to send something to the browser. With standard http communication protocol, the connection is only alive when the browser needs something. The server has to wait until the browser makes a connection (which may take a long time).

The first solution was long polling. Basically after the request is done, the browser immediately opens a new request but sends nothing and stalls. Now that the TCP/IP connection is there, the server can send something at any time.

Some proxies however do not like multiple messages to be sent in one connection. They would simply drop all consecutive messages except for the first one. So with the long polling, the server sends one message and closes the connection. The browser updates itself and opens a new connection, to which the server responds with another message and closes the connection again. This is a lot of TCP/IP overhead entailing repeated connection opening and closing. Also, the http headers need to be sent every time, which is additional overhead.

A solution has been devised, that would introduce an always-opened pipe through which both parties (browser and server) could communicate asynchronously by sending messages to each other, without the http overhead and TCP/IP overhead. That's WebSockets.

## WebSockets

By default Vaadin will use WebSockets with XHR. WebSocket connection is established by the browser, in order for the server to be able to notify the browser at any time; however when browser wants something it will send a new HTTP XHR request. This looks like quite an overhead: why doesn't Vaadin simply use pure web sockets for client request as well? The reason is that some proxies may suddenly stop your websocket traffic for no apparent reason, which would stop traffic both ways, so your Vaadin app would for example stop responding to button clicks. Therefore, it's better to use XHR - even if the websocket freezes, only the push messages from the server are affected, but your app is still responsive, client-wise. Eventually a heartbeat will be sent, which would then "repair" (re-establish) a broken WebSocket pipe.

However, WebSockets have a disadvantage: they do not hold a http session. The Atmosphere library emulates the http session for WebSocket requests, but it may fail in some setups, leading to [The Dreaded "Vaadin Session has Expired"/"Cookies Disabled"](../the-dreaded-vaadin-session-has-expired).

## Comparing Those Two

The simplest alternative is to use HTTP Long Polling, by annotating your UI with `@Push(value = PushMode.AUTOMATIC, transport = Transport.LONG_POLLING)`. That way websockets aren't used at all, just the standard http mechanism you've already been using. Long polling may break with some proxies though, so you'd want to test that first. Comparing those two:

* WebSockets is able to run over UDP but web browser's WebSocket use TCP/IP anyway now ([we might get UDP in the future](https://gafferongames.com/post/why_cant_i_send_udp_packets_from_a_browser/) though, via Google's QUIC). So with respect to the transport layer, both use TCP/IP (even though Long Polling additionally uses http protocol which is much more chatty than the websocket protocol).
* TCP/IP is horrible with respect to liveness - it will detect that a connection is broke after 2 hours, stalling new data. This kind of behavior is useless with real-world apps. That's why WebSockets define and use PING/PONG messages which is great for keepalive. However, Vaadin uses heartbeat too. So, with both websockets and long polling we have a long running TCP/IP with ping mechanism to detect liveness of the connection.
* The thread doesn't have to wait actively for receiving data with long polling nor web sockets (since we have NIO(2)), so neither of those two cause resource (thread/memory/cpu) hogs.

The real disadvantages are summed in [The Myth of Long Polling](https://blog.baasil.io/why-you-shouldnt-use-long-polling-fallbacks-for-websockets-c1fff32a064a), in short:

* Long Polling is way more chatty and has TCP/IP overhead;
* It's very slow when you have a rapid stream of messages from the server.

However, if your app updates e.g. once per 10 seconds and is deployed on the intranet with huge LAN network speeds, the long polling may be quite a viable alternative to the web sockets.

It's best to choose one that works with your setups, with the browsers you need to support and with the proxies the customers might be using.
