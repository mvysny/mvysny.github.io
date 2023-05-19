---
layout: post
title: Vaadin And The Problem of Blocking Dialogs
---

Hold on dear reader before you close this blogpost, it's more interesting than in sounds :-D
A blocking dialog is a dialog which blocks the code execution until an answer is obtained from the user.
For example, in Swing, it is possible to write a code block which shows a confirm dialog, waits until the user clicked the "Yes"
or "No" button, then resumes its execution on confirmation and finishes afterwards. Something akin to the following:

```java
public class TicketPurchasingService {

    public static void purchaseTicketForConcert(String singerOrBand) {
        List<Concert> concerts = getAvailableConcertsFor(singerOrBand);
        Concert soonestConcert = concerts.get(0);
        // Waits for the user to click either the "Yes" or "No" button, then returns 0 for yes, 1 for no, 2 for cancel
        int input = JOptionPane.showConfirmDialog(null, "Soonest concert available: " + soonestConcert + ". Would you like to continue with the purchase?");
        if (input == 0) {
            Purchase purchase = doPurchase(soonestConcert);
            JOptionPane.showMessageDialog(null, "Concert " + soonestConcert + " purchased, thank you. Purchase details: " + purchase);
        } else {
            JOptionPane.showMessageDialog(null, "Please come back again");
        }
    }
}
```

We could make the function more complex, for example by wrapping it in a `try{}catch` block, thus handling any purchase errors gracefully,
but let's save that for later, and let's now focus on the `showConfirmDialog()` function for now.
Is it possible to do such a thing in Vaadin, or in fact in any web framework? The answer is no, but actually yes, depending on which JVM you're running.

## The Problem

All Swing apps have exactly one event loop which processes all UI events - mouse clicks,
tracking the mouse cursor as it moves and firing hover events, and so on.
All the UI code is called from this event loop, and it is actually forbidden to manipulate
UI components from outside the event loop. There is exactly one thread, dedicated to run the event loop;
when that thread finishes the app quits.

If the event loop gets blocked in any way (e.g. by a long-running network call, which we can emulate simply by calling `Thread.sleep(10000)`),
Swing app freezes - it won't respond to any mouse clicks, the windows won't move, and it will appear completely dead.

The blocking dialog apparently blocks the event loop from the execution, since it awaits for the user to press a button before returning e.g. 0 for
yes. That raises a question: if a blocking dialog apparently blocks the event loop, how come that the app still responds to the clicks
on the "Yes"/"No" button? The solution of this problem is as follows: the `JOptionPane.showConfirmDialog()` function
runs a nested event loop which processes UI events until one of the buttons get clicked.
That way, the `JOptionPane.showConfirmDialog()` function blocks until a button is clicked, but the app
still responds to events since the event loop is in fact running, even if it's running temporarily inside
of the `showConfirmDialog()` function.

Can we do the same thing with Vaadin?

## Blocking Dialogs in Vaadin

Consider the following Vaadin click handler:

```java
public class MyView {
    public MyView() {
        Button deleteButton = new Button("Delete");
        deleteButton.addClickListener(e -> {
            if (confirmDialog("Are you sure?")) {
                entity.delete();
            }
        });
    }
}
```

Is there an implementation of `confirmDialog()` function that would show a Vaadin Dialog and block until a button
is shown? We know the answer already, so let's focus on the 'no' part first.

The above code can not be implemented with the regular thread-based approach.
The problem here is as follows: assume that `confirmDialog()` function blocks the Vaadin
UI thread to wait for the user to click the "Yes" or "No" button. However,
in order for the dialog to be actually drawn in the browser,
the Vaadin UI thread must finish and produce a response for the browser. But the Vaadin UI
thread can't finish since it's blocked in the `confirmDialog()` function.

This is a fundamental problem of all web frameworks, not just of Vaadin. For more information
on how 'event loops' work in server UI frameworks, please read [Event Loop (Session Lock) in Vaadin](../event-loop-session-lock-in-vaadin/).

## But Actually Yes

So, what dark magic are we using, to solve the problem above? The answer is Java 20 Virtual Threads, or
you may remember it by its code name of The Project Loom.

TBD

That creates an illusion of a blocking code, but the code is not really
blocking

Please see the [Vaadin Loom example project](https://github.com/mvysny/vaadin-loom) for more details.

## Kotlin

The [Kotlin language](https://kotlinlang.org) offers a solution that works on any JVM version, even on old
JVM 8. The mechanism used is the [Kotlin Coroutines](../vaadin-and-kotlin-coroutines/). With this
approach it's the kotlin compiler (rather than the JVM runtime) who will break the code down into separate code chunks.
Basically, the code is transformed into a bunch of callbacks by the compiler; a state machine with the 'runNext()'
method is created, which then keeps track which callback (or continuation) goes next.

There is an inherent problem with this solution though: this solution doesn't work with `Thread.sleep()` and the regular Java blocking calls -
you have to use their suspending counterparts.
