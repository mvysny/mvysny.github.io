---
layout: post
title: Vaadin And Kotlin Coroutines
---

When Kotlin 1.1 brought in Coroutines, at first I wasn't impressed. I thought coroutines to be just a bit more lightweight threads: a lighter version of the OS threads we already have, perhaps easier on memory and a bit lighter on the CPU. Of course, this alone can actually make a ground-breaking difference: for example, Docker is just a light version of a VM, but it's quite a difference. It's just that I failed to see the consequences of this ground-breaking difference; also, performance-wise in Vaadin apps, it seems that there is little need to switch away from threads (read [Are Threads Obsolete With Vaadin Apps?](http://mavi.logdown.com/posts/3487539) for more info).

So, is there something else to Coroutines with respect to Vaadin? The answer is yes.

## What are Coroutines?

Coroutine is a block of code that looks just like a regular block of code. The main difference is that you can pause (suspend) that block by calling a special function; later on you can direct the code to continue the execution; the function will simply end and the calling code resumes execution. This is achieved by compiler magic and thus no support from JVM/OS is necessary. The [Informal Kotlin Coroutines](https://github.com/Kotlin/kotlin-coroutines/blob/master/kotlin-coroutines-informal.md) introduction offers great in-depth explanation. Even better is [Roman Elizarov's Coroutine Video](https://www.youtube.com/watch?v=_hfBv0a09Jc&list=PLQ176FUIyIUY6UK1cgVsbdPYA3X5WLam5&index=2) - the most clear explanation of Coroutines that I've seen (here is the part 2: [Deep Dive into Coroutines on JVM](https://www.youtube.com/watch?v=YrrUCSi72E8)).

There are the following problems with Coroutines:

* the compiler magic (a nasty state machine is produced underneath);
* the block looks like just a regular synchronous code, but suddenly out of nowhere completely another thread may continue the execution (after the coroutine is resumed). That's not something we can easily attune our mental model to.
* They're not easy to grok.

*Just* disadvantages, what the hell? I can do pausing with threads already, simply by calling `wait()` or locks or semaphores etc; so what's the big fuss? The important difference is that at the suspension point, the coroutine *detaches* from the thread - it saves its call stack, the state of the variables and bails out, allowing the thread to do something else, or even terminate. When the coroutine is resumed later on, it can pick any thread to restore the stack+state in, and continue execution. Aha! Now this is something we can't do with threads.

## The Blocking Dialogs

The coroutines suspend at suspension functions, and we can resume them as we see fit, say, from a button click handler. Consider the following Vaadin click handler:

```kotlin
deleteButton.addClickListener { e ->
  if (confirmDialog("Are you sure?")) {
    entity.delete()
  }
}
```

This can't be done with the regular approach since we can't have blocking dialogs with Vaadin. The problem here is as follows: assume that `confirmDialog()` function blocks the Vaadin UI thread to wait for the user to click the "Yes" or "No" button. However, in order for the dialog to be actually drawn in the browser, the Vaadin UI thread must finish and produce response for the browser. But Vaadin UI thread can't finish since it's blocked in the `confirmDialog` function.

However, consider the following [suspend function](https://github.com/mvysny/vaadin-coroutines-demo/blob/master/src/main/kotlin/org/test/Dialogs.kt#L72):

```kotlin
suspend fun confirmDialog(message: String = "Are you sure?"): Boolean {
    return suspendCancellableCoroutine { cont: CancellableContinuation<Boolean> ->
        val dlg = ConfirmDialog(message, { response -> cont.resume(response) })
        dlg.show()
    }
}
```

When the dialog's Yes or No button is clicked, the block is called with `response` of `true` (or `false`, respectively), which resumes the continuation, and with it, the calling block.

This allows us to write the following code in the button's click handler:

```kotlin
deleteButton.addClickListener { e ->
  launch(vaadin()) {
    if (confirmDialog("Are you sure?")) {
      entity.delete()
    }
  }
}
```

The `launch` method slates the coroutine to be run later (via the `UI.access()` call). The click handler does not wait for the coroutine to run but terminates immediately, hence it does not block. Since the listener is now finished and there is no other UI code to run, Vaadin will now run `UI.access()`-scheduled things, including our coroutine (coroutine is the block after the `launch` method).

The coroutine will create the confirm dialog and will suspend (and *detach* from the UI thread). That allows the UI thread to finish and draw the dialog in the browser. Later on, when the "Yes" button is clicked, the coroutine is resumed in the UI thread. It will close the dialog (the code is left out for brevity), deletes the entity and finishes the coroutine and the UI thread as well, allowing the dialog close to be propagated towards the browser.

And alas, with the help of compiler magic, we now have blocking dialogs in Vaadin. Of course those dialogs are not really blocking - that still can not be done. What the compiler actually does is that it will break the coroutine code into two parts:

* the first part creates the dialog and exits;
* the second one runs on button click, closes the dialog and deletes the entity.

The compiler will convert our nice block into a nasty state automaton class. However, the illusion in the source code is perfect.

## Further Down The Rabbit Hole

The above coroutine is rather simple - there are no cycles, try/catch blocks, and only a simple `if` statement. I wonder if the illusion will hold with a more complex code. Let's explore further.

We will create a simple movie tickets ordering page. The workflow is as follows:

1. we will first check whether there are tickets available; if yes then
2. we'll ask the user for confirmation on purchase;
3. if the user confirms, we make the purchase.

We will access a very simple dummy REST service for the query and for purchase; the app will also provide server-side implementations for these dummy services, for simplicity reasons. Since those REST calls can take a while, we will display a progress dialog for the duration of those requests.

Let's pause briefly and visualize the code using the old, callback approach. We can block safely in the UI thread during the duration of those REST calls, but then we can't display the progress dialog: it's the same situation as with the blocking confirmation dialog above. Hence we need to run that REST request in the background, end the UI request code, and resume when the REST request is done. Lots of REST clients allow async callbacks - for example Retrofit2 (which is usuually my framework of choice). Unfortunately Retrofit2's dark secret is that it blocks a thread until the data is retrieved. With NIO2 we can do better, hence we'll use [Async Http Client](https://github.com/AsyncHttpClient/async-http-client). In pseudo-code, the algorithm would look like this:

```java
showProgressDialog();
get("http://localhost:8080/rest/tickets/available").andThen({ r ->
  hideProgressDialog();
  showConfirmDialog({ response ->
    if (response) {
      showProgressDialog();
      post("http://localhost:8080/rest/tickets/purchase").andThen({ r ->
        hideProgressDialog();
        notifyUser("The tickets has been purchased");
      });
    } else {
      notifyUser("Purchase canceled");
    }
  });
});
```

Behold, the Pyramid of Doom. And that's just the happy flow - now we need to add error handling on every call, and also make the whole thing cancelable - if the user cancels and navigates to another View, we need to clean up those dialogs. Brrr.

Luckily we have Coroutines, and hence we can rewrite the [purchaseTickets()](https://github.com/mvysny/vaadin-coroutines-demo/blob/master/src/main/kotlin/org/test/MyUI.kt#L62) like this:

```kotlin
private fun purchaseTicket(): Job = launch(vaadin()) {
    // query the server for the number of available tickets. Wrap the long-running REST call in a nice progress dialog.
    val availableTickets: Int = withProgressDialog("Checking Available Tickets, Please Wait") {
        RestClient.getNumberOfAvailableTickets()
    }

    if (availableTickets <= 0) {
        Notification.show("No tickets available")
    } else {

        // there seem to be tickets available. Ask the user for confirmation.
        if (confirmDialog("There are $availableTickets available tickets. Would you like to purchase one?")) {

            // let's go ahead and purchase a ticket. Wrap the long-running REST call in a nice progress dialog.
            withProgressDialog("Purchasing") { RestClient.buyTicket() }

            // show an info box that the purchase has been completed
            confirmationInfoBox("The ticket has been purchased, thank you!")
        } else {

            // demonstrates the proper exception handling.
            throw RuntimeException("Unimplemented ;)")
        }
    }
}
```

Looks sequential, easy to read, easy to understand, but it has full power of error handling and cancelation handling:

* Error handling - we simply throw an exception as we would in a sequential code, and the kotlin-produced state machine will take care that it is propagated properly through try{}catch blocks and out of the coroutine. There, our Vaadin integration layer will catch the exception and will call the standard Vaadin error handler.
* Cancelation: the `confirmDialog()` function simply tells the continuation to [close the dialog](https://github.com/mvysny/vaadin-coroutines-demo/blob/master/src/main/kotlin/org/test/Dialogs.kt#L84) when the coroutine is completed (both successfully, exceptionally or canceled). The [withProgressDialog()](https://github.com/mvysny/vaadin-coroutines-demo/blob/master/src/main/kotlin/org/test/Dialogs.kt#L14) is even simpler - it will simply use `try{}finally` to hide the dialog; coroutine will then call the `finally` part even when canceled.

Coroutines allowed us to do amazing things here: we were able to use the sequential programming approach which produced readable/debuggable code, which is at the same time highly asynchronous and highly performant. I personally love that I am not forced to use Rx/Promise's `thenCompose`, `thenAccept` and all of that functional programming crap - we can simply use the built-in language constructs as `if`, `try{}catch` again.

The whole example project is at github: [Vaadin Coroutines Demo](https://github.com/mvysny/vaadin-coroutines-demo) - visit the page for more instructions on how to run the project for yourself and open it in your IDE. It's very simple.

You can try out the cancelation for yourself: normally it should be hooked on View's `detach()` which is called when navigating away, but it's easier to play around when you have a button for that (the "Cancel Purchase" button in the example app).

## Further Ideas

Your application may need to access a relational database instead of making REST calls, to fetch the data. JDBC drivers only allows blocking access mode - that's fine since it's fine to block in JVM with Vaadin. Yet, there are fully async database drivers (for example for MySQL and PostgreSQL there are drivers on Github), so feel free to go ahead and use them with Continuations.

Unfortunately, we can't use async approach with Vaadin's Grid's DataProvider. This is because the DataProvider API is not asynchronous: the nature of the API requires us to compute the data and return it in the request itself. However, that's completely fine since it's OK to block in JVM.

Of course you can implement even more longer running processes. Perhaps it might be possible to save the state of a suspended coroutine to, say, a database. That would allow us to develop and run long-running business processes in your app, in a really simple way, with the full power of the Kotlin programming language. The possibilities are interesting.
