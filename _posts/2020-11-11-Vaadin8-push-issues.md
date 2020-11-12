---
layout: post
title: Vaadin 8 Push issues
---

Vaadin Push is a tricky complicated beast, based on a complicated push stack.
A lot of things can go wrong, causing the Vaadin client to freeze endlessly.
Let's discuss how exactly push works, and what can be done to prevent the freeze.

Note that it's often impossible to diagnose exactly where the problem lies:
the issue can be caused by a certain configuration of proxy, a random TCP/IP
connection drop, unfortunate timing, certain Spring or Servlet container version,
or any of the combination above.
Also, Vaadin reconnection mechanism is a complex state machine which is hard to test
and fix things in.
  
The following list could help with Vaadin 8 Push issues, such as UI freezing -
having the browser just sitting there, idle, with the Vaadin progress indicator blinking.

## What can go wrong with push

### Java support for Push

The Push history in Java application servers and servlet containers is a long history
of bugs in the servlet containers themselves, and workarounds made in the Atmosphere library.
See [Vaadin 8 Docs: Configuring Push For Your Environment](https://vaadin.com/docs/v8/framework/articles/ConfiguringPushForYourEnvironment.html)
for more details.

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

Moreover, during the 5 minute window, the server has no way of knowing that the
connection is broken; any reply sent from the server to the client is lost silently.
This is the major reason for UI freezings as we will describe below.

### Heartbeats/KeepAlive

In order to keep the connection alive and detect faulty connection state,
heartbeats are sent.

The client only sends the heartbeats to the server, the server never sends heartbeats
to the client. Therefore, the client has no way of learning that the connection is
broken. Moreover, the only thing the server will do is that it will close
the UI after three heartbeats have been missed;
neither the client nor the server will attempt to repair the connection by
reconnecting.

This will be important later on, when I demonstrate the way how the client
can freeze endlessly.

### XHR/Websocket VS Long-Polling

See [Long Polling vs WebSockets](../long-polling-vs-websockets/) for more details
on how those things work. In practice, Long-Polling has been observed to work
more reliably than WebSocket/XHR, therefore I'd advise you to use Long-Polling. 

### UIDL

Vaadin's synchronization protocol is based on UIDL (UI Diffing Language?).
Basically it's a JSON file, listing what have been changed since the last UIDL update. For example,
if you set a new caption to a TextField with connector ID 42, you will be able to
observe this information in the UIDL sent from the server to the client.

Essentially, Vaadin sends diffs (called UIDLs) of what has been changed from the server-side.

### Message Ordering

Since missing out just one of those diffs could lead to undefined client-side state,
Vaadin keeps strict track of which UIDLs has been sent and received by the client-side Vaadin code.
Essentially, the UIDL numbering scheme starts from 0 and continues in a strictly increasing
order.

However, certain condition may lead to UIDL messages dropped or reordered:

* Broken TCP/IP pipe (most common cause);
* A bug in Vaadin, handling possible race conditions incorrectly
* Other - these kind of bugs are hard to reproduce.

### Out-of-order UIDL Messages

Say Vaadin client receives message 62
while expecting 61. Vaadin will postpone the message 62 and will wait for message 61,
which may never arrive. Ultimately Vaadin will give up waiting and
will ask the server to perform a full resync. However, Vaadin will effectively
freeze the UI until either the message arrives, or a full resync is performed.

The following is logged into your browser's JavaScript console:

* The `Gave up waiting for message 61 from the server` message;
* The `Received message with server id 62 but expected 61. Postponing handling until the missing message(s) have been received` message

See [Bug 11702](https://github.com/vaadin/framework/issues/11702)
for an example.

> Unfortunately I don't know how long it will take for Vaadin to
give up waiting for message in this case and perform a resync. I'm assuming 5 minutes,
or perhaps it's the same setting governing heartbeats?

However, neither XHR/WebSockets nor Long-Polling transfer layer itself can cause
the message reordering, since they're both based on TCP/IP.
Therefore, there has to be other cause; the only way I can see this can happen
with XHR/WebSockets:
 
1. Vaadin Server sends UIDL over Websocket connection (which is broken) and so the message gets lost
2. (at some later time) Vaadin Client makes a XHR request to the Server and receives next UIDL.
3. Vaadin Client detects out-of-order message and awaits for previous message which will never come.

With Long-Polling, it could go like this:

1. Vaadin client establishes a connection but sends nothing, waiting for server to send something.
2. Proxy kills the connection after 2 minutes.
3. Server sends UIDL but the message is lost.
4. Client sends a ping message over a new connection; the server responds by a new UIDL
   message that had accumulated since step 3.
5. Vaadin Client detects out-of-order message and awaits for previous message which will never come.

### Frequent resync requests

Occassional resync requests are okay in case when the connection is lost, or
some internal bug of XHR/WebSocket causes out-of-order message to be sent in rare
case. However, frequent resync requests should definitely not happen on regular basis -
if they do, there's some kind of problem going on.

I can envision the following scenario for Long-Polling:

1. Client encounters out-of-order message as described above.
2. Client gives up waiting for the older message and sends resync over a new fresh connection.
3. The server responds, and the client resyncs successfully.
4. Client immediately opens a new connection but sends nothing. Goto 1.

The same thing can not happen with XHR/WebSocket:

1. Client encounters out-of-order message as described above.
2. Client gives up waiting for the older message and sends resync over a new fresh XHR connection.
3. The server responds over WebSocket connection (which is broken), and so the response is lost.
4. Vaadin Client now freezes, endlessly waiting for a resync response which will never come.

### Vaadin Client-side corrective measures

When the connection is broken, the client will basically perform the same corrective algorithm
both for WebSocket and Long-Polling. However, the effects are subtly different.

In both cases, we start with a state that a UIDL message has not been received for
5 minutes from the server. In both cases, Vaadin Client tries to
resync by sending a resync request.

In case of XHR/WebSockets:

1. The resync request is sent over XHR (a new fresh HTTP request), which reaches the server.
2. The server responds with UIDL over WebSocket connection (which is broken), and so
   the message gets lost.
3. Vaadin Client now freezes, endlessly waiting for a resync response which will never come.

The observable effect is that the client will freeze endlessly.

In case of Long-Polling:

1. The resync request is sent over a new fresh HTTP request, which reaches the server.
2. The server responds with UIDL over the same connection, which should now work.
3. Vaadin Client receives the resync request and reinitializes correctly.

The observable effect is that the client will eventually unfreeze,
but there will be a lot of resync requests in the logs.

## Solutions to try

Since a broken connection can cause the Vaadin client to freeze endlessly,
usually the best thing
is to prevent the connection from being broken at all costs.

### Make Heartbeats go faster

The default heartbeat interval is 5 minutes, however certain proxies will kill the
connection silently after 2 minutes of inactivity. A good heartbeat interval is
45-60 seconds (see [Wiki Keepalive](https://en.wikipedia.org/wiki/Keepalive)).
Read [Vaadin 8 Docs on configuring the heartbeat interval](https://vaadin.com/docs/v8/framework/articles/CleaningUpResourcesInAUI.html).

### Disable polling when using Push

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

As mentioned above, certain proxies will kill the TCP/IP connection silently after 2 minutes
of inactivity, and will stop relaying data over to the server. This will cause
the vaadin client to freeze indefinitely.

Increase the proxy inactivity setting to 10 minutes or even 20 minutes, to be extra-sure
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

### Use Long-Polling instead of Websocket/XHR

When using XHR/Websocket, Vaadin will in fact use TWO connections: one XHR
connection sending stuff from server to client, and a new TCP/IP connection whenever
client needs to send something to the server. That greatly increases the risk of
desynchronizing state and receiving messages out-of-order.

Therefore longpolling may help with out-of-order messages since it always only uses one TCP/IP
connection, and a fresh one at that. See above on how to detect out-of-order UIDL messages.

### Avoid Streaming, disable Anti-Virus, others

Please see [Vaadin 8 Docs: Configuring Push For Your Environment](https://vaadin.com/docs/v8/framework/articles/ConfiguringPushForYourEnvironment.html)
for more details.

### Spring+WebLogic+Push combo

I vaguely remember that certain WebLogic version will prevent Spring-based app to work when deployed as a WAR archive.

### Make Vaadin perform a page reload

This is a bit of a longshot, since this setting will cause Vaadin to perform 
page reload on session timeout, which may take a long time (~30 minutes)?

```java
    public static class Servlet extends VaadinServlet {
        @Override
        protected void servletInitialized() throws ServletException {
            super.servletInitialized();
            getService()
                    .setSystemMessagesProvider(new SystemMessagesProvider() {
                        @Override
                        public SystemMessages getSystemMessages(
                                SystemMessagesInfo systemMessagesInfo) {
                            CustomizedSystemMessages messages = new CustomizedSystemMessages();
                            messages.setSessionExpiredNotificationEnabled(
                                    false);
                            messages.setSessionExpiredURL(null);
                            return messages;
                        }
                    });
        }
    }
```

### Chrome freezing immediately on page reload

Speculation: could be because the newest version of Chrome does not support
Synchronous XMLHTTPRequest() in Page Dismissal anymore.
And Atmosphere's long polling implementation is in fact based on using
Synchronous XMLHTTPRequest(). Please check Atmosphere bug tracker for more details.

### If everything else fails

Disable push and use the poll mechanism, by setting the `UI.setPollInterval()`.

## Conclusion

* Push is not a silver bullet and can freeze your UI easily - avoid using
  unless necessary.
* Use Long-Polling over XHR/WebSocket, to reduce chance of UI freezing. Also,
  Long-Polling should not be affected by endless UI freezing.
* Prevent connection breaking at all costs, otherwise your UI will freeze indefinitely.
  * Either reconfigure the proxies to not to drop the connection, or increase heartbeat rate, or both.
