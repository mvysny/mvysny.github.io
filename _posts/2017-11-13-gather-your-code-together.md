---
layout: post
title: Gather Your Code Together
---

Nicolas Frankel put some of my feelings into an excellent article [Is Object-Oriented Programming compatible with an enteprise context?](https://blog.frankel.ch/oop-compatible-enterprise-context). During the development of [Aedict Online](https://aedict-online.eu) (still as a Java-based JavaEE/JPA app back then, now it's [Vaadin-on-Kotlin](vaadinonkotlin.eu)-based), when trying to find rows from JPA+DB I often tried to find the necessary functionality on the JPA entity itself. Wouldn't it be great if, upon user's log in, we could find the user and verify his password using the following code?

```kotlin
fun login(username: String, password: String): User? {
  val user = User.findByUsername(username) ?: return null
  if (!user.verifyPassword(password)) return null
  return user
}
```

Unfortunately, I was not able to implement the `User.findByUsername` static method properly on JavaEE. I was forced by JavaEE to move such finders to an enterprise bean, because that was the only way to have transactions and the EntityManager. All my attempts to create such finders from JPA Entity static method failed:

* The DI engine makes it impossible to look up beans from a static method
* Creating a singleton bean with all things injected, providing them from a static context is a pattern discouraged in the DI world.

Eventually I realized that it was the DI itself who directly forbade me to group the code in a logical way, finders (they are in fact factory methods!) together with the Entity itself. I believe that the need to keep the common functionality together is one of the core concepts in pragmatic OOP, and I felt that DI was violating this. As the time passed I got so frustrated that I no longer could see the merits of the DI technology itself. After realizing this I hesitantly rejected the DI approach and tried to prototype a different approach.

I was learning Kotlin back then and I have just learned of global functions with blocks. What if those things could to the transaction for me, outside of EJB context? Such heresy, working with a database just like that! The idea is described in [Writing Vaadin apps in Kotlin Part 2](../2017-3-4-Tutorial-Writing-Vaadin-apps-in-Kotlin-Part-2/), but the gist is that it's dead easy to write a function which runs given block in a transaction, creates an EntityManager and provides it: the `db` method.

With that arsenal at hand, I was able to simply write this code:
```kotlin
class User {
  ..
  companion object {
    fun findByUsername(username: String): User? = db {
      em.createQuery("select * from User where username = :username")
        .setParameter("username", username)
        .singleResult as User?
    }
  }
}
```
It was *that* easy. I added a HikariCP connection pooling on top of that and I felt ... betrayed. The Dependency Injection propaganda crumbled and I saw DI standing naked, a monstrosity of dynamic proxies and enormous stack traces, bringing no value but obfuscating things, making things very complex and forcing me to split code in a way that I perceived unnatural (and anti-OOP). By moving away from DI I was expecting a great loss of functionality; I expected that I would have to tie things together painfully. *Everybody* uses DI so it's right to do so, right?

Instead, the DI-less code worked *just like that* - there was no need to inject lookup service into my JPA entity as Nicholas had to do, I did not had to resort to use Aspect Weaving or whatever clever technique my tired brain refused to comprehend. Things were simple again. I've embraced the essence of simplicity. Nice poem. Back to earth, Apollo.

I started to use static finders and loved them ever since. Later on I have created a simple [Dao](https://github.com/mvysny/vaadin-on-kotlin/blob/master/vok-db/src/main/kotlin/com/github/vok/framework/sql2o/Dao.kt) which allowed me to just define the `User` class as follows:

```kotlin
class User : Entity<Long> {
  companion object : Dao<User>
}
```

And the `Dao` would bring in useful static methods such as `findAll()`, `count()` etc, and the `Entity` would bring in instance methods such as `save()`, `delete()`, which allowed me to write code such as this:

```kotlin
val p = Person(name = "Albedo", age = 130)
p.save()
expect(p) { Person.findById(p.id!!) }
expect(1) { Person.count() }
```

Ultimately I [ditched the JPA crap away](https://github.com/mvysny/vaadin-on-kotlin/issues/3) and embraced Sql2o with CRUD additions. You can find this approach being used in the [Beverage Buddy Vaadin 10 Sample App](https://github.com/mvysny/vaadin-on-kotlin#vaadin-10-flow-example-project), along with other goodies, such as:

```kotlin
grid.dataSource = Review.dataSource
category.delete()
```

By throwing the DI away, I no longer had to run the container with Spring Maven plugin or fiddle with [Arquillian](http://arquillian.org/) since I could just run the code *as it was*, from a simple JUnit tests: [Browserless Web testing](../browserless-web-testing/).

But that's story for another day.
