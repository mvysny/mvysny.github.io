---
layout: post
title: How Vaadin Closes The UI When You Close The Browser Tab
---

Say you put some cleanup code into a detach listener — release a lock, close a resource,
mark the user as offline:

```java
@Route("")
public class MainView extends VerticalLayout {
    public MainView() {
        addDetachListener(e -> markUserOffline());
    }
}
```

When does that listener actually run when the user closes the tab? The common belief —
repeated in older articles, including [my own](../vaadin-session-timeout/) — is that
Vaadin waits for *three missed heartbeats* and, if it was the last tab, never detaches
until the session expires. That was true once, but since **Vaadin 24.1** it's only half
the story. Modern Vaadin closes the UI *eagerly* using a **beacon**. Let's look at both
mechanisms, because which one you get has real consequences.

## The primary path: an unload beacon

When you open a Vaadin app, the client registers a `pagehide` listener
(`com.vaadin.client.ApplicationConnection`):

```java
Browser.getWindow().addEventListener("pagehide", e -> {
    registry.getMessageSender().sendUnloadBeacon();
});
```

`pagehide` fires when the tab is closed, when you navigate away, or when the page is
refreshed. `sendUnloadBeacon()` builds a tiny payload flagged with `UNLOAD` and ships it
with the browser's [Beacon API](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/sendBeacon)
(`com.vaadin.client.communication.MessageSender`):

```java
public void sendUnloadBeacon() {
    ...
    extraJson.put(ApplicationConstants.UNLOAD_BEACON, true);
    sendBeacon(registry.getXhrConnection().getUri(), payload.toJson());
}

public static native void sendBeacon(String url, String payload) /*-{
    $wnd.navigator.sendBeacon(url, payload);
}-*/;
```

`navigator.sendBeacon()` is designed exactly for this: it fires a small request during page
unload without blocking or delaying the tab from closing. On the server,
`ServerRpcHandler` recognizes the beacon and closes the UI right away:

```java
// com.vaadin.flow.server.communication.ServerRpcHandler, paraphrased
if (rpcRequest.isUnloadBeaconRequest()) {
    if (isPreserveOnRefreshTarget(ui)) {
        // "Eager UI close ignored for @PreserveOnRefresh view"
    } else {
        ui.close();   // <-- your detach listener fires here, promptly
    }
}
```

So in the normal case — a plain `@Route` view, no `@PreserveOnRefresh` — closing the tab
detaches the UI **immediately**, even if it was the last or only tab. Your `markUserOffline()`
runs right away. Good.

