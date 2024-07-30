---
layout: post
title: Vaadin, Kotlin and CRUD database access
---

There are many JDBC frameworks, both Java and Kotlin. However, some of the frameworks
lack certain functionality which prevents them to be used with Vaadin and the traditional
way of Vaadin CRUD via the [Binder](https://vaadin.com/docs/latest/flow/binding-data/components-binder-beans),
including the JSR 303 Bean Validation.

In order for a persistence framework to be usable with Vaadin, it should offer entities or DTOs that:

1. are detached (a real POJO), so no hidden fields with references to transactions etc.
   The reason is that the entity may be temporarily stored in session, and therefore the entity should be serializable.
2. do not track modifications and do not automatically emit SQL UPDATE statements.
   Instead, a `save()`/`update()`/`create()` function should be provided by the framework. This way, when the user presses the "Cancel" button,
   the changes done in the DTO are simply thrown away and not persisted. The fields should be settable from outside of the transaction.
3. comply to the bean specification, in order for the bean to be usable with Vaadin Binder.
   This includes having proper getters and setters so that they can be annotated with JSR-303 validation annotations.

## Exposed

[Exposed](https://github.com/JetBrains/Exposed) is an ORM framework officially endorsed by JetBrains, therefore
it carries a lot of weight. Exposed supports so-called DAO mode where you can read database rows to entities.

Disadvantages:
* Requires `kotlin-reflect.jar` which is a huge 3,1mb library
* Unfortunately, the entities are strongly tied to a transaction, they're not POJOs, the modifications emit SQL UPDATEs automatically,
  and the entities can not be modified from outside the transaction.

Related feature requests:

* [#497: Proper way to serialize/deserialize DAOs entities.](https://github.com/JetBrains/Exposed/issues/497)
* [EXPOSED-463: Support for DTOs / detached POJO entities](https://youtrack.jetbrains.com/issue/EXPOSED-463/Support-for-DTOs-detached-POJO-entities)

Example projects: TODO

## Ktorm

[Ktorm](https://github.com/kotlin-orm/ktorm) is unofficial but looks really popular. The SQL UPDATEs aren't emitted automatically,
and Ktorm ticks all the rules:

1. Even though entities are interfaces, they're detached.
2. They don't emit SQL UPDATEs
3. They're beans.

Disadvantages:
* Requires `kotlin-reflect.jar` which is a huge 3,1mb library
* Not as popular as Exposed
* [Supports H2 with a quirk](https://github.com/kotlin-orm/ktorm/issues/569)

Example projects:

* [beverage-buddy-ktorm](https://github.com/mvysny/beverage-buddy-ktorm)

## vok-orm

I've created [vok-orm](https://github.com/mvysny/vok-orm) in a way to be directly usable with Vaadin, and therefore
it complies with all the above-mentioned properties. The code base is really simple as well.

Disadvantages:
* not really popular, so getting bugs fixed might be tricky.

Example projects:

* [jdbi-orm-vaadin-crud-demo](https://github.com/mvysny/jdbi-orm-vaadin-crud-demo): pure Java project demoing jdbi-orm (jdbi-orm is used by vok-orm and implements the majority of functionality)
* [beverage-buddy-vok](https://github.com/mvysny/beverage-buddy-vok): A full-blown Vaadin Kotlin app which demoes vok-orm-based CRUD
* [vok-security-demo](https://github.com/mvysny/vok-security-demo): uses vok-orm to load users
* [vaadin-kotlin-pwa](https://github.com/mvysny/vaadin-kotlin-pwa): demoes Vaadin+Kotlin+CRUD as well
* [vaadin-simple-security-example](https://github.com/mvysny/vaadin-simple-security-example) - uses jdbi-orm to load users from the database and store salted passwords

## JOOQ

[JOOQ](https://www.jooq.org) is very popular in Java world and also supports Kotlin bindings.
It can generate detached POJOs which check all the boxes above.
Unfortunately, the generator can't be configured much and will overwrite our JSR-303 annotations,
so you need to be extra-careful when re-generating POJOs.

Example projects:

* [beverage-buddy-jooq](https://github.com/mvysny/beverage-buddy-jooq)


## JPA

No.
