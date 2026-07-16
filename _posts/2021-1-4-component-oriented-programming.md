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
> philosophy of "Do one thing and do it well" works wonders here - understand this
> as "be responsible for one thing, and do it well".

## Prior art

None of this is new - it's a well-established discipline usually called
[Component-Based Software Engineering](https://en.wikipedia.org/wiki/Component-based_software_engineering).
The idea goes all the way back to Douglas McIlroy's 1968 talk *Mass Produced Software
Components*; McIlroy later baked the same idea into Unix as pipes and filters, which is
exactly the "UNIX philosophy" invoked above. Brad Cox pushed the analogy further with his
"Software ICs" (and invented Objective-C to build them), and Clemens Szyperski wrote the
canonical book on the topic - tellingly subtitled
[*Component Software: Beyond Object-Oriented Programming*](https://www.amazon.com/Component-Software-Object-Oriented-Programming-Addison-wesley/dp/032175302X),
which lines up with the point below that components are a natural extension of OOP.

## Advantages

* **Reusable** - a component is a much smaller and more natural unit of reuse
  than a whole page.
* **UI consistency** - reuse the same components throughout the app and everything
  looks the same. A 'Sampler' page - a single page demoing your common UI patterns
  (layouts, layouts with borders, forms, ...) - helps promote this.
* **A natural extension of OOP** - it's just encapsulation and object composition.
  It also uses inheritance, but in one disciplined way: you extend the framework's
  widget (or your own abstract component base) to *be* a concrete component - never
  to share loose utility code. That's the honest carve-out to
  [Composition Over Inheritance](../composition-over-inheritance/).
* **The UNIX philosophy** - each component does one thing and does it well.
* **Scales with complexity** - simple for simple components, yet composes into
  arbitrarily complex ones without leaking that complexity through the API.
* **Easy to test** - Vaadin components are insanely easy to test with
  [Karibu-Testing](https://github.com/mvysny/karibu-testing/); use TestBench for
  components with lots of client-side logic.

## Not MVP

Component-Oriented Programming is essentially the opposite of the
[MVC/MVP/MVVM](../mvc-mvp-mvvm-no-thanks/) family of patterns. MVP splits your code
along *architectural layers* - view, presenter, model - and pushes UI logic out of the
component in the name of testability, giving you three files (and the comms between them)
to maintain per screen. COP splits along *responsibility* instead: everything a component
needs to do its one job lives inside that component, so it stays self-sufficient.

That's also why, with Vaadin, the productivity boost comes from the components themselves
rather than from an MVP framework layered on top - and why this architecture grows with your
app instead of forcing a rewrite from MVC to MVP to MVVM as the app gets bigger.

## Listeners

If the component needs to tell you something, it will expose a listener for you to plug in.
Examples:

* A `Button` doesn't know how to save an entity, nor should it: its job is to give you a
  nicely styled button. Therefore, it exposes a click listener for you to hook in and
  do something.
* A `Grid` exposes selection listeners, item double-click listeners.
* Your custom `PersonCard` component exposes an e-mail listener when the user clicks the e-mail
  button.

The listeners do not have to be complex: in fact a `public final List<SerializableRunnable> clickListeners = new LinkedList<SerializableRunnable>()` is more than enough.

## Data Providers

The component needs data to display — and there are two kinds of component, which want opposite APIs.

**A component that owns its domain takes data and renders itself.** `BookingsGrid`,
`PersonForm`, a `PersonCard` — each one knows what a booking or a person *is* and how it
should look, so its public API is a data API phrased in *domain* terms: you hand it the
thing to show and it draws itself.

```java
grid.setItems(bookings);     // domain data in — NOT grid.setText(...), NOT grid.colorCell(...)
form.setPerson(person);
```

A quick test for "is my API at the right level": could you swap the entire rendering
mechanism — a table for a set of cards, HTML for a canvas — without changing a single
caller? If the API speaks bookings and persons, yes; if it speaks text, cells and colours,
every caller is welded to the mechanism. This is *tell, don't ask*: tell the component its
new state and let it compute the pixels, instead of asking for its internals and mutating
them from the outside.

The data can arrive two ways, both fine: the caller pushes it (`grid.setItems(...)`), or the
component pulls its own (`BookingsGrid` calls the service in its constructor — the
self-sufficient case). The invariant isn't *how* the data arrives, it's *who owns the
rendering* — the component does. And that is what buys back some of the testability that
self-sufficiency costs you: because the view renders whatever data you hand it, you can drive
it with canned data in a test — no backend, no live service — and assert on what it shows.

**A generic, domain-agnostic component is the deliberate exception — it cannot own rendering
it knows nothing about.** A raw `Grid<T>`, a `ComboBox<T>`, a reusable widget built to serve
many use-cases: none of them can know how to render an arbitrary `T`, so a data-only API is
impossible for them. Instead they *externalize* the domain knowledge as injected strategies:

* `Renderer` — how to turn a value into a cell,
* `ValueProvider` — how to extract a value out of a bean,
* `DataProvider` — how to fetch a page of beans.

And the two kinds compose: **you build a domain component by configuring a generic one.**
`BookingsGrid extends Grid<Booking>` wires the columns, renderers and data source *once*, in
its constructor, and then presents the clean `setItems(bookings)` data API to its callers —
the whole strategy surface vanishes behind it:

```java
public class BookingsGrid extends Grid<Booking> {
    public BookingsGrid() {
        addColumn(Booking::getCustomer).setHeader("Customer");  // ValueProvider, wired once
        addColumn(Booking::getDate).setHeader("Date");
        setItems(bookingService.findAll());                     // DataProvider, wired once
    }
}
```

So there are two axes of reuse, which is why one rule cannot cover both: a *generic* component
is reused across **domains** (Person, Booking, VM) by injecting different strategies; a
*domain* component is reused across **data sources and test drivers** through its data API.
Don't force the data API onto a generic component, and don't bake a fixed domain into a
generic one.

Think of the data side as the *model* and the component as the *view* - a handy way
to reason, not a mandate to split them into separate classes. How much ceremony the
model needs is just ordinary code sizing:

* **Model logic big enough to warrant a class** - give it one, nested inside the
  component or standalone (a custom `DataProvider` implementation).
* **Model logic small** - a lambda or a direct service call right inside the
  component, exactly as `BookingsGrid` does above.
* **One source feeding several components** (1:many) - inject it as a constructor
  argument, since a shared object can't live inside any single component.

This self-sufficiency is the single most important property, and it's worth defending even
at the expense of testability. `BookingsGrid` has exactly one responsibility - to show a list
of bookings - and it does *everything* needed to fulfil it, including reaching into the database.
That's not a violation of "do one thing and do it well" but the very definition of it: the UNIX
`tree` command has the singular responsibility of showing a file tree, yet to succeed it happily
uses the filesystem to read the data, then a formatter and the terminal to print it out. Many
collaborators, one responsibility. A self-sufficient component is the same idea.

The price you pay is testability: a component that talks to the backend can no longer be tested
in complete isolation. That's a shortcoming worth admitting - and it has a good answer, which is
what the rest of this post is about.

## Testing

Even if you use Karibu to fake Vaadin, you still need the booking service up and
running. You can either mock the booking service
by implementing a set of mock interfaces then set those mocks to the global service
registry (see [Services](https://www.vaadinonkotlin.eu/services/)). However, even
better is to actually use the services as-is and test your app through-and-through: the system testing.

Your services will use some sort of backend to get the data from:

* If you use REST, it's possible to provide a fake implementation of the
  REST services.
* If you use a SQL database, you can either load H2 in-memory and run on that, or
  you can start an empty database in Docker and use that.

The system testing approach has a tremendous advantage: since you're running the server
and the tests in one JVM, you are in full control of the database:

* You can start a transaction before every test, then roll it back, to revert
  the database to a known state. This is fast as hell but prevents you from inspecting
  the database state from Intellij as you're debugging the test.
* You can delete the data+repopulate the database before every test - slower.
* A combo: have a static boolean flag in your tests. Use the "transaction revert" by default,
  but switch to the "repopulate" strategy by flipping the flag before debugging a test.