This landed in Vaadin 24.1 (Flow issue
[#6293](https://github.com/vaadin/flow/issues/6293)). If you read that detach fires only
after three missed heartbeats, that advice predates the beacon.

## The catch #1: `@PreserveOnRefresh`

Notice the `isPreserveOnRefreshTarget(ui)` guard above. If your view is annotated
`@PreserveOnRefresh`, Vaadin **deliberately skips** the eager close. The reason: at
`pagehide` time Vaadin can't tell a genuine tab-close from an F5 refresh — both fire
`pagehide`. The whole point of `@PreserveOnRefresh` is that the server-side view survives a
refresh, so Vaadin plays it safe and does *not* close the UI on the beacon. It falls back to
the heartbeat mechanism instead (below).

Consequence: **for `@PreserveOnRefresh` views, closing the tab does not detach the UI
eagerly** — you're always on the fallback path.

## The catch #2: the beacon is best-effort

`navigator.sendBeacon()` is fire-and-forget and not guaranteed. The beacon can be lost when:

- the browser or OS crashes, the process is killed, the laptop lid is closed, power is lost;
- the network drops at the exact moment of unload;
- the browser has a bug (there have been real ones, e.g. Chrome
  [#19048](https://github.com/vaadin/flow/issues/19048), Firefox
  [#19305](https://github.com/vaadin/flow/issues/19305)).

When the beacon doesn't arrive, the server never gets the eager-close signal — and again
falls back to the heartbeat mechanism.

## The fallback: heartbeat cleanup (and its last-tab hole)

The old mechanism is still there as the safety net. A tab periodically sends a *heartbeat*
(every 5 minutes by default); a UI that misses three in a row is considered dead. The subtle
part is *where* that check runs — and there's exactly one place. `VaadinService.requestEnd()`
runs at the end of **every** request that used a session (UIDL, heartbeat, beacon, anything)
and calls `cleanupSession()`, which walks **all** UIs in the session and closes the dead ones:

```java
// com.vaadin.flow.server.VaadinService, paraphrased
void requestEnd(...) {
    ...
    cleanupSession(session);      // <-- the ONLY place the sweep happens
}

private void closeInactiveUIs(VaadinSession session) {
    for (UI ui : session.getUIs()) {
        if (!isUIActive(ui) && !ui.isClosing()) {
            ui.close();           // heartbeatInterval * 3.1 elapsed
        }
    }
}
```

The key fact: **the sweep only runs when a request reaches the session.** There is no
background timer. And a tab's own heartbeats keep *that* tab alive — they can never be what
closes it, because a tab still sending heartbeats isn't dead.

So what closes a dead UI on the fallback path? A request from **some other UI in the same
session**. With two tabs open, if one dies (crashed beacon, or a `@PreserveOnRefresh` view),
the *surviving* tab's heartbeats keep hitting `requestEnd → cleanupSession`, which eventually
notices the dead one and closes it — 15–20 minutes later with defaults.

But close the **last** tab and there's no other UI left to send anything. No request ever
reaches the session again, so `requestEnd()` never fires, so `closeInactiveUIs()` never runs,
so `ui.close()` is never called. The dead UI lingers until the **servlet container**
invalidates the idle HTTP session (the `session-timeout`, typically 30 minutes) — only then
does Vaadin close the session and, with it, your UI. Your detach listener finally runs, half
an hour late.

A couple of things that do **not** rescue this last-tab case: `closeIdleSessions=true` (that
check also lives inside `cleanupSession`, so it needs a request too) and shortening the
heartbeat interval (fewer missed beats to wait for, but still nobody to notice them).

## Putting it together

| Situation | What closes the UI | When |
|---|---|---|
| Plain `@Route` view, beacon delivered | Unload beacon → `ui.close()` | Immediately |
| `@PreserveOnRefresh` view, or beacon lost, **but another tab is open** | Heartbeat sweep, driven by the other tab's requests | ~15–20 min (defaults) |
| `@PreserveOnRefresh` view, or beacon lost, and it was the **last tab** | Servlet session expiry | `session-timeout` (~30 min) |

## What this means for your code

- For a plain routed app, server-side detach on tab-close is now reasonably prompt — the
  beacon does the job.
- **Do not** rely on prompt detach if you use `@PreserveOnRefresh`, or if you need it to be
  correct even when the beacon is lost (crashes, flaky networks, mobile). In those cases
  detach is best-effort and, for the last tab, deferred to session timeout.
- If you truly need a reliable "user left" signal, treat it as a best-effort hint and back it
  with a timeout-based sweep on the server. Keep the `session-timeout` short enough that a
  lingering session is acceptable, and consider `closeIdleSessions=true` for the
  tab-left-open-and-forgotten case (it doesn't help the last-tab-closed case, but it does
  bound the idle-but-open one).

## See also

For the session-timeout and `closeIdleSessions` configuration side — how the servlet
container and Vaadin cooperate to eventually close everything — see
[Vaadin Session Timeout / Heartbeats](../vaadin-session-timeout/). The
[official application-lifecycle docs](https://vaadin.com/docs/latest/flow/advanced/application-lifecycle)
describe the heartbeat contract but, at the time of writing, don't mention the unload beacon.
