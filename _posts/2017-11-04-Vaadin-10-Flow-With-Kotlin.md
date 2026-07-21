---
layout: post
title: Vaadin 10 Flow With Kotlin
---

It is indeed possible to write Vaadin 10 Flow apps in Kotlin. Here are a couple of resources to get you started:

* Two introductionary videos, 40 minutes total running time, which explains the ideas behind Vaadin 10 Flow and behind the Vaadin-on-Kotlin framework itself:
  * [Vaadin-on-Kotlin Flow Part 1](https://www.youtube.com/watch?v=1GVdKwrI16A),
  * [Vaadin-on-Kotlin Flow Part 2](https://www.youtube.com/watch?v=qDd-8F0TgAY)

Those videos will also help you to download and start with the very simple skeleton application.

* The skeleton application which contains everything necessary to build the app and launch it, and it only introduces a very simple UI: a button and a text field. You can find all the necessary information here: [karibu10-helloworld-application](https://github.com/mvysny/karibu10-helloworld-application)
* A more polished application which shows additional components and also demonstrates the ability to connect to a Polymer Template: the Beverage Buddy application. It has no database access support and only serves in-memory dummy data. It is a part of the [Karibu DSL](https://github.com/mvysny/karibu-dsl) framework; instructions to get it and launch it: [Beverage Buddy](https://github.com/mvysny/karibu-dsl#quickstart-vaadin-10-flow).
* The same Beverage Buddy application as above, but uses an embedded full-blown H2 SQL database and is based on the [Vaadin-on-Kotlin](http://vaadinonkotlin.com) framework: [Beverage Buddy](https://github.com/mvysny/vaadin-on-kotlin#vaadin-10-flow-example-project).

Please feel free to post any questions at the [Vaadin Forums](https://vaadin.com/forum).
