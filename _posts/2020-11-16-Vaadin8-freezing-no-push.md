---
layout: post
title: Vaadin 8 Freezing with Push disabled
---

In case the push is not used, the XhrConnection class is used to send requests.
It doesn't matter whether it's a Poll request
or a "regular" request stemming from e.g. pushing a button - in this case they are equal.
The code at `XhrConnection:193` suggests there is really no timeout set, and so
Vaadin client will happily sit there for 10 hours, awaiting a response to the message it had sent:

```
        // TODO enable timeout
        // rb.setTimeoutMillis(timeoutMillis);
        // TODO this should be configurable
```

## Delayed requests

The client will delay further poll requests until the previous one is served. This can be verified easily,
by setting the client's poll interval to 1s, while adding 3s sleep to the servlet handling:

```java
@WebServlet(urlPatterns = "/*", name = "MyUIServlet", asyncSupported = true)
@VaadinServletConfiguration(ui = MyUI.class, productionMode = false)
public class MyUIServlet extends VaadinServlet {
    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        }
        super.service(request, response);
    }
}
```

It can be seen in the "Network" tab that all requests (poll request and button-press requests)
are only executed after a response to the previous request is received. This means that poll requests
are effectively executed every 3 seconds, instead of 1s as configured.

> Explanation why the requests are delayed on purpose: If the requests would not to be delayed, then a follow-up request could fetch a follow-up UIDL response,
leading to out-of-order UIDL messages. Read [Vaadin 8 Push Issues](../Vaadin8-push-issues/) for more details.
That's why Vaadin is delaying the requests.

## Dead connection

Say that there's no response from the server, either because the server simply takes too long to reply,
or the response packet it lost, or the TCP/IP connection becomes broken, or the VPN
connection breaks.
In such case Vaadin will simply block and wait endlessly.

## Cleanly closed connections

Since Vaadin client will never timeout and thus will never close a request connection,
and Vaadin Servlet has no means to close the connection without producing a response,
this scenario can only occur when it's a third-party closing the connection:

* a load-balancer configured to drop inactive connections after 5 minutes
* a proxy, or Tomcat or a firewall configured to drop inactive connections after 5 minutes

Now the recovery process will differ for different scenarios:

* The server had not received the request (this means that the connection got broken between the load-balancer
  and the server itself - highly unlikely, unless there's a flaky intranet connection).
  Alternatively the load-balancer can't reach the
  server for some reason, and so it closes the connection to the client.
* The server received the request but blocked endlessly and failed to respond.
* The server received the request, produced the response but it got lost between the server and the load-balancer
  (also unlikely, unless there's a flaky intranet connection).

In all three cases Vaadin client will receive a XMLHttpRequest error and will try to reconnect and
re-send the same request,
displaying "Server connection lost, trying to reconnect" in the process, logging this to the JS console:

```
Thu Nov 19 10:50:55 GMT+200 2020 com.vaadin.client.communication.DefaultConnectionStateHandler
INFO: Reconnect attempt 1 for XHR line 9 > injectedScript:1:245
Thu Nov 19 10:50:55 GMT+200 2020 com.vaadin.client.communication.DefaultConnectionStateHandler
INFO: Re-sending last message to the server... line 9 > injectedScript:1:245
Thu Nov 19 10:50:55 GMT+200 2020 com.vaadin.client.communication.XhrConnection
INFO: Sending xhr message to server: {"csrfToken":"a67ee020-73e6-422d-9ea8-dac1141f173d","rpc":[["0","com.vaadin.shared.ui.ui.UIServerRpc","poll",[]]],"syncId":28,"clientId":22}
```

### Scenario #1 - server never received the request

In such case the server will simply produce the response to the request, and everything
will continue as usual.

### Scenario #2 - server blocks

In this case the server is blocked within a session lock. Re-sending a request will
block on the server, waiting for the session lock to unlock. If the server never responds,
then client blocks endlessly in this loop.

However, say that the server finally responds to the first request. The response can not be
written since the pipe is dead (Tomcat logs an exception in this case: `Caused by: java.io.IOException: Connection reset by peer`)
and is lost. The server will now receive the re-sent request for the same thing,
realize that the client is in a broken state and responds with a full resync.

The client will receive the resync and will log the following to the console:

```
Thu Nov 19 10:51:05 GMT+200 2020 com.vaadin.client.communication.XhrConnection
INFO: Server visit took 10047ms line 9 > injectedScript:1:245
Thu Nov 19 10:51:05 GMT+200 2020 com.vaadin.client.communication.MessageHandler
INFO: JSON parsing took 1ms line 9 > injectedScript:1:245
Thu Nov 19 10:51:05 GMT+200 2020 com.vaadin.client.communication.DefaultConnectionStateHandler
INFO: Re-established connection to server line 9 > injectedScript:1:245
Thu Nov 19 10:51:05 GMT+200 2020 com.vaadin.client.communication.XhrConnection
INFO: Received xhr message: for(;;);[{"syncId": 31, "resynchronize": true, "clientId": 23, "changes" : [["change",{"pid":"0"},["0",{"id":"0"}]]], "state":{"0":{"pollInterval":15000,"localeServiceState":{"localeData":[{"name":"en_GB","monthNames":["January","February","March","April","May","June","July","August","September","October","November","December"],"shortMonthNames":.... /ETC, TRIMMED
```

The client resyncs and everything continues.

### Scenario #3 

In this case the first response is lost. The server will receive re-sent request for the same thing,
realize that the client is in a broken state and responds with a full resync. This scenario will now continue
in exactly the same way as Scenario #2.

## Reproducing the scenario #2 above

It's possible to reproduce the scenario #2 above on your development machine.

1. Create a button which will simply sleep for 10 seconds server-side on click.
2. Click the button and observe the POST connection ongoing in the browser's network tab.
3. Run `sudo ss -K dst 127.0.0.1 dport = 8080` a couple of times to kill the connection cleanly.
   Taken from [Stack overflow: Killing TCP connections in Linux](https://unix.stackexchange.com/questions/71940/killing-tcp-connection-in-linux/203658).
4. Observe the JavaScript log.
