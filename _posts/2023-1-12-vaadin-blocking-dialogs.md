---
layout: post
title: Vaadin And The Problem of Blocking Dialogs
---

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

Is it actually possible to do such a thing in Vaadin?

## The Problem

All Swing apps have exactly one event loop which processes all UI events - mouse clicks,
tracking the mouse cursor as it moves and firing hover events, and so on.
All the UI code is called from this event loop, and it is actually forbidden to manipulate
UI components from outside the event loop. There is exactly one thread, dedicated to run the event loop;
when that thread finishes the app quits.

If the event loop gets blocked in any way (e.g. by a long-running network call, which we can emulate simply by calling `Thread.sleep(10000)`),
Swing app freezes - it won't respond to any mouse clicks, the windows won't move, and it will appear completely dead.

The blocking dialog, as its name says, blocks the event loop from the execution.
It awaits for the user to press a button before returning e.g. 0 for
'yes'. That raises a question: if the blocking dialog blocks the event loop, how come that the app still responds to the clicks
on the "Yes"/"No" button? The solution of this problem is as follows: the `JOptionPane.showConfirmDialog()` function
runs a nested event loop which processes UI events until one of the buttons gets clicked.
That is the reason why the app still responds to events: the event loop is in fact still running,
it's just running temporarily inside the `showConfirmDialog()` function.

Can we do the same thing with Vaadin?

### Blocking Dialogs in Vaadin

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
is clicked? The answer is no if you can't send a response before blocking.
The problem here is as follows: assume that `confirmDialog()` function blocks the Vaadin
UI thread to wait for the user to click the "Yes" or "No" button. However,
in order for the dialog to be actually drawn in the browser,
the Vaadin UI thread must finish and must produce a response for the browser. But the Vaadin UI
thread can't finish since it's blocked in the `confirmDialog()` function.

This is a fundamental problem of all web frameworks, not just of Vaadin. For more information
on how 'event loops' work in server UI frameworks, please read [Event Loop (Session Lock) in Vaadin](../event-loop-session-lock-in-vaadin/).

EDIT: There's a very interesting solution which forces Vaadin to send the response "in the middle of" the UI thread,
before the UI thread finishes. Please see the end of this blogpost for more information.

## The Virtual Threads Solution

So, what dark magic are we using to solve the problem above? The answer is the Java 21 Virtual Threads, or
The Project Loom. Project Loom introduces the concept of a *virtual thread*, which
differs from the good old native OS thread in a way that it can *suspend*. When a code running in a virtual thread
calls a blocking function,
its execution is paused, it will store the current call stack and will lie dormant until
the function unblocks. The call stack is then restored and the code resumes execution as if nothing special happened.

This of course needs a lot of support from the JVM itself. If you're interested, there's a very well written
[Oracle article on virtual threads](https://blogs.oracle.com/javamagazine/post/java-loom-virtual-threads-platform-threads)
which describes in layman terms:

* how the virtual thread execution suspends and unmounts from the carrier thread (fancy term
for the good old native OS thread)
* how the JVM awaits until the blocking call ends,
* how the JVM mounts the virtual thread back on a 'carrier thread' (not necessarily the same thread as before) and continues execution.

That creates an illusion of a blocking code, but the code is no longer really
blocking - it's lying around dormant in the heap until unblocked.

Virtual threads preserve the `ThreadLocal` values and also the value of `UI.getCurrent()` even after the unmount+mount
procedure, which tells us that we could use it to run Vaadin UI code.

To get back to the blocking dialogs: we could use this machinery to unmount the virtual thread from within the `confirmDialog()`
function. That would allow the native thread running Vaadin UI code to finish and send the response to the browser, thus
drawing the dialog, which is exactly what we need! We can use `CompletableFuture.get()` to block;
after the user clicks a button, we can simply complete the `Future` which causes the `CompletableFuture.get()` call
to unblock, mount the dormant virtual thread to the Vaadin UI thread and continue execution.

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
        dialog.close();
        return response;
    }
}
```

The question is: how can we persuade the virtual thread mechanism to only use Vaadin UI threads as the carrier threads?

### Unwinding The Magic

The whole magic happens in the `VirtualThread` class. The source code of that class gets very technical quickly,
and so I won't dig into it further. The virtual thread suspending mechanism uses `Continuation.park()` to
unmount the thread and remember the call stack in a continuation object; `Continuation.unpark()` then resumes the
execution. Virtual threads are constructed via the `Thread.ofVirtual().factory()` factory (of type `ThreadFactory`),
and they behave exactly like regular threads until they're blocked. The default factory uses a dedicated Executor
(a ForkJoinPool really, but the difference is not important for this article) which
runs tasks in good old native threads. The Executor basically runs a chunk of the virtual thread execution,
up to a point where the virtual thread blocks.

Now we need two things:
* Create an Executor which runs tasks in the Vaadin UI thread,
* Pass that Executor into the virtual thread factory.

The first item is easy. The `Executor` is an interface
with just one method: `Executor.execute(Runnable)`.
It's trivial to create an `Executor` which simply runs all submitted tasks in `ui.access()`:

```java
private class UIExecutor implements Executor {
    private final UI ui;

