---
layout: post
title: Vaadin 8 Communication Explained
---

Vaadin's synchronization protocol is based on UIDL (UI Diffing Language?).
Basically it's a JSON file, listing what have been changed since the last UIDL update. For example,
if you set a new caption to a TextField with connector ID 42, you will be able to
observe this information in the UIDL sent from the server to the client.

Essentially, Vaadin sends diffs (called UIDLs) of what has been changed from the server-side.

## UIDL Example

For example, clicking on a Vaadin button will make the client-side VButton send
the click event to the server-side (possibly along with any outstanding value change events since those
are able to be configured as non-immediate). The example request JSON follows:

```json
{"csrfToken":"70029027-d82e-45dc-a315-78ff7642a290","rpc":[
  ["7","com.vaadin.shared.ui.button.ButtonServerRpc","click",[
    {"altKey":false,"button":"LEFT","clientX":75,"clientY":130,"ctrlKey":false,"metaKey":false,"relativeX":38,"relativeY":19,"shiftKey":false,"type":1}
  ]
  ]
],"syncId":1,"clientId":1}
```

From the above you can see that a component with ID 7 called the `ButtonServerRpc` class, the `click()` function.
The Vaadin server then calls the appropriate method, which calls Button's listeners.
Vaadin server will then monitor all components for all changes (label changes, value changes, layout children changes),
gathers them into one big response and sends it back to the client, so that the changes can be applied
to the client-side components.

Example response JSON:

```json
for(;;);[
  {"syncId": 2, "clientId": 2, "changes" : [], "state":{
    "5":{"childData":{"6":{"alignmentBitmask":5,"expandRatio":0},
    "7":{"alignmentBitmask":5,"expandRatio":0},"8":{"alignmentBitmask":5,"expandRatio":0}}},
    "8":{"text":"Thanks , it works!"}
  },
  "types":{"5":"3","8":"14"}, 
  "hierarchy":{"5":["6","7","8"]
  }, 
  "rpc" : [], "meta" : {}, "resources" : {}, "typeMappings" : { "com.vaadin.ui.Label" : 14 }, "typeInheritanceMap" : { "14" : 7 , "3" : 10 , "4" : 7 , "10" : 12 , "12" : 4 , "7" : 9 }, "timings":[229, 0]}
]
```

From that we can see that the component with ID 8
needs to apply a new text. We can also see from `types` that the component 8 is mapped to type 14;
from `typeMappings` we can see that it's the type `com.vaadin.ui.Label`. That means
that the `Label` with ID 8 will change its text to `Thanks , it works!`.

## Message Ordering

Since missing out just one of those diffs could lead to undefined client-side state,
Vaadin must keep strict track of which UIDLs has been received from the server by the client-side Vaadin code.
The UIDL numbering scheme starts from 0 and continues in a strictly increasing monotonic
order.

The first request is a `POST` to `/` containing various browser information such as time zone,
theme, location etc. The server responds by sending the first UIDL containing the initial screen
layout and all initially visible components. The client creates and draws all components,
then awaits for the user activity.

Any user activity will now cause a message #0 to be sent to the server, to which the server replies with message #1.
Any follow-up activity will cause a message #1 to be sent to the server, to which the server replies with message #2.
And so on.

The message number is stored in the `syncId` UIDL JSON field and also in the `clientId` UIDL JSON field.

## Difference between syncId and clientId

The `syncId` number is for server -> client messsages, the `clientId` is for client -> server messages.

When not using push, those numbers will stay exactly the same, since for every client request there
is exactly one server response. However, when using push, the server may push a new UIDL
message at any time, without being provoked by a message from the client first.
In such case, the `syncId` number is increased
but the `clientId` number is kept the same.

The reasons for having two oddly-named values is historical:

> First, there was only syncId which was supposed to cover both directions. Then later on,
> it was realized that we need separate numbers for each direction. At that point, clientId
> was introduced without renaming the existing syncId to e.g. serverId.

Both numbers are used to check for missing/out-of-order messages: the client-side code
checks the value of `syncId`, while the server checks the value of the `clientId`.

## Corrective Measures

If certain conditions lead to UIDL messages dropped or reordered, corrective measures are taken.
If it is the client who detects a missing message, he will delay the processing and will wait for 5 seconds
until any missing messages are possibly retrieved. If this fails, the client asks for a full resync.

Whenever server receives a request for resync, it will gather all state from all components
and sends the entire information to the client-side. The client will then completely redraw all
components from scratch, to make the client-side up-to-date and establish lost sync.

The server can also detect missing messages, in such case it can simply respond with a full resync
message. The client will then drop everything and redraw the components from scratch.

See the [Vaadin 8 Push issues](../Vaadin8-push-issues/) for more details on how the out-of-order
comms could occur.

## HTTP URLs

### No Push

When not using Push, the whole communication uses a very simple HTTP request-response pattern.

The first request is a HTTP POST to `http://localhost:8080/?v-1607331961570=`;
any follow-up requests go as HTTP POSTs to `http://localhost:8080/UIDL/?v-uiId=1`.

Vaadin client will also send infrequent heartbeats via HTTP POST to `http://localhost:8080/HEARTBEAT/?v-uiId=1`,
to let the server know that the UI is still alive. The default heartbeat interval is 5 minutes but
this can be reconfigured.

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

## Chrome Rant

Chrome decides to simply drop parts of the URL and will simply only show the
`?v-uiId=xyz` instead of `/UIDL/?v-uiId=xyz` part in the Network tab. You will thus be unable
to tell between UIDL requests and Heartbeat requests. I have no idea in which fucking universe this makes sense,
just be aware of this shit when dealing with screenshots from Chrome.
