---
layout: post
title: Vaadin 8 Push issues
---

There's so much that can go wrong in Java world of Push - the Atmosphere contains
workarounds for server bugs that got ironed out eventually; Spring+WebLogic+Push
combo may not work for certain Spring and WebLogic versions, etc. Here I'll try
to list everything I know what could go wrong.

Note that it's often impossible to diagnose exactly where the problem lies:

* The issue can be caused by a certain configuration of proxy, a random TCP/IP
  connection drop, unfortunate timing, certain Spring or Servlet container version,
  or any of the combination above.
* Vaadin Reconnection mechanism is a complex state machine which is hard to test
  and fix things in.
* Therefore, it's almost impossible to figure out what the problem is, even if
  you obtain all the logs. Even if you gain insight what's going on, fixing
  the state machine is hard.
  
Therefore, the best way is to try out as much as possible from the items below,
hope for the best, and eventually move to Vaadin 14.

The following list could help with Vaadin 8 Push issues, such as:

* UI Freezing - browser just sitting there, idle, with the Vaadin progress indicator blinking
* Frequent page reloads for no apparent reason

## What can go wrong

### TCP/IP breaks silently

TCP/IP is a horrible abstraction: it may break at any time for no apparent reason,
and when it does, it starts acting as `/dev/null`: sending bytes succeed,
but they're not really sent and there's simply no response, ever. There's no way to make this work:

* SO_KEEPALIVE is a ping with undefined ping interval since on Java you can't specify
  TCP_KEEPCNT, TCP_KEEPIDLE nor TCP_KEEPINTVL, therefore it's useless. If I remember
  correctly the default is *two hours* and may be only configured on the OS level
  which makes it completely useless.