    public UIExecutor(UI ui) {
        this.ui = ui;
    }

    @Override
    public void execute(Runnable command) {
        ui.access((Command) command::run);
    }
}
```

The latter item is a bit tricky. The virtual thread factory is implemented by the `java.lang.ThreadBuilders$VirtualThreadBuilder` class
which is not part of the public API. It introduces a constructor which accepts an `Executor` but the constructor is also not public.
That's not a problem though: we'll use a bit of reflection to create the builder.

Please see the [Vaadin Loom example project](https://github.com/mvysny/vaadin-loom) for more details:

* The `SuspendingExecutor` class runs submitted tasks in virtual threads, on given executor;
* `VaadinSuspendingExecutor` class uses the class above, while running the continuations in the Vaadin UI thread.

WARNING: the code above uses a non-public API to force virtual threads to use a custom executor.
While the solution fundamentally works, it could be prone to strange errors, for example
it's possible to [deadlock using one lock only](https://twitter.com/mariofusco/status/1659245444252172310).

## Kotlin

The [Kotlin language](https://kotlinlang.org) offers a solution that works on any JVM version, even on old
JVM 8. The mechanism used is the [Kotlin Coroutines](../vaadin-and-kotlin-coroutines/). With this
approach it's the kotlin compiler (rather than the JVM runtime) who will break the code down into separate code chunks.
Basically, the code is transformed into a bunch of callbacks by the compiler; a state machine with the 'runNext()'
method is created, which then keeps track which callback (or continuation) goes next.

There is an inherent problem with this solution though: this solution doesn't work with `Thread.sleep()` and the regular Java blocking calls -
you'll have to use their suspending counterparts. Please find more in the [Kotlin Coroutines documentation](https://kotlinlang.org/docs/coroutines-overview.html).

## Pushing Response During the UI Thread execution

In the discussion of the [vaadin.com blogpost on blocking dialogs](https://vaadin.com/blog/tackling-blocking-dialogs-in-web-applications-with-vaadin),
Matthias shared a very interesting solution. The solution is as follows: in the middle
of the UI request, you can unlock Vaadin session and call `UI.push()` to send all accumulated
UI changes to the client-side, causing the dialog to draw before the UI thread
actually finishes. Now the thread is no longer the "UI thread" (since the session lock is gone),
and so you are to block. After the blocking is done, you can reacquire the UI lock and continue execution.

Since this solution doesn't require any specific Java features, this will work on any JVM, however
there are things to look out for:

1. You must have push enabled (obviously).
2. You also need to run the UI code from within a `ui.accessSynchronously(() -> {})` block.
   `ui.access()` may not work since the UI code will be executed as pendingAccessTasks as a part
   of this UI request. That's problematic, since you can't call `push()` from pendingAccessTasks since
   the push function itself will run pendingAccessTasks processing again, thus potentially forming
   an endless loop, or causing the pending tasks to reorder, or other side-effects. TODO rethink this.
3. You may need to call `VaadinSession.unlock()` multiple times since the lock is reentrant and may be locked
   multiple times from the current thread. You then also need to lock the session multiple times.
4. Final call of `VaadinSession.unlock()` also pushes the changes automatically (if `Push.AUTOMATIC`) is used.

Beware: the http-handling thread will remain locked while waiting for the user to respond. If the
user closes the browser, the thread may remain locked indefinitely. This way, you can run out of
http-handling threads, thus rendering the servlet container unable to respond to requests, and to appear dead.
You can monitor session or UI detach and interrupt the wait, or you can wait in a loop and periodically
check whether the UI is still attached.

This solution also relies on the fact that `VaadinSession.unlock()`/`ui.push()` pushes the most recent UI state
immediately to the client-side, and doesn't wait until this thread progresses. Namely,
the push() javadoc reads "If push is enabled, but the push connection is not currently open, the push will be done when the connection is established.",
and that might (or might not) create a problem.

Matthias plans to create a public GitHub project that demoes this approach in the future;
when he does, I'll gladly add a link from this article.
