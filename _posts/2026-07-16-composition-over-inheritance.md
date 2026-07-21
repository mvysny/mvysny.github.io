---
layout: post
title: Composition Over Inheritance
---

"Composition over inheritance" is one of those rules everyone repeats and few
examine. It's a good rule - one of the few OOP slogans that's actually right by
default. But a slogan you don't examine is a slogan you'll misapply, and this one
has exactly one honest exception that trips people up. Let me state where the rule
holds, why, and the one place it doesn't - and why *pretending* the exception
isn't an exception does more harm than the exception itself.

## Why inheritance is the wrong default

When you want to use functionality from another class, you have two options: hold
a reference to it (composition), or extend it (inheritance). Composition wins by
default, and it's not close.

Inheritance looks cheap and turns out expensive. Quoting Josh Bloch's
[*Effective Java*, Item 17 - "Design and document for inheritance or else prohibit it"](https://medium.com/@rufuszh90/effective-java-item-17-design-and-document-for-inheritance-or-else-prohibit-it-be6041719fbc):
your `protected` methods silently become part of your public API, and your
constructor must never call an overridable method (the subclass override runs
before the subclass is initialized). Neither trap is visible at the call site;
both bite later.

Worse, inheritance destroys code locality. Read a class that extends a deep
hierarchy and methods get "magically called out of nowhere" from superclasses
located completely elsewhere - and thanks to polymorphism, you often can't even
tell at compile time which override actually runs. I wrote about that at length in
[Code Locality and the Ability to Navigate](../code-locality-and-ability-to-navigate/#oop-inheritance);
the short version is that a subclass is welded to *all* the code of *all* its
ancestors, and you have to hold the whole tree in your head to understand any leaf.

Composition has none of these problems. A composed object is a reusable box with a
well-defined API that doesn't leak its internals. You call it; you don't *become*
it. That's the good approach, and it's the default everywhere.

Everywhere except one place.

## The one honest exception: component UI frameworks

If you've used Swing, Vaadin, Android, or any component-oriented UI toolkit, you've
already broken the rule - correctly. These frameworks are *designed* to be extended
by subclassing. Building your own component **is** extending one of theirs:

```java
public class BookingsGrid extends Grid<Booking> {
    public BookingsGrid() {
        addColumn(Booking::getCustomer).setHeader("Customer");
        addColumn(Booking::getDate).setHeader("Date");
        setItems(bookingService.findAll()); // populates itself
    }
}
```

That's inheritance, front and center. And it's not a violation - it's the
sanctioned plug-in mechanism. You extend `Grid` / `JPanel` / `Composite` / `View`
because that's how the framework expects you to add your own component to it. The
whole architecture is built on it.

Here's the part people get wrong: **don't dress this up as "composition with the
framework."** It isn't. It's inheritance, plain and honest. Calling it composition
to keep the rule feeling unbroken dilutes the one word we most want kept sharp -
and then the next person can't tell your principled exception from an ordinary
abuse. Name it for what it is: the accepted UI-framework carve-out to
composition-over-inheritance. Named honestly, the two rules stop fighting.

## The sharp line: inherit to *be* a component, not to *share* code

The carve-out is narrow, and the boundary is crisp. You may inherit to **be** a
component - to specialize a widget into one concrete, self-sufficient box. You may
**not** inherit to **share** arbitrary utility code. That second kind is exactly
what composition-over-inheritance forbids, and the carve-out doesn't touch it.

So this is fine (`BookingsGrid` above): extending `Grid` to become a grid. And this
is not:

```java
// WRONG: an abstract base that exists only to share helper methods
public abstract class AbstractView extends VerticalLayout {
    protected void showError(String msg) { Notification.show(msg); }
    protected User currentUser() { return SecurityUtils.getUser(); }
}
```

`AbstractView` isn't a component - nobody instantiates it, it has no cohesive
purpose, it's a junk drawer of helpers that got hoisted into a base class so
subclasses could reach them. That's inherit-to-share wearing a UI costume. Make
`showError` and `currentUser` plain functions and call them. The rule still governs
here, framework or not.

## The chain extends one rung past the framework

The carve-out isn't limited to the framework's own classes. Your own **abstract
component base** is a legitimate ancestor too - as long as it's a real, cohesive,
reusable component in its own right.

Take a CRUD master-detail screen. An `AbstractMasterDetail` (built on the
framework's split-layout widget, wiring the list-selects-then-editor-shows plumbing
that every master-detail shares) is a genuine component. A `PersonMasterDetail`
that extends it - supplying the person grid columns, the person editor fields, and
the fetch - is a concrete one:

```java
public class PersonMasterDetail extends AbstractMasterDetail<Person> {
    public PersonMasterDetail() {
        grid.addColumn(Person::getName).setHeader("Name");
        editor.add(new TextField("Name"), new EmailField("Email"));
        setItems(personService.findAll());
    }
}
```

Notice this is **subclass-to-configure**, and done cleanly it often *beats* the
generic alternative - a `MasterDetail<Person>` you assemble by handing a factory a
pile of column definitions, editor fields, and callbacks. Why? Because
`PersonMasterDetail` is a *named, cohesive box*: `new PersonMasterDetail()` and
you're done, and the thing has an identity you can find, reuse, and talk about. The
generic `MasterDetail<Person>` has no identity - it exists only as a parameterized
construction smeared across whatever call site assembled it. The concrete subclass
is more self-sufficient, not less.

## The base must earn its place

The carve-out **permits** an abstract base; it does not **mandate** one. A base
earns its existence by the same test every component faces: is it a genuine,
cohesive, reusable abstraction? `AbstractMasterDetail` - yes. But when the
commonality across the would-be subclasses is shallow - divergent scaffolding that
happens to rhyme, rather than a real shared component - the test fails, and the
right move is to **duplicate**.

Say you have three top-level app shells that each wire up a menu, a header, and a
content area, but the wiring diverges in every one. Folding them into an
`AbstractApp` to "save" the handful of shared lines is inherit-to-share all over
again: you'd weld three divergent things to a fake common ancestor and pay the
fragile-base-class tax forever. Copy the boilerplate instead. Same test as
`AbstractMasterDetail`, opposite verdict - because this base isn't a real
component, only a hiding place for duplication you were embarrassed by.

## In short

Composition over inheritance, undiluted, is the default everywhere. Component UI
frameworks are the one honest exception: you inherit - from the framework's widgets,
or from your own abstract component base - to **be** a self-sufficient component,
never to **share** loose code. Name the exception honestly and it costs you nothing;
pretend it's composition and you blunt the very rule you were trying to keep.

If you want the positive side of this - how self-sufficient components compose into
whole applications - that's [Component-Oriented Programming](../component-oriented-programming/).
