---
layout: post
title: Using SQLDataProvider with Vaadin 8 and 10
---

The [Vaadin-on-Kotlin](http://vaadinonkotlin.eu) framework contained the
support for feeding the outcome of a SQL query to the Vaadin Grid for the
long time. However, since VoK is based on Kotlin, Java developers probably
avoided this solution and looked for a Java-based example. Well, here it is:

* [Vaadin 8 SQLDataProvider Example](https://github.com/mvysny/vaadin8-sqldataprovider-example)
  with a [live demo](https://vaadin8-sqldataprovider.herokuapp.com/)
* [Vaadin 10 SQLDataProvider Example](https://github.com/mvysny/vaadin10-sqldataprovider-example)
  with a [live demo](https://vaadin10-sqldataprovider.herokuapp.com/)

Both of the examples are pure Java, even though the project uses code from
Vaadin-on-Kotlin. The Kotlin stdlib is only included as a run-time dependency -
the example projects contains no Kotlin code and doesn't even run the Kotlin compiler.

The example projects demo the following features:

* A full-fledged implementation of the SQLDataProvider, which supports paging,
  sorting and filtering.
* A FilterBar for Grid, with auto-generated filtering UI components, passing
  filters to the SQLDataProvider. This is a direct replacement for the
  [FilteringTable Add-On](https://vaadin.com/directory/component/filteringtable),
  but it targets Vaadin 8 Grid as opposed to FilteringTable targeting Vaadin
  7-compat Grid.
* The FilterBar is also available for Vaadin 10, targeting native Vaadin
  10 Grid.

The example projects use Maven as the build system.

The SQLDataProvider connects to the database directly, using the
[VoK-ORM](https://github.com/mvysny/vok-orm) library; by default a direct
access to a JDBC `DataSource` is required, and the JDBC connections are pooled
using the Hikari-CP connection pooler. However, if you're running in a Spring
or JavaEE container, you can override this behavior, see Vok-ORM documentation for details.

## Edit: JPADataProvider

For those of you who just can't let go, I've prepared a full-fledged
JPADataProvider example, with filtering, sorting and filter bar:
[Vaadin 8 JPADataProvider Example](https://github.com/mvysny/vaadin8-jpadataprovider-example)
with a [live demo](https://vaadin8-jpadataprovider-exampl.herokuapp.com/).
