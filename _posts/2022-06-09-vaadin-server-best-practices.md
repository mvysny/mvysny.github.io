---
layout: post
title: Vaadin Server-Side Best Practices
---

Vaadin 14+ can be used two ways: writing as much code as possible in JavaScript,
and writing as much code as possible in Java. I'll focus on the Java way.

See [Java Antipatterns](../java-antipatterns/) for a brief list of tips; here I'll
post more along with explanations.

## Let the exceptions bubble out

Don't catch exceptions in your Java code and in your click handlers. Instead, let them bubble out.
Vaadin contains two main points for exception handling; if you configure them correctly
then you'll have a nice unified exception handling which doesn't repeat itself.
See [Vaadin Error Handling](../vaadin-error-handling/) for more details.

## Don't use LocaleChangeObserver

The idea behind `LocaleChangeObserver` is to get notified once someone calls
`UI.setLocale()` (or `VaadinSession.setLocale()` which is a shortcut for `UI.setLocale()` on all UIs).
That would enable you to have a language picker combo in your UI, permanently accessible,
immediately switching the language of the user.

The problem is that the idea fails fairly quickly. You have a bunch of `TextField`s with
internationalized labels and placeholders which are set once. The `TextField` doesn't implement
`LocaleChangeObserver` and doesn't allow you to set a i18n key for the label.
In order to do that, you'll quickly find yourself creating `LocalizedTextField` which
extends `TextField` and has a `setLocalizedLabel()` function which accepts i18n string key,
then listens to locale changes and updates its label on locale change. This is a lot of code,
especially considering that you need to do that for every built-in Vaadin component.

Solution would seem to be to drop the whole idea and reload the page on language change.
That unfortunately doesn't work with `@PreserveOnRefresh`, so if you use those, you
can't use this solution.

The simplest solution is to allow the language to only be set on login.

## PolymerTemplates/LitTemplates

Don't use those. The advantage was that there would be a WYSIWYG editor for the templates (Vaadin Designer),
but that one is dead/deprecated. The disadvantages are as follows:

* They wrap contents in a ShadowDOM, which complicates CSS styling a LOT: for example you can't have global styles in the template
  unless you `@CSSInject` them one-by-one.
  * ShadowDOM also disables global lookups in Selenium/TestBench. Workaround is to lookup the template first,
    then lookup its children - then ShadowDOM will be searched as well. If you have
    multiple nested ShadowDOMs, good luck - you'll need to peel the layers off like onion.
  * [Karibu-Testing also has troubles with the templates](https://github.com/mvysny/karibu-testing/tree/master/karibu-testing-v10#polymer-templates--lit-templates),
    because of how they work internally: you either can't address components server-side, or you will only
    be given an empty "shells" of components.

## Testing

Use TestBench if you must, but only for a happy flow. TestBench is based on Selenium and shares its disadvantages:
* It's slow.
* It's hard to run in CI
* It's hard to prepare a database which suits all testing scenarios.
* It's almost impossible for a test to clean the database after itself. Say you have a list of persons
  and you create a new one. In order to clean up the db, you need to delete that person. Now you have
  these options:
  * Bypass server and delete the person from the db directly. Not a good idea, especially if you're
    using Hibernate with cache enabled by default. Also might not be that easy - additional business
    logic might need to run.
  * Expose your service layer as REST, then call that from your TestBench. Lots of work.
  * Make TestBench click the "delete" button. If it fails, you'll have to manually delete the person.

Therefore, the best way is to use TestBench only for happy flows, and prepare a very simple database for those simple
test scenarios. Alternatively, don't use TestBench at all and only test everything with Karibu-Testing.
Despite labeling itself as unit-testing framework, it can test your app through-and-through if you're able
to bootstrap your app and database in your JUnit JVM. It's also lightning fast and you can
rollback your database after every test, making the test cleanup dead-simple.

Read more on [Karibu-Testing](https://github.com/mvysny/karibu-testing) page.

## MVP/MVC/MVVP/Other crap

[MVC/MVP/MVVM? No Thanks.](../mvc-mvp-mvvm-no-thanks/). Just use
[Component-oriented programming](../component-oriented-programming/).

## EventBus

Don't. Unless your app is highly asynchronous in nature. Otherwise it will be hard
for you to reason about code flow (since it's hard/impossible to tell which observers will react to given event).
EventBus will interrupt the code, and it will interrupt you when you are reading/debugging the code and trying to figure out what it does:
you need to basically stop reading and figure out who's handling the events and what they do exactly.

I consider EventBus an anti-pattern in most common use-cases.

## Sampler

Create a reusable set of Java layouts such as GreyDetailsPane; then create a view called Sampler which
demoes all layouts and proper ways to use components. This creates a go-to off-the-shelf recipes
for new developers to follow.

The sampler page can be really simple: a bunch of Tabs, every tab demoing a particular feature:
one tab for layouts, one tab for grids, one tab for CRUD, one tab for notifications and simple reusable UI things
like "Pills".

See the [vaadin8-sampler](https://github.com/mvysny/vaadin8-sampler) app for an example of a simple Sampler app.
The Vaadin8 sampler demoes all components; in your app you should demo your apps'
components and CSS classes and styles instead.
