---
layout: post
title: My Favorite Vaadin Architecture
---

The best way that worked for me was a simple SOA architecture,
no Spring, no JPA, no DI. Only use what you really need. [DIY](../frameworkless-diy/).

If you use SQL database, plain JDBC is a pain in the ass. Use [jdbi-orm](https://gitlab.com/mvysny/jdbi-orm),
or maybe [ActiveJDBC](https://javalite.io/activejdbc) even though I hated that you need a Maven plugin for that.
Don't use JPA - it's the [Mother Of All Leaky Abstractions](../java-antipatterns/)

Don't use DI in any form or shape (no Spring, no Guice, no Dagger). Instead, create a static repository of services:

```java
public static class Services {
  public static LoginService getLoginService() {}
  public static ThatService getThatService() {}
}
```

Much simpler to reason about, much faster to start, much easier to debug and maintain.

For stateful services you can use JVM singletons. For session-scoped services you can
make the getter look up the service instance from Vaadin session; see [Stateful Service documentation](https://github.com/mvysny/vaadin-boot#services)
for more details.

Use [Karibu-Testing](https://github.com/mvysny/karibu-testing/) to test your app server-side.
Either:

* don't mock/fake anything: use your services as-is and assert on the database contents, using
  an in-memory db like H2 or a throwaway db-in-docker; maybe rolling back transactions at the end of each test
* If you can't do that, e.g. because you're using REST server, you can fake the REST server.
* If you can't do that, set fake implementations of services before every test.

Don't drink the kool aid of [MVC, MVP, MVVM](../mvc-mvp-mvvm-no-thanks/), Hexagonal
and other crap. Have a simple layer of services, then make your components call those
services directly. Simple SOA.

Don't use JavaEE nor Spring-Boot: JavaEE is dead and an anti-pattern, Spring is anti-pattern (and should be dead):

* Use [Vaadin-Boot](../vaadin-boot/) which uses an embedded Jetty
* Or develop in Intellij with Tomcat, then [deploy into the Tomcat Docker image](../Launch-your-Vaadin-on-Kotlin-app-quickly-in-cloud/)

[Use Lumo theme, don't use the Material theme](../Vaadin-Material-Theme/).

For Vaadin-related suggestions: Vaadin actually can be used in a simple way, without Spring, Hibernate, JavaEE
and other crap. Additional rules apply:

* (If you must use DI) Don't ever mark Vaadin components as beans otherwise you may get strange parent-child-relationship-broken issues
* Don't use PolymerTemplates nor LitTemplates: they don't work with Karibu-Testing and
  the abstraction leaks in multiple ways:
    * see [Karibu-Testing+PolymerTemplates](https://github.com/mvysny/karibu-testing/tree/master/karibu-testing-v10#polymer-templates--lit-templates)
    * `@Id`-mapped elements within a vaadin-dialog template are not properly initialized. (TODO github ticket link)
* Use [Component-oriented approach](../component-oriented-programming/) over MVP
* Avoid EventBus unless your app is highly asynchronous in nature. Otherwise it will be hard
  for you to reason about code flow (since it's hard/impossible to tell which observers will react to given event).
* Use Karibu-Testing for everything: from unit-testing your components to system-testing your app:
  start your app with an actual database (use TestContainers to have the database up quickly); navigate to your login view via `UI.getCurrent().navigate()`,
  then navigate throughout your app.
  * Optionally, use TestBench to test the happy flow: a very simple scenario, mostly testing
    that the app renders in a web browser.
* Create a reusable set of Java layouts such as `GreyDetailsPane`; then create a view called Sampler which
  demoes all layouts and proper ways to use components. This creates a documentation of all the layouts;
  a catalogue of best practices if you will; a go-to posterboy source-code "recipes",
  excellent source of copy-paste for new developers joining the team.
* For security use [vaadin-simple-security](https://github.com/mvysny/vaadin-simple-security)
* Read [Configuring your Vaadin apps](https://github.com/mvysny/vaadin-boot#configuration) on
  configuration tips.
* Package your app as a zip/jar via [Vaadin Boot](https://github.com/mvysny/vaadin-boot)
* [Localization/Internationalization (l10n/i18n)](../vaadin-localization/)
