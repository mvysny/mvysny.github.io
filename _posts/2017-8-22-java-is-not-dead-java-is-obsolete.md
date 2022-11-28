---
layout: post
title: Java Is Not Dead, Java Is Obsolete
---

Obsolete as in Cobol - used widely, but on a descendant trajectory. Let's ask a very simple question:

> How many freshmen, when faced the question which language/web framework to learn,
> would pick Java (with all of its complexity) when there are countless other languages/frameworks to pick from?

To build a full-stack web apps in Java you need to:

* learn Mother Of All Frameworks: JavaEE or Spring
* learn Mother Of All (Leaky) Abstractions: JPA
* Pay for Intellij, use Netbeans or use Eclipse (which has more controls than a freaking flight simulator, and is next to impossible to launch a WAR with - that's why now we have Spring Boot)
* Use Java which is (let's face it) a bloody chatty feature-lacking language. And
  because of this feature (or lack thereof) it gave birth to monstrosities like JavaEE and Spring.
  Java 8 has streams() and `Optional`, sure, but let's face it: the former is chatty and not enough, 
  and the latter usually just produces crappy code.
* When you will eventually learn JavaEE, you will have to work with Javists (complexity-infected happy bunch) on an enterprise (read uber-complex) variation of [FizzBuzzEnterpriseEdition](https://github.com/EnterpriseQualityCoding/FizzBuzzEnterpriseEdition) and will start all project with including Spring, regardless of whether it is actually relevant to the project itself or not.

That's a Mount Everest-grade of steep learning curve. Why climb Mount Everest
when you have Groovy on Grails, Ruby on Rails, Node.js, Python, Vaadin-on-Kotlin?
Oracle dumped JavaEE (oh, donated to the community, right) but:

* It's too late, non-Java replacements are in place and widely used,
* It's no longer "the cool thing",
* I don't think Oracle really cares for JavaEE now - they sell cloud VMs now and
* they don't care what actually runs on those VMs.
* There is no replacement. Spring? Yeah right:

> `AbstractSingletonProxyFactoryBean`: Convenient proxy factory bean superclass for proxy factory beans that create only singletons.

![What the fuck is this?!?](http://www.latelierdumod.com/wp-content/uploads/2015/01/what-the-fuck-is-this.jpg)

Let's face it: even though Node.js is a hype like Ruby-on-Rails was before,
it is gaining momentum and redirecting new faces away from Java. Schools teach Python
instead of Java. Java's stream of new programmers grows thin and old ones are retiring. And that's a recipe for extinction.

## The Next Generation of Tooling

Even if somebody would start to learn Java now, they would horribly lag with their knowledge
behind people who hopped on the Java train 10 years ago. Isn't it thus
better to bet on and hop on a promising (read hyped) frameworks of now, like node.js?
Yes, JavaScript is horrible. It's a language with many pitfalls and horrible `==`, but it's extremely popular.
And to develop in Node.js, all you have to have is the node.js platform and a text
editor (Atom). Compare that with the Java overwhelming ecosystem of tools, IDEs and
libraries. Yes, JavaScript's [rapid development is insanely hard to follow](https://hackernoon.com/how-it-feels-to-learn-javascript-in-2016-d3a717dd577f)
but Java Ecosystem has even longer history (Struts, JSP, JSF anyone?).

## So how to save Java?

It's too late - the descent has begun and the Java language designers are running
in the wrong direction. Consider Java streams: the authors of that API should shoot for
simplicity of use instead of for purity of the design, and thus they managed to
create a complex API which is pain to use. Use Kotlin's streams using extension methods
producing plain lists for a week, and you will not want to go back to Java, guaranteed.

## So how to save JDK?

So Java is obsolete, what about JDK? Is there somebody to save JDK? Well, definitely
not Ceylon, since it has been dumped recently (sorry, DONATED to a scrap heap named Apache)
and is effectively **dead**. Not Scala - it's too complex, not to mention **dead**. The only
strongly-typed language that can save JDK is Kotlin. Yet, not to worry. JDK is used by
popular dynamic languages like Groovy, JRuby, Jython, which are far from dead. So the JDK
platform is alive and kicking, you just need to avoid Java and some of its ecosystem.