* SO_TIMEOUT only prevents from blocking too long, but doesn't really keep the connection up.
  See [setSoTimeout on StackOverflow](https://stackoverflow.com/questions/12820874/what-is-the-functionality-of-setsotimeout-and-how-it-works)
  for more details.
* SO_LINGER also doesn't keep the connection open; more on [SO_LINGER StackOverflow](https://stackoverflow.com/questions/3757289/when-is-tcp-option-so-linger-0-required).

The only way to remedy this is to send a protocol-specific Ping packets; in Vaadin's terminology those are called
[heartbeats](https://vaadin.com/docs/v8/framework/application/application-lifecycle.html).

Since both WebSockets and Long-polling run on top of TCP/IP, they're both affected.

The default heartbeat interval is 5 minutes. That effectively mean that, in the worst
case, Vaadin can only learn after *5 minutes* that the connection is down,
and can deploy the counter-measures of resyncing state fully
from the server-side.

### XHR/Websocket VS Long-Polling

See [Long Polling vs WebSockets](../long-polling-vs-websockets/) for more details
on how those things work. In practice, Long-Polling has been observed to work
more reliably than WebSocket/XHR, therefore I'd advise you to use Long-Polling. 

### UIDL

Vaadin's synchronization protocol is based on UIDL (UI Definition/Diffing Language? :-D ).
Basically it's a JSON file, listing what have been changed since the last UIDL update. For example,
if you set a new caption to a TextField with connector ID 42, you will be able to
observe this information in the UIDL sent from the server to the client.

Essentially, Vaadin sends diffs (called UIDLs) of what has been changed from the server-side.
Since missing out just one of those diffs could lead to undefined client-side state,
Vaadin keeps strict track of which UIDLs has been sent and received by the client-side Vaadin code.

### Message Ordering

Every UIDL message has a precise order number which is kept strictly in sync.

However, certain condition may lead to UIDL messages dropped or reordered:

* Broken TCP/IP pipe (most common cause);
* A bug in Vaadin, handling possible race conditions incorrectly
* Other - these kind of bugs are hard to reproduce.

### Out-of-order UIDL Messages

Say Vaadin receives message 62
while expecting 61. Vaadin will postpone the message 62 and will wait for message 61,
which may never arrive. Ultimately Vaadin will give up waiting and
will ask the server to perform a full resync.

The following is logged into your browser's JavaScript console:

* The `Gave up waiting for message 61 from the server` message;
* The `Received message with server id 62 but expected 61. Postponing handling until the missing message(s) have been received` message

See [Bug 11702](https://github.com/vaadin/framework/issues/11702)
for an example.

> Unfortunately I don't know how long it will take for Vaadin to
give up waiting for message in this case and perform a resync. I'm assuming 5 minutes,
or perhaps it's the same setting governing heartbeats?

However, neither XHR/WebSockets nor Long-Polling transfer layer can cause
the message reordering, since they're both based on TCP/IP.
Therefore, the only explanation I can see
is some kind of race condition on Vaadin server-side, or an unfortunate
network timing originating from
client performing XHR call and getting a newer UIDL, while WebSocket is busy delivering
an older UIDL with a delay.

However, in this case, the Vaadin client will eventually perform a full resync
and should unfreeze, given that the connection is not broken.

### Frequent resync requests

Occassional resync requests are okay in case when the connection is lost, or
some internal bug of XHR/WebSocket causes out-of-order message to be sent in rare
case. However, frequent resync requests should definitely not happen on regular basis -
if they do, there's some kind of problem going on.

### Vaadin Client-side corrective measures

When the connection is broken, the client will basically do this:

1. Await for next UIDL (which will never come)
2. After 5 minutes it will ask for a resync. It's not known whether the client does so
   over XHR or over WebSocket - if over WebSocket, the resync request will get lost as well;
   if over XHR and the response is sent via WebSocket, the response will get lost as well.
3. The client will endlessly await for resync, thus appearing to be frozen.

The client only sends the heartbeats to the server, the server never sends heartbeats
to the client. Moreover, the only thing the server will do is that it will close
the UI after three heartbeats have been missed. Unfortunately,
neither the client nor the server will attempt to repair the connection by
reconnecting.

Therefore, if the connection becomes broken, Vaadin client will simply freeze
indefinitely.

## Blinking progress bar

What can cause the blinking progress bar?

1. TCP/IP connection broken; Vaadin waiting for next heartbeat, ultimately giving up
   and performing resync. This can be remedied by make heartbeats fire more rapidly,
   or to reconfigure proxies/loadbalancers/others to stop killing the connection.
2. Vaadin receives UIDL messages out-of-order. Not known how to
   make Vaadin give up faster, and not sure whether that's even a good idea.

## Solutions to try

Hopefully something from the following might help. Usually the best thing
is to prevent the connection from being broken at all costs, since
that causes the Vaadin client to freeze indefinitely.

### Make Heartbeats go faster

The default heartbeat interval is 5 minutes, however certain proxies will kill the
connection silently after 2 minutes of inactivity. A good heartbeat interval is
45-60 seconds (see [Wiki Keepalive](https://en.wikipedia.org/wiki/Keepalive)).
Read [Vaadin 8 Docs on configuring the heartbeat interval](https://vaadin.com/docs/v8/framework/articles/CleaningUpResourcesInAUI.html).

### Don't use polling

> Note: Polling refers to `UI.setPollInterval()` which works both with and without Push,
while Long-Polling only works with push. Polling and Long-Polling are two very different things.

Setting `UI.setPollInterval()` to 0 or greater may interfere with Push, even though
it technically shouldn't. Make sure nobody is calling that method, by simply overriding it
in your UI and throwing an exception, or calling `super.setPollInterval(-1)`.

The problem is that polling may start sending new stuff from the client, while push
enables the server to send new stuff as well.

### Upgrade Vaadin 8

Certain bugs ([7719](https://github.com/vaadin/framework/issues/7719), [11702](https://github.com/vaadin/framework/issues/11702)) have been fixed
in Vaadin 8.9.3 or later; other push-related bugs could have been fixed in newer versions as well.
Please make sure you're using the newest Vaadin possible.

If you see `SEVERE: Trying to start a new request while another is active`, that's [bug 7719](https://github.com/vaadin/framework/issues/7719)
which should be fixed in Vaadin 8.9.3.

### Reconfigure Proxy

As mentioned above, certain proxies will kill the connection silently after 2 minutes
of inactivity. Increase this setting to 10 minutes or even 20 minutes, to be extra-sure
that Vaadin pings will keep the connection open. Alternatively, decrease the heartbeat
interval to be 45-60 seconds.

Alternatively, configure a slightly shorter timeout for push in the Vaadin application
so that the server terminates the idle connection and is aware of the termination
before the proxy can kill the connection. Use the
`pushLongPollingSuspendTimeout` servlet parameter for this
(defined in milliseconds) (Vaadin 7.6+).

### Reconfigure Load Balancer / VPN / Firewall

The same thing as with the proxy - certain load balancers/VPNs/Firewalls will kill the connection
silently after 2 minutes of inactivity. See the "Reconfigure Proxy" above for
a possible list of solutions.

### Try using Long-Polling instead of Websocket/XHR

When using XHR/Websocket, Vaadin will in fact use TWO connections: one XHR
connection sending stuff from server to client, and a new TCP/IP connection whenever
client needs to send something to the server. That greatly increases the risk of
desynchronizing state and receiving messages out-of-order.

Therefore longpolling may help with out-of-order messages since it always only uses one TCP/IP
connection. See above on how to detect out-of-order UIDL messages.

### Avoid Streaming, disable Anti-Virus, others

Please see [Vaadin 8 Docs: Configuring Push For Your Environment](https://vaadin.com/docs/v8/framework/articles/ConfiguringPushForYourEnvironment.html)
for more details.