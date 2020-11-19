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

## Push Explained

### Java support for Push

The Push history in Java application servers and servlet containers is a long history
of bugs in the servlet containers themselves, and workarounds made in the Atmosphere library.
See [Vaadin 8 Docs: Configuring Push For Your Environment](https://vaadin.com/docs/v8/framework/articles/ConfiguringPushForYourEnvironment.html)
for more details.

### TCP/IP breaks silently

TCP/IP is a horrible abstraction. Read [TCP-IP Sucks](../tcp-ip-sucks) for more details.

Since both WebSockets and LONG_POLLING run on top of TCP/IP, they're both affected.
Vaadin uses something called
[heartbeats](https://vaadin.com/docs/v8/framework/application/application-lifecycle.html),
however they're severely limited when compared to the 'ping' mechanism. Read below for more info.

When the connection is broken, the server has no way of knowing that the
connection is broken; any UIDL sent from the server to the client is lost silently.
This is the major reason for UI freezings as we will describe below.

> Note: the client always uses a new connection when contacting server, both with
> WEBSOCKET_XHR and with LONG_POLLING, therefore requests from the client are
> usually not affected by broken TCP pipes. Not the case for WEBSOCKET which uses
> the websocket pipe for client-to-server requests as well.

### Heartbeats/KeepAlive

Unfortunately, Vaadin [heartbeats](https://vaadin.com/docs/v8/framework/application/application-lifecycle.html)
can not detect a broken connection with WEBSOCKET_XHR and
LONG_POLLING, and here's why.

It's only the Vaadin client that sends the heartbeats to the server, the server never sends heartbeats
nor responses to a heartbeat to the client. Therefore, the client has no way of learning from the heartbeats alone
that the connection is
broken. Moreover, the only thing the server will do is that it will close
the UI after three heartbeats have been missed. The server will never attempt to repair the connection by
reconnecting. On top of that, heartbeats are always sent over a *new* requests - they don't
use LongPolling GET nor the websocket pipe.

However, using `Transport.WEBSOCKET` (not WEBSOCKET_XHR) will make poll requests (not heartbeats though)
go through the websocket pipe, which allows the poll requests to serve as a keepalive ping.

### Push transport modes

Vaadin supports three transport modes:

* `LONG_POLLING` - Vaadin client/atmosphere creates a long-running HTTP GET request which
  blocks on the server side until server has something asynchronous to send back. Nothing else
  is sent through this pipe - both heartbeats and regular requests open a new separate
  TCP/IP connections. Heartbeats are sent
  as a new `HTTP POST` request to `/HEARTBEAT/?v-uiId=xyz` with no UIDL response;
  regular requests are sent as a new `HTTP POST` request to
  `/UIDL/?v-uiId=xyz` and the server responds with the UIDL message
  (which is sent through this new request instead of through the long-running HTTP GET request).
  The GET request URL looks like this: `PUSH?v-uiId=1&v-pushId=9d11a92e-4757-4929-b27e-dcd88d4ebbc3&X-Atmosphere-tracking-id=42cffc7f-746a-42e1-a411-ba50e7a0d6bf&X-Atmosphere-Framework=2.3.2.vaadin1-javascript&X-Atmosphere-Transport=long-polling&X-Atmosphere-TrackMessageSize=true&Content-Type=application/json; charset=UTF-8&X-atmo-protocol=true&_=1605779039425`.
* `WEBSOCKET_XHR` - Vaadin client/atmosphere creates a long-running websocket bi-directional pipe.
  The server writes to the pipe when there's something asynchronous to send back. Nothing else
  is sent through this pipe - both heartbeats and regular requests open a new separate
  TCP/IP connections, exactly as with `LONG_POLLING`.
  The reasoning is that if the websocket connection became broken, it doesn't prevent
  from requests still reaching the server. The websocket URL will also look like this: `PUSH?v-uiId=1&v-pushId=2560ed30-365e-45e9-8cbd-699189c065f8&X-Atmosphere-tracking-id=0&X-Atmosphere-Framework=2.3.2.vaadin1-javascript&X-Atmosphere-Transport=websocket&X-Atmosphere-TrackMessageSize=true&Content-Type=application/json; charset=UTF-8&X-atmo-protocol=true`,
  the important difference is that the status will be `101` and the 'type' will be either 'plain' (Firefox)
  or 'websocket' (Chrome).
* `WEBSOCKET` - Vaadin client/atmosphere creates a long-running websocket bi-directional pipe.
  The server writes to the pipe when there's something asynchronous to send back.
  The heartbeats are still sent via separate requests, however the regular requests
  (including poll-activated requests) are now transmitted via the websocket pipe.
  Therefore, using poll interval of, say, 30 seconds will cause activity on the pipe,
  preventing load-balancers/proxies/firewalls from killing the connection.
  However, a broken pipe will instantly kill any kind of comms between the client and the server.
  The websocket request URL will look the same as with `WEBSOCKET_XHR`.

#### Chrome Rant

Chrome decides to simply drop parts of the URL and will simply only show the
`?v-uiId=xyz` instead of `/UIDL/?v-uiId=xyz` part in the Network tab. You will thus be unable
to tell between UIDL requests and Heartbeat requests. I have no idea in which fucking universe this makes sense,
just be aware of this shit.

### WEBSOCKET_XHR VS LONG_POLLING

See [Long Polling vs WebSockets](../LONG_POLLING-vs-websockets/) for more details
on how those things work. In practice, LONG_POLLING has been observed to work
more reliably than WebSocket/XHR, therefore I'd advise you to use LONG_POLLING. 

Also, LONG_POLLING is typically much better supported by proxies/load balancers since
it's just a regular HTTP request, as opposed to a websocket pipe (which is a special HTTP
protocol upgrade).

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

Out-of-order UIDL condition is easy to spot: the following messages are logged into your browser's JavaScript console:

* The `Gave up waiting for message 61 from the server` message;
* The `Received message with server id 62 but expected 61. Postponing handling until the missing message(s) have been received` message

See [Bug 11702](https://github.com/vaadin/framework/issues/11702)
for an example.

After the "out-of-order UIDL" condition is encountered, Vaadin client will only wait 5 seconds
before sending the resync request. This is governed by the `MessageHandler.MAX_SUSPENDED_TIMEOUT`
setting which is hard-coded and can not be reconfigured.

Neither WEBSOCKET_XHRs nor LONG_POLLING transfer layer itself can cause
the message reordering, since they're both based on TCP/IP.
Therefore, it is simply caused by having two communication pipes, one of them becoming unresponsive.
With WEBSOCKET_XHRs:

1. Vaadin client establishes the websocket connection but sends nothing, waiting for server to send something.
2. Proxy kills the connection after 2 minutes.
3. Vaadin Server sends a push UIDL message over Websocket connection.
   The connection is broken and so the message gets lost.
4. (at some later time) Vaadin Client makes a XHR request to the Server and receives next UIDL.
5. Vaadin Client detects out-of-order message and awaits for previous message which will never come.
6. Vaadin Client times out after 5 seconds and asks for a resync in a separate connection.

With WEBSOCKET, the out-of-order UIDLs can not happen since the entire communication
goes through a single channel (the websocket connection):

1. Vaadin client establishes the websocket connection.
2. Eventually, proxy kills the connection after 2 minutes.
3. Vaadin Server sends a push UIDL message over Websocket connection.
   The connection is broken and so the message gets lost.
4. (at some later time) Vaadin Client makes a XHR request to the Server. The connection
   is broken and so the message gets lost.
5. Vaadin Client awaits for an answer which will never come.
6. TODO investigate: Will Vaadin Client eventually timeout and resync?
7. Resync request is sent over websocket and lost.
8. Vaadin Client freezes endlessly.

With LONG_POLLING, it's the same thing as with WEBSOCKET_XHR:

1. Vaadin client establishes the long-polling GET connection but sends nothing, waiting for server to send something.
2. Proxy kills the connection after 2 minutes.
3. Server sends UIDL but the message is lost.
4. Client sends another request (a button click, or a Poll request) over a new connection;
   the server responds by the next UIDL message.
5. Vaadin Client detects out-of-order message and awaits for previous message which will never come.
6. Vaadin Client times out after 5 seconds and asks for a resync in a separate connection.

With no push, just a rapid stream of poll requests:

1. A poll request is sent to the server; the request is received but the response is
   lost because of a flaky TCP/IP connection.
2. Another poll request is sent to the server. The server responds with yet another UIDL.
3. Vaadin Client detects out-of-order message and awaits for previous message which will never come.
4. Vaadin Client times out after 5 seconds and asks for a resync in a separate connection.

### Frequent resync requests

Occassional resync requests are okay in case when the connection is lost, or
some internal bug of WEBSOCKET_XHR causes out-of-order message to be sent in rare
case. However, frequent resync requests should definitely not happen on regular basis -
if they do, there's some kind of problem going on.

I can envision the following scenario for LONG_POLLING:

1. Client encounters out-of-order message as described above.
2. Client gives up waiting for the older message and sends resync as a HTTP PUSH request over new connection.
3. The server responds, and the client resyncs successfully.
4. Client immediately opens a new connection but sends nothing. Goto 1.

The same thing happens with WEBSOCKET_XHR:

1. Client encounters out-of-order message as described above.
2. Client gives up waiting for the older message and sends resync as a HTTP PUSH request over new connection.
3. The server responds, and the client resyncs successfully.
4. Client immediately opens a new connection but sends nothing. Goto 1.

### Vaadin Client-side corrective measures

#### out-of-order UIDL

When the "out-of-order UIDL" condition is detected,
the client will wait 5 seconds to hopefully receive the missing UIDL responses.
If the messages did not arrive in time, Vaadin Client will now ignore them and
will attempt to perform a
full resync: the client will try to download a complete server-side state of all components, redrawing them
from scratch. To achieve that, the client sends a resync request.

In case of WEBSOCKET:

1. The resync request is sent over the websocket connection.
2. The websocket connection is broken and thus the request is lost.
3. Vaadin Client now freezes, endlessly waiting for a resync response which will never come.

The observable effect is that the client will freeze endlessly.

In case of LONG_POLLING and WEBSOCKET_XHR:

1. The resync request is sent over a new fresh HTTP request, which reaches the server.
2. The server responds with UIDL over the same connection, which should now work.
3. Vaadin Client receives the response to the resync request and reinitializes correctly.

The observable effect is that the client should unfreeze after 5 seconds.

#### No response received after a long time

When push is disabled, see [Vaadin 8 Freezing with Push disabled](../Vaadin8-freezing-no-push/).

TODO what happens when push is enabled?

## When things go wrong

* When the browser freezes straight after login (Chrome 80+), it could be that the Session Fixation
  prevention algorithm doesn't work with Vaadin push. See
  [Getting rid of synchronous XHR - does it affect Vaadin?](../Synchronous-XHR-Affect-Vaadin/)
  for more details.
* When the client freezes randomly, it could be that the connection gets broken by proxy, firewall
  or load balancer. Read below for solutions to try, and for the conclusion.

## Solutions to try

Since a broken connection can cause the Vaadin client to freeze endlessly,
usually the best thing
is to prevent the connection from being broken at all costs.

### Make Heartbeats go faster - doesn't help

The default heartbeat interval is 5 minutes, however certain proxies will kill the
connection silently after 2 minutes of inactivity. A good heartbeat interval is
45-60 seconds (see [Wiki Keepalive](https://en.wikipedia.org/wiki/Keepalive)).
Read [Vaadin 8 Docs on configuring the heartbeat interval](https://vaadin.com/docs/v8/framework/articles/CleaningUpResourcesInAUI.html).

Unfortunately, Vaadin heartbeats can't be used to keep the LongPolling, WEBSOCKET nor WEBSOCKET_XHR
connection alive: they're always sent from client to server over a new POST request, and never
sent through the long-running LongPolling GET request nor through the websocket pipe.

### Use poll requests as keepalives

Poll requests (configured via `UI.setPollInterval()`) can be used as heartbeats/keepalive only
when `Transport.WEBSOCKET` is used, since only `Transport.WEBSOCKET` will cause poll requests
to go through the websocket pipe.

Using this approach should prevent load-balancers/proxies/firewalls from killing the connection;
however in case of "spuriously broken connections" the WEBSOCKET transport will
also stop delivering requests from the client to the server, rendering the client dead.

### Send pings from server to client

You can track the list of all opened UIs, and send some dummy RPC request (executeJS or similar)
periodically to every UI via ui.access(). These UIDLs will get sent over the LongPolling GET request nor WEBSOCKET_XHR
(given that there's no current request ongoing).

This should prevent load-balancers/proxies/firewalls from killing the connection.
Unfortunately this still won't help in the case of "spuriously broken connection".

### Disable polling when using Push

> Note: Polling refers to `UI.setPollInterval()` which works both with and without Push,
while LONG_POLLING only works with push. Polling and LONG_POLLING are two very different things.

Setting `UI.setPollInterval()` to 0 or greater may interfere with Push, even though
it technically shouldn't. Make sure nobody is calling that method, by simply overriding it
in your UI and throwing an exception, or calling `super.setPollInterval(-1)`.

I think that polling is not a problem per se; it will just expose the dead connection
much faster. Poll can actually keep the connection alive with the `Transport.WEBSOCKET`,
as described above.

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

### Use LONG_POLLING instead of Websocket or Websocket/XHR

Proxies and load balancers usually has much better support for LONG_POLLING as opposed to
a websocket pipe. See above. 

Also, WEBSOCKET on flaky connections frequently stops working entirely, since also
Vaadin client requests are sent over the websocket; if the websocket pipe becomes broken
then there's absolutely no communication whatsoever.

On the other hand WEBSOCKET_XHR and LONG_POLLING will send requests in a fresh new connection.

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
* Use LONG_POLLING over WEBSOCKET_XHR -
  LONG_POLLING should be supported better by proxies.
* Use WEBSOCKET and polls to keep the connection alive. This will however not help with flaky connections.
* Prevent frequent connection breaking at all costs, otherwise your UI will appear frozen frequently.
  * Reconfigure the proxies to not to drop the connections;
  * Implement a server->client heartbeat which will ping every live UI every 45-60 seconds.
* Disable push before reinitializing session, to avoid Vaadin client freezing
  on Chrome 80+ with push enabled.
