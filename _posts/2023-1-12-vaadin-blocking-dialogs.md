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
still responds to events since the event loop is in fact running, even if it's running temporarily inside the `showConfirmDialog()` function.

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
you may remember it by its code name of The Project Loom. When a code runs in a virtual thread (as opposed to the good old native OS thread), and the code blocks,
it is possible to pause the execution, store the current call stack, and make the code lie dormant until
the code unblocks. The call stack is then restored and the code resumes execution as if nothing special happened.

This of course needs a lot of support from the JVM itself. If you're interested, there's a very well written
article  [Oracle article on virtual threads](https://blogs.oracle.com/javamagazine/post/java-loom-virtual-threads-platform-threads)
which describes in layman terms how exactly the virtual thread execution suspends, unmounts from the carrier thread (fancy term
for the good old native OS thread) and awaits until the blocking call ends, then mounts back on a carrier thread (the same
thread or some other thread) and continues execution. That creates an illusion of a blocking code, but the code is not really
blocking - it's lying around in the heap until unblocked.

Virtual threads preserve the `ThreadLocal` values and also the value of `UI.getCurrent()` even after the unmount+mount
procedure, and therefore we could use it to run Vaadin UI code.

To get back to the blocking dialogs: we could use this machinery to unmount the virtual thread from within the `confirmDialog()`
function. That would allow the native thread running Vaadin UI code to finish and send the response to the browser, thus
drawing the dialog, which is exactly what we need! We can use `CompletableFuture.get()` to block;
after the user clicks a button, we can simply complete the `Future` which causes the `CompletableFuture.get()` call
to unblock, mount to the Vaadin UI thread and continue execution.

The function will look like follows:
```java
public class Dialogs {
    public static boolean confirmDialog(@NotNull String message) {
        final CompletableFuture<Boolean> responseFuture = new CompletableFuture<>();
        final ConfirmDialog dialog = new ConfirmDialog();
        dialog.setText(message);
        dialog.addConfirmListener(e -> responseFuture.complete(true));
        dialog.addCancelListener(e -> responseFuture.complete(false));
        dialog.open();

        // this is where we'll block until the user clicks a button in the dialog
        final boolean response = responseQueue.get();
        return response;
        dialog.close();
    }
}
```

The question is: how can we persuade the virtual thread mechanism to only use Vaadin UI threads as the carrier threads?

## How exactly does that work?

The whole magic happens in the `VirtualThread` class which quickly gets very technical, and so I won't dig in much
(also because I don't understand the mechanism myself :-p ). The thread mechanism uses `Continuation.park()` to
unmount the thread and remember the call stack in a continuation object; `Continuation.unpark()` then resumes the
execution. Virtual threads are constructed via the `Thread.ofVirtual().factory()` `ThreadFactory` and their API
pretty much resembles the API of a regular thread. The default factory uses some default ForkJoinPool which
runs tasks in good old native threads. The ForkJoinPool basically runs chunks of the virtual thread execution,
up to a point where the virtual thread blocks.

Now we need two things:
* Create a ForkJoinPool which runs tasks in the Vaadin UI thread,
* Pass that ForkJoinPool into the virtual thread factory.

The first item is easy. The virtual thread factory actually runs all tasks in an `Executor` which is an interface
with just one method: `Executor.execute(Runnable)`. It's trivial to create an `Executor` which simply runs all submitted tasks in `ui.access()`.

The latter item is a bit tricky. The virtual thread factory is implemented by the `java.lang.ThreadBuilders$VirtualThreadBuilder` class
which is not part of a public API. Its constructor accepts an `Executor` but the constructor is also not public.
That's not a problem though: we'll use a bit of reflection to create the builder.

Please see the [Vaadin Loom example project](https://github.com/mvysny/vaadin-loom) for more details:

* The `SuspendingExecutor` runs submitted tasks in virtual threads, on given executor;
* `VaadinSuspendingExecutor` uses the class above, while running the continuations in the Vaadin UI thread.

## Kotlin

The [Kotlin language](https://kotlinlang.org) offers a solution that works on any JVM version, even on old
JVM 8. The mechanism used is the [Kotlin Coroutines](../vaadin-and-kotlin-coroutines/). With this
approach it's the kotlin compiler (rather than the JVM runtime) who will break the code down into separate code chunks.
Basically, the code is transformed into a bunch of callbacks by the compiler; a state machine with the 'runNext()'
method is created, which then keeps track which callback (or continuation) goes next.

There is an inherent problem with this solution though: this solution doesn't work with `Thread.sleep()` and the regular Java blocking calls -
you have to use their suspending counterparts.
