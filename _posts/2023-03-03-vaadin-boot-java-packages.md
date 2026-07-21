---
layout: post
title: Placing Vaadin Boot App into Java Packages
---

The basic principle of Java packaging is to [package by feature](https://phauer.com/2020/package-by-feature/).
Let me repeat the advantages here:

* Better discoverability and overview
* Self-contained and independent
* Simpler code
* Testability

That's why I recommend to go with the package-by-feature approach over package-by-layer.
It's like grouping car components, nuts, bolts, threads, windshield and whatnot, by color. It's just ridiculous.

Every rule can be broken if the outcome is simpler and easier to understand, so I'll lay down
a bunch of layout examples and then you decide for yourself. But first, a couple of comments
on the article.

## MVC

The article mentioned MVC, obviously [don't use that](../mvc-mvp-mvvm-no-thanks/) and
use [Component-oriented programming](../component-oriented-programming/) instead.

## SOA

There's an exception to the rule. If your app is a huge 3-tiered SOA, then it's
completely okay to place the service-tier classes apart from the UI-tier classes. Possibly
even into a separate jar. That is okay.

However, if the app is mostly CRUD with little logic,
go ahead and place your entities in the same package as your UI code.

## Vaadin Boot Java Packaging

See [Vaadin Simple Security Example](https://github.com/mvysny/vaadin-simple-security-example) app for a proper example.

Say that your app will be live in `https://example.com`; you would then place all the sources of the app into
the `com.example` package.

A Vaadin-Boot Vaadin app typically has a `Main` class which launches the app itself. Then there's `AppShell` as required
by Vaadin; a `Bootstrap` class, starting the whole server up; and possibly an `ApplicationServiceInitListener` which
configures Vaadin further. Those are all important classes, related to the application and its startup; place them
into the `com.example` package. There usually is a `MainLayout` defining the basic layout of the app: the side navigational
menu bar, the topmost secondary menu bar, currently logged in user, the logout button and so on. Basically every route uses
this layout; as such it should also be placed into the `com.example` package.

Every route should then have its own package, say, `com.example.security`; all security-related classes including routes
will be placed there. The tree example:

```
com.example
├── ApplicationServiceInitListener.java
├── AppShell.java
├── Bootstrap.java
├── Main.java
├── MainLayout.java
├── admin
│   └── AdminRoute.java
├── components
│   ├── EntityDataProvider.java
│   └── NavMenuBar.java
├── security
│   ├── LoginRoute.java
│   ├── LoginService.java
│   └── User.java
├── user
│   └── UserRoute.java
└── welcome
    └── WelcomeRoute.java
```

### SOA: Take 2

You can anticipate that the service layer will grow big; then you might want to split the app into two:

* `com.example.services` for services;
* `com.example.ui` for Vaadin UI code.

In such case, you can place the `Main` class and the `Bootstrap` class into the `com.example` package (since they
bootstrap the entire app including UI and services), and nest `AppShell`, `ApplicationServiceInitListener`,
`MainLayout` and all routes under `com.example.ui`.
