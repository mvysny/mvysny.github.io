---
layout: post
title: TCP-IP Sucks
---

TCP/IP was established as a means to have a bi-directional pipe
where random packet reordering can not happen and where the information
is reliably delivered to the other party. It succeeded with the "reordering"
part, and failed miserably with the "reliably" part. Read on.

## TCP/IP breaks silently

TCP/IP is a leaky abstraction: it may break at any time for no apparent reason,
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

There are two general scenarios on how the TCP/IP connection becomes broken:

* The TCP/IP may die spuriously (e.g. a cell phone signal is lost)
* A load-balancer/proxy/firewall may silently kill an assumingly-dead connection
  (say there has not been a communication for 2 minutes).

To remedy the cases above, app-specific protocols need to employ:

* ping messages, sent periodically over the pipe, in order for the TCP/IP
  connection to appear as being used for the load-balancer/proxy/firewall,
  so that they don't kill it.
* ACKs (acknowledge messages, sent after every request, to confirm that
  the request has indeed been received).

### ping

The only way to remedy the connection being dropped as unused is to send
a protocol-specific `ping` packets periodically.
In order to detect a dead TCP/IP connection (since the TCP/IP stack is not going to
figure it out itself), the other side needs to respond with a `pong` message.
If the `pong` is not received, the connection
is considered broken and corrective measures
need to be taken.

### ACKs

In order to detect the dead TCP/IP connection faster, it's also good
to have the other party to send an acknowledge message back, for every message
sent their way. This is important to also know which messages to re-send,
in case the connection fails.

## Detecting connection failures

The only way to detect a TCP/IP connection failure is to realize that
no reply has been received after certain timeout. Generally,
a 1 minute timeout should be more than enough for even slow TCP/IP connections,
but you can use a lower value if you need to detect the failure faster.

Unfortunately, there's no silver timeout number which works in all cases.
As a rule of thumb, use something between 30 secs and 2 minutes.

## Corrective measures

There's no way to repair a TCP/IP connection: writing to it will only
make the packets "fall out" somewhere on the way, being ignored.

The only way is to throw away the old TCP/IP connection,
reconnect to the other party by creating a new TCP/IP connection,
and resend all packets which might have been lost.

In order to know which message to re-send, the client needs to:

* Assign an unique ID to every message,
* Keep track of to which messages a reply has been received

Easy to say, right? :-D

## Conclusion

TCP/IP sucks; WebSocket sucks too since it performs absolutely
no broken-connection detection, no corrective measures and no
automatic connection re-establish and packet re-send.

For the purposes of modern apps that need to communicate bi-directionally,
TCP/IP is completely inadequate without lots of supportive machinery.
