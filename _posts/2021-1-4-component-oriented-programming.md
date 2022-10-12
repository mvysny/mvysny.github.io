---
layout: post
title: Component-Oriented Programming
---

If you ever used a component-oriented framework such as Java's Swing or Vaadin,
then you're familiar with components such as buttons and checkboxes. It goes like this:

1. Need a button? Write `new Button()`. Need a text field? Write `new TextField()`.
2. Build own components and views by composing existing components with layouts.
3. Navigate to components by marking them with a `@Route("path")` annotation.
4. If the component needs data, it will introduce an interface (e.g. DataProvider)
5. If the component wants you to know something, it will provide a listener.

Simple, right? You can even go further: your `PersonGrid` can add columns to itself
and populate itself with data, calling the backend services directly; all you
then need to do is to call `new PersonGrid()` and add it to your layout. Problem solved!

This architecture can grow easily with your app. You create a set of reusable components;
you then compose those components in layouts that also implement a logic. For example,
you can create a `PersonForm` which not only manages fields needed to edit a person,
but also performs validation and may even implement the saving functionality. You can
then compose multiple forms in a bigger wizard, which will still be a component,
hiding all the complexity within its implementation.

> You manage complexity by wrapping it in tiny boxes called components. You then
> compose tiny boxes in bigger boxes, and those in turn in bigger boxes. Every box
> will have a small and nice API depending on what the box solves. The UNIX
> philosophy of "Do one thing and do it right" works wonders here.

## Advantages

* Components are much smaller unit of reuse than pages.
* They are a natural extension to the object-oriented programming paradigm: Encapsulation
* The UNIX philosophy: Do one thing and do it well
* Promotes object composition but also works well with inheritance (if need be)
* Simple for simple components
* "with Vaadin the productivity boost comes from the components rather than the MVP framework."
* Reusable
* UI Consistency: you create a set of reusable components then use them throughout your app;
  they will look the same, granting your UI consistency.
  * To promote this, you create a 'Sampler' in your app - a single page
    dedicated to demoing common UI patterns in your app: common layouts, layouts with
    borders, how to create forms, etc etc.
* Vaadin components are actually insanely easy to test: [Karibu-Testing](https://github.com/mvysny/karibu-testing/)
  * You can also use TestBench to test the client-side of the components if they have
    lots of client-side logic.

## Listeners

If the component needs to tell you something, it will expose a listener for you to plug in.
Examples:

* A `Button` doesn't know how to save an entity, nor should it: its job is to give you a
  nicely styled button. Therefore, it exposes a click listeners for you to hook in and
  do something.
* A `Grid` exposes selection listeners, item double-click listeners.
* Your custom `PersonCard` component exposes an e-mail listener when the user clicks the e-mail
  button.

The listeners do not have to be complex: in fact a `public final List<SerializableRunnable> clickListeners = new LinkedList<SerializableRunnable>()` is more than enough.

## Data Providers

The component needs data to display.

* A common `Grid` which is designed to serve variety of use-cases provides the `DataProvider`
  interface for you to implement, through which Grid then fetches data.
* You can (and should) extend Grid and create a `BookingsGrid` which sets all of its columns
  and renderers, and also may directly call services to populate itself (sets its own `DataProvider`).
  That makes `BookingsGrid` completely self-sufficient.

## Testing

The `BookingsGrid` is not easy to test. Even if you use Karibu to fake Vaadin,
you also need the booking service to be up-and-running. You can either mock the booking service
by implementing a set of mock interfaces then set those mocks to the global service
registry (see [Services](https://www.vaadinonkotlin.eu//services/)). However, even
better is to actually use the services as-is and test your app through-and-through: the system testing.

Your services will use some sort of backend to get the data from:

* If you use REST, it's possible to provide a fake implementation of the
  REST services.
* If you use a SQL database, you can either load H2 in-memory and run on that, or
  you can start an empty database in Docker and use that.

Te system testing approach has tremendous advantage: since you're running the server
and the tests in one JVM, you are in full control of the database:

* You can start a transaction before every test then rolling the transaction back, to revert
  the database to a known state. This is fast as hell but prevents you from inspecting
  the database state from Intellij as you're debugging the test.
* You can delete the data+repopulate the database before every test - slower.
* A combo: have a static boolean flag in your tests. Use the "transaction revert" by default,
  but switch to the "repopulate" strategy by flipping the flag before debugging a test.
